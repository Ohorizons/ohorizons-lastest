"""
Open Horizons — Multi-Agent AI Chat Backend (Semantic Kernel Edition)

Same API contract as agent-api but powered by Semantic Kernel + Azure OpenAI (GPT-5.1 via Foundry).
Drop-in replacement: same endpoints, same SSE format, same frontend.
"""

import os
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

from agents import AGENT_CONFIGS, AgentConfig
from agents.base import BaseAgent
from agents.router import detect_agent, strip_mention
from plugins.github_plugin import GitHubPlugin
from plugins.backstage_plugin import BackstagePlugin
from plugins.ecosystem_plugin import EcosystemPlugin
from plugins.security_plugin import SecurityPlugin
from plugins.observability_plugin import ObservabilityPlugin
from plugins.infra_plugin import InfraPlugin

load_dotenv()

# ── Config ──────────────────────────────────────────────────────────
AZURE_OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY", "")
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-5-1")
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:7007").split(",")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("agent-api-sk")

# ── Plugin Registry ────────────────────────────────────────────────
PLUGIN_INSTANCES = {
    "github": GitHubPlugin(),
    "backstage": BackstagePlugin(),
    "ecosystem": EcosystemPlugin(),
    "security": SecurityPlugin(),
    "observability": ObservabilityPlugin(),
    "infra": InfraPlugin(),
}


def create_kernel_for_agent(config: AgentConfig) -> Kernel:
    """Create a Semantic Kernel with only the plugins this agent needs."""
    kernel = Kernel()
    kernel.add_service(
        AzureChatCompletion(
            ai_model_id=AZURE_OPENAI_DEPLOYMENT,
            api_key=AZURE_OPENAI_API_KEY,
            service_id="claude",
        )
    )
    for plugin_name in config.plugins:
        plugin = PLUGIN_INSTANCES.get(plugin_name)
        if plugin:
            kernel.add_plugin(plugin, plugin_name=plugin_name)
    return kernel


# ── In-Memory Conversation Store ────────────────────────────────────
conversations: dict[str, list[dict]] = {}


# ── Request / Response Models ───────────────────────────────────────
class ChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None
    user: str | None = None
    agent: str | None = None


class ChatChunk(BaseModel):
    type: str
    content: str = ""
    agent: str | None = None
    display_name: str | None = None
    tool_name: str | None = None
    tool_input: dict | None = None


# ── App Lifecycle ───────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    agents = list(AGENT_CONFIGS.keys())
    logger.info("SK Multi-Agent starting — model=%s, agents=%s", AZURE_OPENAI_DEPLOYMENT, agents)
    if not AZURE_OPENAI_API_KEY:
        logger.warning("AZURE_OPENAI_API_KEY not set — chat will fail")
    yield
    logger.info("SK Agent system shutting down")


app = FastAPI(
    title="Open Horizons Multi-Agent API (Semantic Kernel)",
    version="2.0.0-sk",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok", "model": AZURE_OPENAI_DEPLOYMENT, "engine": "semantic-kernel"}


@app.get("/api/agents/info")
async def info():
    agents_info = []
    for name, config in AGENT_CONFIGS.items():
        agents_info.append({
            "name": config.name,
            "display_name": config.display_name,
            "description": config.description,
            "plugins": config.plugins,
            "temperature": config.temperature,
        })
    return {
        "agents": agents_info,
        "total_agents": len(agents_info),
        "model": AZURE_OPENAI_DEPLOYMENT,
        "engine": "semantic-kernel",
        "version": "2.0.0-sk",
    }


@app.post("/api/agents/chat")
async def chat(request: ChatRequest):
    """Multi-agent chat with SSE streaming — powered by Semantic Kernel."""
    conv_id = request.conversation_id or "default"
    if conv_id not in conversations:
        conversations[conv_id] = []

    if request.agent and request.agent in AGENT_CONFIGS:
        agent_name = request.agent
    else:
        agent_name = detect_agent(request.message)

    clean_message = strip_mention(request.message)

    agent_config = AGENT_CONFIGS.get(agent_name)
    if not agent_config:
        agent_config = AGENT_CONFIGS["orchestrator"]
        agent_name = "orchestrator"

    logger.info("Routing to agent: %s (%s) [SK]", agent_name, agent_config.display_name)

    kernel = create_kernel_for_agent(agent_config)
    agent = BaseAgent(config=agent_config, kernel=kernel)

    async def generate() -> AsyncGenerator[str, None]:
        conv_history = conversations[conv_id].copy()
        try:
            async for chunk in agent.handle(
                message=clean_message,
                conversation=conv_history,
                model=AZURE_OPENAI_DEPLOYMENT,
            ):
                chunk_type = chunk.get("type", "")
                if chunk_type == "agent":
                    sse = ChatChunk(type="agent", agent=chunk.get("agent"), display_name=chunk.get("display_name"))
                elif chunk_type == "text":
                    sse = ChatChunk(type="text", content=chunk.get("content", ""))
                elif chunk_type == "tool_use":
                    sse = ChatChunk(type="tool_use", tool_name=chunk.get("tool_name"), tool_input=chunk.get("tool_input"), content=chunk.get("content", ""))
                elif chunk_type == "tool_result":
                    sse = ChatChunk(type="tool_result", tool_name=chunk.get("tool_name"), content=chunk.get("content", "")[:500])
                elif chunk_type == "done":
                    sse = ChatChunk(type="done")
                elif chunk_type == "error":
                    sse = ChatChunk(type="error", content=chunk.get("content", ""))
                else:
                    continue
                yield f"data: {sse.model_dump_json()}\n\n"
        except Exception as e:
            logger.error("Chat error: %s", e, exc_info=True)
            yield f"data: {ChatChunk(type='error', content=str(e)).model_dump_json()}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8009"))
    uvicorn.run("main:app", host=host, port=port, reload=True, log_level=LOG_LEVEL.lower())
