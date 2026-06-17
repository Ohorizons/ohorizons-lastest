"""
${{values.name}} - RAG Application

A Retrieval-Augmented Generation application built with FastAPI,
Azure OpenAI, and Azure AI Search.
"""
import logging
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

from .config import settings
from .rag import RAGService

# Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Metrics
CHAT_REQUESTS = Counter('rag_chat_requests_total', 'Total chat requests')
CHAT_LATENCY = Histogram('rag_chat_latency_seconds', 'Chat request latency')
DOCUMENTS_INDEXED = Counter('rag_documents_indexed_total', 'Total documents indexed')

# RAG service instance
rag_service: Optional[RAGService] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    global rag_service
    logger.info("Initializing RAG service...")
    rag_service = RAGService(
        openai_endpoint=settings.azure_openai_endpoint,
        openai_key=settings.azure_openai_api_key,
        openai_deployment=settings.azure_openai_deployment,
        search_endpoint=settings.azure_search_endpoint,
        search_key=settings.azure_search_api_key,
        search_index=settings.azure_search_index,
    )
    logger.info("RAG service initialized successfully")
    yield
    logger.info("Shutting down RAG service...")


app = FastAPI(
    title="${{values.name}}",
    description="${{values.description}}",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Models
class ChatRequest(BaseModel):
    query: str
    conversation_id: Optional[str] = None


class ChatResponse(BaseModel):
    answer: str
    sources: list[dict]
    conversation_id: str


class HealthResponse(BaseModel):
    status: str
    version: str


# Endpoints
@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    return HealthResponse(status="healthy", version="1.0.0")


@app.get("/ready")
async def ready():
    """Readiness check endpoint."""
    if rag_service is None:
        raise HTTPException(status_code=503, detail="Service not ready")
    return {"status": "ready"}


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Process a chat request using RAG."""
    CHAT_REQUESTS.inc()

    with CHAT_LATENCY.time():
        try:
            result = await rag_service.chat(
                query=request.query,
                conversation_id=request.conversation_id,
            )
            return ChatResponse(
                answer=result["answer"],
                sources=result["sources"],
                conversation_id=result["conversation_id"],
            )
        except Exception as e:
            logger.error(f"Chat error: {e}")
            raise HTTPException(status_code=500, detail=str(e))


@app.post("/documents")
async def upload_document(file: UploadFile = File(...)):
    """Upload and index a document."""
    try:
        content = await file.read()
        await rag_service.index_document(
            filename=file.filename,
            content=content,
            content_type=file.content_type,
        )
        DOCUMENTS_INDEXED.inc()
        return {"status": "accepted", "filename": file.filename}
    except Exception as e:
        logger.error(f"Document upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/documents")
async def list_documents():
    """List indexed documents."""
    try:
        documents = await rag_service.list_documents()
        return {"documents": documents}
    except Exception as e:
        logger.error(f"List documents error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
