"""
Open Horizons — Multi-Agent AI Chat Backend
FastAPI + Azure OpenAI SDK with streaming SSE responses.

7-agent system with trajectory logging and cost tracking.
Agent Router: @mention → keyword → orchestrator.
Real GitHub REST API calls via GITHUB_TOKEN.
"""

import os
import json
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel

from agents import AGENT_CONFIGS, BaseAgent
from agents.router import detect_agent, strip_mention, AGENT_DISPLAY_NAMES
from tools import execute_tool as unified_execute_tool
from middleware.trajectory import trajectory_logger
from middleware.cost_tracker import cost_tracker
from memory.context_store import shared_context

load_dotenv()

# ── Config ──────────────────────────────────────────────────────────
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY", "")
AZURE_OPENAI_API_VERSION = os.getenv("AZURE_OPENAI_API_VERSION", "2025-04-01-preview")
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-5-1")
MODEL_DISPLAY_NAME = os.getenv("MODEL_DISPLAY_NAME", "gpt-5.1")
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:7007").split(",")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("agent-api")


# ── In-Memory Conversation Store ────────────────────────────────────
conversations: dict[str, list[dict]] = {}


def create_openai_client() -> AzureOpenAI:
    """Create an Azure OpenAI client with a fresh token per request."""
    if AZURE_OPENAI_API_KEY:
        return AzureOpenAI(
            azure_endpoint=AZURE_OPENAI_ENDPOINT,
            api_key=AZURE_OPENAI_API_KEY,
            api_version=AZURE_OPENAI_API_VERSION,
        )

    credential = DefaultAzureCredential()
    token = credential.get_token("https://cognitiveservices.azure.com/.default")
    return AzureOpenAI(
        azure_endpoint=AZURE_OPENAI_ENDPOINT,
        azure_ad_token=token.token,
        api_version=AZURE_OPENAI_API_VERSION,
    )


# ── Request / Response Models ───────────────────────────────────────
class ChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None
    user: str | None = None
    agent: str | None = None


class ChatChunk(BaseModel):
    type: str  # "agent", "text", "tool_use", "tool_result", "done", "error"
    content: str = ""
    agent: str | None = None
    display_name: str | None = None
    tool_name: str | None = None
    tool_input: dict | None = None


# ── App Lifecycle ───────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    agents = list(AGENT_CONFIGS.keys())
    logger.info("Multi-Agent system starting — model=%s, deployment=%s, agents=%s",
                MODEL_DISPLAY_NAME, AZURE_OPENAI_DEPLOYMENT, agents)
    if not AZURE_OPENAI_ENDPOINT:
        logger.warning("AZURE_OPENAI_ENDPOINT not set — chat will fail")
    yield
    logger.info("Agent system shutting down")


app = FastAPI(
    title="Open Horizons Multi-Agent API",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health + Info Endpoints ─────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "model": MODEL_DISPLAY_NAME, "deployment": AZURE_OPENAI_DEPLOYMENT}


@app.get("/api/agents/info")
async def info():
    agents_info = []
    for name, config in AGENT_CONFIGS.items():
        agents_info.append({
            "name": config.name,
            "display_name": config.display_name,
            "description": config.description,
            "tools": [t["name"] for t in config.tools],
            "temperature": config.temperature,
        })
    return {
        "agents": agents_info,
        "total_agents": len(agents_info),
        "model": MODEL_DISPLAY_NAME,
        "version": "2.0.0",
    }


# ── Observability Endpoints (L5) ────────────────────────────────────
@app.get("/api/agents/trajectories")
async def get_trajectories():
    """Return trajectory summary for observability dashboard."""
    return trajectory_logger.summary()


@app.get("/api/agents/trajectories/{agent_name}")
async def get_agent_trajectories(agent_name: str):
    """Return recent trajectories for a specific agent."""
    return trajectory_logger.get_by_agent(agent_name)


@app.get("/api/agents/costs")
async def get_costs():
    """Return cost summary across all agents."""
    return cost_tracker.get_summary()


@app.get("/api/agents/costs/{agent_name}")
async def get_agent_costs(agent_name: str):
    """Return cost summary for a specific agent."""
    return cost_tracker.get_agent_summary(agent_name)


@app.get("/api/agents/context")
async def get_context():
    """Return shared context store summary."""
    return shared_context.summary()


