"""RAG Service implementation."""
import uuid
import logging
from typing import Optional

from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery
from azure.core.credentials import AzureKeyCredential
from openai import AzureOpenAI

logger = logging.getLogger(__name__)


class RAGService:
    """Retrieval-Augmented Generation service."""

    def __init__(
        self,
        openai_endpoint: str,
        openai_key: str,
        openai_deployment: str,
        search_endpoint: str,
        search_key: str,
        search_index: str,
    ):
        """Initialize RAG service."""
        self.openai_client = AzureOpenAI(
            azure_endpoint=openai_endpoint,
            api_key=openai_key,
            api_version="2024-02-15-preview",
        )
        self.openai_deployment = openai_deployment

        self.search_client = SearchClient(
            endpoint=search_endpoint,
            index_name=search_index,
            credential=AzureKeyCredential(search_key),
        )

        self.conversations: dict = {}

    async def chat(
        self,
        query: str,
        conversation_id: Optional[str] = None,
    ) -> dict:
        """Process a chat query with RAG."""
        # Get or create conversation
        if conversation_id is None:
            conversation_id = str(uuid.uuid4())
            self.conversations[conversation_id] = []

        history = self.conversations.get(conversation_id, [])

        # Generate embedding for query
        embedding = await self._get_embedding(query)

        # Search for relevant documents
        results = self._search_documents(embedding, query)

        # Build context from search results
        context = self._build_context(results)
        sources = [{"id": r["id"], "title": r.get("title", ""), "score": r["@search.score"]} for r in results]

        # Generate response
        answer = await self._generate_response(query, context, history)

        # Update conversation history
        history.append({"role": "user", "content": query})
        history.append({"role": "assistant", "content": answer})
        self.conversations[conversation_id] = history[-10:]  # Keep last 10 messages

        return {
            "answer": answer,
            "sources": sources,
            "conversation_id": conversation_id,
        }

    async def _get_embedding(self, text: str) -> list[float]:
        """Generate embedding for text."""
        response = self.openai_client.embeddings.create(
            model="text-embedding-3-large",
            input=text,
        )
        return response.data[0].embedding

    def _search_documents(self, embedding: list[float], query: str, top_k: int = 5) -> list:
        """Search for relevant documents."""
        vector_query = VectorizedQuery(
            vector=embedding,
            k_nearest_neighbors=top_k,
            fields="content_vector",
        )

        results = self.search_client.search(
            search_text=query,
            vector_queries=[vector_query],
            select=["id", "title", "content", "source"],
            top=top_k,
        )

        return list(results)

    def _build_context(self, results: list) -> str:
        """Build context string from search results."""
        context_parts = []
        for i, result in enumerate(results, 1):
            content = result.get("content", "")
            title = result.get("title", f"Document {i}")
            context_parts.append(f"[{i}] {title}:\n{content}\n")
        return "\n".join(context_parts)

    async def _generate_response(self, query: str, context: str, history: list) -> str:
        """Generate response using OpenAI."""
        system_prompt = """You are a helpful assistant that answers questions based on the provided context.
Always cite your sources using [1], [2], etc. when referencing information from the context.
If you cannot find the answer in the context, say so clearly.
Be concise and accurate."""

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {query}"},
        ]

        # Add conversation history
        for msg in history[-4:]:  # Last 4 messages for context
            messages.insert(-1, msg)

        response = self.openai_client.chat.completions.create(
            model=self.openai_deployment,
            messages=messages,
            temperature=0.7,
            max_tokens=1000,
        )

        return response.choices[0].message.content

    async def index_document(self, filename: str, content: bytes, content_type: str) -> None:
        """Index a document for RAG."""
        # TODO: Implement document processing and indexing
        logger.info(f"Indexing document: {filename}")
        pass

    async def list_documents(self) -> list[dict]:
        """List indexed documents."""
        # TODO: Implement document listing
        return []