# ── Streaming Chat Endpoint ─────────────────────────────────────────
@app.post("/api/agents/chat")
async def chat(request: ChatRequest):
    """Multi-agent chat with SSE streaming.

    Flow:
    1. Router detects agent from @mention / keywords / default
    2. Agent runs agentic loop (Claude + tools)
    3. Streamed to frontend via SSE
    """
    conv_id = request.conversation_id or "default"
    if conv_id not in conversations:
        conversations[conv_id] = []

    # Detect which agent should handle this message
    if request.agent and request.agent in AGENT_CONFIGS:
        agent_name = request.agent
    else:
        agent_name = detect_agent(request.message)

    # Clean message (remove @mention prefix)
    clean_message = strip_mention(request.message)

    # Get agent config
    agent_config = AGENT_CONFIGS.get(agent_name)
    if not agent_config:
        agent_config = AGENT_CONFIGS["orchestrator"]
        agent_name = "orchestrator"

    logger.info("Routing to agent: %s (%s)", agent_name, agent_config.display_name)

    # Start trajectory logging (L5)
    trajectory_id = trajectory_logger.start(
        agent=agent_name,
        user=request.user or "anonymous",
        message=clean_message,
    )

    # Write agent selection to shared context store (L3 CA-MCP)
    shared_context.write(
        key=f"active_agent:{conv_id}",
        value=agent_name,
        agent="router",
        ttl_seconds=300.0,
        tags=["routing", "active"],
    )

    # Create agent instance
    agent = BaseAgent(config=agent_config, tool_executor=unified_execute_tool)

    async def generate() -> AsyncGenerator[str, None]:
        client = create_openai_client()
        conv_history = conversations[conv_id].copy()
        total_input_tokens = 0
        total_output_tokens = 0

        try:
            async for chunk in agent.handle(
                message=clean_message,
                conversation=conv_history,
                client=client,
                model=AZURE_OPENAI_DEPLOYMENT,
            ):
                chunk_type = chunk.get("type", "")

                if chunk_type == "agent":
                    sse = ChatChunk(
                        type="agent",
                        agent=chunk.get("agent"),
                        display_name=chunk.get("display_name"),
                    )
                elif chunk_type == "text":
                    sse = ChatChunk(type="text", content=chunk.get("content", ""))
                elif chunk_type == "tool_use":
                    # Log tool call to trajectory (L5)
                    trajectory_logger.log_tool_call(
                        trajectory_id,
                        tool_name=chunk.get("tool_name", ""),
                        tool_input=chunk.get("tool_input", {}),
                    )
                    sse = ChatChunk(
                        type="tool_use",
                        tool_name=chunk.get("tool_name"),
                        tool_input=chunk.get("tool_input"),
                        content=chunk.get("content", ""),
                    )
                elif chunk_type == "tool_result":
                    # Log tool result to trajectory (L5)
                    trajectory_logger.log_tool_result(
                        trajectory_id,
                        tool_name=chunk.get("tool_name", ""),
                        result=chunk.get("content", ""),
                    )
                    sse = ChatChunk(
                        type="tool_result",
                        tool_name=chunk.get("tool_name"),
                        content=chunk.get("content", "")[:500],
                    )
                elif chunk_type == "done":
                    # Save conversation state
                    if "messages" in chunk:
                        conversations[conv_id] = chunk["messages"]

                    # Extract token usage if available
                    usage = chunk.get("usage", {})
                    total_input_tokens += usage.get("prompt_tokens", 0)
                    total_output_tokens += usage.get("completion_tokens", 0)

                    # Record cost (L5)
                    cost_tracker.record(
                        agent=agent_name,
                        model=AZURE_OPENAI_DEPLOYMENT,
                        input_tokens=total_input_tokens,
                        output_tokens=total_output_tokens,
                        trajectory_id=trajectory_id,
                    )

                    # Finish trajectory (L5)
                    trajectory_logger.finish(
                        trajectory_id,
                        outcome="success",
                        token_usage={
                            "input_tokens": total_input_tokens,
                            "output_tokens": total_output_tokens,
                        },
                    )

                    sse = ChatChunk(type="done")
                elif chunk_type == "error":
                    trajectory_logger.finish(trajectory_id, outcome="error")
                    sse = ChatChunk(type="error", content=chunk.get("content", ""))
                else:
                    continue

                yield f"data: {sse.model_dump_json()}\n\n"

        except Exception as e:
            logger.error("Chat error: %s", e, exc_info=True)
            trajectory_logger.finish(trajectory_id, outcome="error")
            yield f"data: {ChatChunk(type='error', content=str(e)).model_dump_json()}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


# ── Entrypoint ──────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8008"))
    uvicorn.run("main:app", host=host, port=port, reload=True, log_level=LOG_LEVEL.lower())
