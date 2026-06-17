"""
Open Horizons — Multi-Agent AI Chat Backend (Microsoft Agent Framework Edition)

7-agent system powered by MAF + AzureOpenAIClient + MCP native.
Same API contract: same endpoints, same SSE format, same frontend.

Key differences from SK version:
  - @tool decorator instead of @kernel_function
  - Agent + AzureOpenAIClient instead of Kernel
  - MCPStreamableHTTPTool for native MCP Ecosystem integration
  - Built-in tool calling loop via agent.get_response()
"""

import os
import json
import asyncio
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from agent_framework import Agent, FunctionTool, MCPStreamableHTTPTool, MCPStdioTool, Message, ChatOptions
from agent_framework.openai import AzureOpenAIClient

# Tool imports
from tools.github_tools import (
    get_workflow_runs, get_workflow_run_jobs,
    get_check_runs, get_pull_requests,
    create_issue, list_issues, get_issue,
    get_dependabot_alerts, get_code_scanning_alerts, get_secret_scanning_alerts,
)
from tools.observability_tools import (
    prometheus_query, prometheus_alerts, prometheus_targets, grafana_list_dashboards,
)
from tools.infra_tools import (
    kube_list_namespaces, kube_list_pods, kube_list_deployments, kube_get_events, kube_cluster_health,
)
from tools.backstage_tools import backstage_catalog_search, backstage_list_templates

load_dotenv()

# ── Config ──────────────────────────────────────────────────────────
AZURE_OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY", "")
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-5-1")
MAX_TOKENS = int(os.getenv("MAX_TOKENS", "4096"))
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:7007").split(",")
MCP_ECOSYSTEM_URL = os.getenv("MCP_ECOSYSTEM_URL", "http://host.docker.internal:3100/mcp")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("agent-api-maf")

# ── Common rules for all agents ────────────────────────────────────
COMMON_RULES = """
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language."""

# ── MCP Tools (native MAF integration) ─────────────────────────────
# HTTP-based MCPs
mcp_ecosystem = MCPStreamableHTTPTool(
    name="mcp_ecosystem",
    url=MCP_ECOSYSTEM_URL,
    description="MCP Ecosystem: Backstage docs, Copilot docs, GitHub Copilot docs, Spec-Kit methodology.",
)

mcp_microsoft_learn = MCPStreamableHTTPTool(
    name="mcp_microsoft_learn",
    url="https://learn.microsoft.com/api/mcp",
    description="Microsoft Learn: official Microsoft and Azure documentation, code samples, tutorials.",
)

# Stdio-based MCPs — disabled by default (slow npx downloads cause init timeouts)
# Enable individually via env vars when pre-installed in the container.
ADO_PAT = os.getenv("AZURE_DEVOPS_PAT", "")
ENABLE_STDIO_MCPS = os.getenv("ENABLE_STDIO_MCPS", "false").lower() == "true"

mcp_azure_devops = MCPStdioTool(
    name="mcp_azure_devops",
    command="npx",
    args=["-y", "@azure-devops/mcp@latest", "open-horizonstech",
          "-d", "core", "-d", "repositories", "-d", "pipelines",
          "-d", "work-items", "-d", "search", "-d", "wiki"],
    description="Azure DevOps: repos, pipelines, work items, search, wiki for open-horizonstech org.",
) if ADO_PAT and ENABLE_STDIO_MCPS else None

mcp_playwright = MCPStdioTool(
    name="mcp_playwright",
    command="npx",
    args=["@playwright/mcp@latest"],
    description="Playwright: browser automation, web scraping, UI testing.",
) if ENABLE_STDIO_MCPS else None

mcp_awesome_copilot = MCPStdioTool(
    name="mcp_awesome_copilot",
    command="docker",
    args=["run", "-i", "--rm", "ghcr.io/microsoft/mcp-dotnet-samples/awesome-copilot:1.0.2026031800"],
    description="Awesome Copilot: curated catalog of Copilot agents, skills, prompts, and instructions.",
) if ENABLE_STDIO_MCPS else None

mcp_azure = MCPStdioTool(
    name="mcp_azure",
    command="npx",
    args=["-y", "Azure.Mcp@2.0.0-beta.23", "--yes", "--", "server", "start"],
    description="Azure MCP: manage Azure resources, subscriptions, resource groups, services.",
) if ENABLE_STDIO_MCPS else None

mcp_figma = MCPStreamableHTTPTool(
    name="mcp_figma",
    url="https://mcp.figma.com/mcp",
    description="Figma: design files, components, variables, screenshots, code connect.",
) if os.getenv("FIGMA_TOKEN") else None

# Collect all available MCP tools (filter None)
ALL_MCP_TOOLS = [t for t in [
    mcp_ecosystem, mcp_microsoft_learn, mcp_figma,
    mcp_azure_devops, mcp_playwright, mcp_awesome_copilot, mcp_azure,
] if t is not None]

logger.info("MCP tools loaded: %s", [t.name for t in ALL_MCP_TOOLS])


# ── Agent Definitions ──────────────────────────────────────────────
def _create_client() -> AzureOpenAIClient:
    return AzureOpenAIClient(api_key=AZURE_OPENAI_API_KEY, endpoint=AZURE_OPENAI_ENDPOINT, model_id=AZURE_OPENAI_DEPLOYMENT)


AGENT_DEFS: dict[str, dict] = {
    "pipeline": {
        "display_name": "Pipeline — CI/CD Diagnostics",
        "description": "Diagnoses GitHub Actions pipeline failures using real workflow run data.",
        "instructions": f"""You are **Pipeline**, the CI/CD diagnostics specialist for the Open Horizons platform.

Use get_workflow_runs to fetch recent runs, get_workflow_run_jobs to drill into failures.
Start with a one-line diagnosis, show failed details, provide numbered remediation steps.
{COMMON_RULES}""",
        "tools": [get_workflow_runs, get_workflow_run_jobs],
        "temperature": 0.3,
        "keywords": ["pipeline", "ci/cd", "cicd", "build fail", "workflow fail", "action fail",
                      "deploy fail", "github action", "workflow run", "build error", "build", "deploy"],
    },
    "sentinel": {
        "display_name": "Sentinel — Test & Coverage",
        "description": "Analyzes CI check runs and pull requests to assess test quality.",
        "instructions": f"""You are **Sentinel**, the test and coverage specialist for the Open Horizons platform.

Use get_check_runs for CI status checks, get_pull_requests for PR review state.
Show check conclusion status clearly, flag failing required checks.
{COMMON_RULES}""",
        "tools": [get_check_runs, get_pull_requests],
        "temperature": 0.3,
        "keywords": ["test", "coverage", "unit test", "integration test", "testing", "quality gate", "check run"],
    },
    "compass": {
        "display_name": "Compass — Planning & Stories",
        "description": "Decomposes epics into INVEST user stories and creates GitHub Issues.",
        "instructions": f"""You are **Compass**, the planning specialist for the Open Horizons platform.

Decompose epics into max 8 INVEST user stories. Use create_issue to create GitHub Issues.
Use list_issues/get_issue to check for duplicates first.
{COMMON_RULES}""",
        "tools": [create_issue, list_issues, get_issue],
        "temperature": 0.5,
        "keywords": ["epic", "user story", "stories", "decompose", "sprint planning", "planning",
                      "issue", "create issue", "backlog"],
    },
    "guardian": {
        "display_name": "Guardian — Security & Compliance",
        "description": "Scans repositories for vulnerabilities, exposed secrets, and compliance issues.",
        "instructions": f"""You are **Guardian**, the security specialist for the Open Horizons platform.

Use get_dependabot_alerts for dependency vulnerabilities, get_code_scanning_alerts for SAST findings,
get_secret_scanning_alerts for exposed secrets. Start with a security posture summary.
Prioritize critical/high severity. Flag exposed secrets as URGENT.
{COMMON_RULES}""",
        "tools": [get_dependabot_alerts, get_code_scanning_alerts, get_secret_scanning_alerts, *ALL_MCP_TOOLS],
        "temperature": 0.3,
        "keywords": ["security", "vulnerability", "CVE", "dependabot", "compliance", "secret scan",
                      "code scan", "CodeQL", "SAST", "patch"],
    },
    "lighthouse": {
        "display_name": "Lighthouse — Observability & SRE",
        "description": "Monitors cluster health, queries metrics, checks alerts using Prometheus and Grafana.",
        "instructions": f"""You are **Lighthouse**, the observability specialist for the Open Horizons platform.

Use prometheus_alerts first for quick assessment. Use prometheus_query for specific PromQL queries.
Use prometheus_targets to verify scrape health. Use grafana_list_dashboards to find dashboards.

Common PromQL:
- CPU: 100 - (avg(rate(node_cpu_seconds_total{{mode="idle"}}[5m])) * 100)
- Memory: (1 - node_memory_AvailableBytes / node_memory_MemTotal) * 100
- Pod restarts: increase(kube_pod_container_status_restarts_total[1h])
{COMMON_RULES}""",
        "tools": [prometheus_query, prometheus_alerts, prometheus_targets, grafana_list_dashboards, *ALL_MCP_TOOLS],
        "temperature": 0.3,
        "keywords": ["alert", "metrics", "latency", "incident", "SLO", "prometheus", "grafana",
                      "monitoring", "observability", "dashboard", "health check"],
    },
    "forge": {
        "display_name": "Forge — Infrastructure & Cloud",
        "description": "Inspects Kubernetes clusters, namespaces, deployments, pods, and services.",
        "instructions": f"""You are **Forge**, the infrastructure specialist for the Open Horizons platform.

Use kube_cluster_health for overall status. Use kube_list_pods to check pod status.
Use kube_list_deployments for replica counts. Use kube_get_events for recent warnings.
Flag pods with high restart counts (>5) or CrashLoopBackOff.
{COMMON_RULES}""",
        "tools": [kube_list_namespaces, kube_list_pods, kube_list_deployments, kube_get_events,
                  kube_cluster_health, *ALL_MCP_TOOLS],
        "temperature": 0.3,
        "keywords": ["kubernetes", "k8s", "cluster", "infra", "namespace", "pod", "deployment",
                      "service", "node", "replica", "kubectl", "container", "restart", "crash"],
    },
    "orchestrator": {
        "display_name": "Open Horizons Assistant",
        "description": "General assistant that routes to specialist agents.",
        "instructions": f"""You are the **Open Horizons Assistant** — the default AI agent.

SPECIALIST AGENTS:
- @pipeline — CI/CD diagnostics
- @sentinel — Test & coverage
- @compass — Planning & stories
- @guardian — Security & compliance
- @lighthouse — Observability & SRE
- @forge — Infrastructure & cloud

Route to the right specialist when appropriate. Answer general platform questions directly.
{COMMON_RULES}""",
        "tools": [backstage_catalog_search, backstage_list_templates, *ALL_MCP_TOOLS],
        "temperature": 0.5,
        "keywords": [],
    },
}


# ── Agent Router ───────────────────────────────────────────────────
import re

MENTION_MAP = {f"@{name}": name for name in AGENT_DEFS if name != "orchestrator"}


def detect_agent(message: str) -> str:
    msg = message.lower().strip()
    for mention, name in MENTION_MAP.items():
        if mention in msg:
            return name
    for name, defn in AGENT_DEFS.items():
        for kw in defn.get("keywords", []):
            if kw in msg:
                return name
    return "orchestrator"


def strip_mention(message: str) -> str:
    return re.sub(r"@\w+\s*", "", message).strip()


# ── In-Memory Conversation + Agent Context Store ───────────────────
conversations: dict[str, list] = {}
conversation_agents: dict[str, str] = {}  # tracks which agent is active per conversation


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


# ── App ─────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    agents = list(AGENT_DEFS.keys())
    logger.info("MAF Multi-Agent starting — model=%s, agents=%s, mcp=%s", AZURE_OPENAI_DEPLOYMENT, agents, MCP_ECOSYSTEM_URL)
    if not AZURE_OPENAI_API_KEY:
        logger.warning("AZURE_OPENAI_API_KEY not set — chat will fail")
    yield
    logger.info("MAF Agent system shutting down")


app = FastAPI(title="Open Horizons Multi-Agent API (MAF)", version="3.0.0-maf", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=CORS_ORIGINS, allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])


@app.get("/health")
async def health():
    return {"status": "ok", "model": AZURE_OPENAI_DEPLOYMENT, "engine": "microsoft-agent-framework"}


@app.get("/api/agents/info")
async def info():
    agents_info = [{"name": name, "display_name": d["display_name"], "description": d["description"],
                    "tools": [t.name if hasattr(t, 'name') else str(t) for t in d["tools"]],
                    "temperature": d["temperature"]} for name, d in AGENT_DEFS.items()]
    return {"agents": agents_info, "total_agents": len(agents_info), "model": AZURE_OPENAI_DEPLOYMENT,
            "engine": "microsoft-agent-framework", "version": "3.0.0-maf"}


@app.post("/api/agents/chat")
async def chat(request: ChatRequest):
    """Multi-agent chat with SSE streaming — powered by Microsoft Agent Framework."""
    conv_id = request.conversation_id or "default"
    if conv_id not in conversations:
        conversations[conv_id] = []

    # Agent routing: explicit > @mention > keyword > keep previous agent > orchestrator
    if request.agent and request.agent in AGENT_DEFS:
        agent_name = request.agent
    else:
        detected = detect_agent(request.message)
        if detected != "orchestrator":
            agent_name = detected
        elif conv_id in conversation_agents:
            # Keep the same agent within a conversation (avoids losing context)
            agent_name = conversation_agents[conv_id]
        else:
            agent_name = "orchestrator"

    clean_message = strip_mention(request.message)
    defn = AGENT_DEFS.get(agent_name, AGENT_DEFS["orchestrator"])
    conversation_agents[conv_id] = agent_name

    logger.info("Routing to agent: %s (%s) [MAF]", agent_name, defn["display_name"])

    # Create MAF Agent with AzureOpenAIClient
    client = _create_client()
    agent = Agent(
        client=client,
        name=agent_name,
        instructions=defn["instructions"],
        tools=[t for t in defn["tools"] if t is not None],
        default_options=ChatOptions(temperature=defn["temperature"], max_tokens=MAX_TOKENS),
    )

    # Run agent (MAF handles full agentic loop including tool calls)
    history = conversations[conv_id].copy()
    history.append(Message(role="user", text=clean_message))

    try:
        response = await agent.run(messages=history)
        text_content = response.text or ""
        logger.info("Agent %s responded: %d chars", agent_name, len(text_content))

        # Save conversation
        history.append(Message(role="assistant", text=text_content))
        conversations[conv_id] = history

    except (Exception, asyncio.CancelledError) as e:
        logger.error("Chat error in %s: %s", agent_name, e, exc_info=True)
        text_content = ""
        error_text = str(e)

        async def error_stream() -> AsyncGenerator[str, None]:
            yield f"data: {ChatChunk(type='agent', agent=agent_name, display_name=defn['display_name']).model_dump_json()}\n\n"
            yield f"data: {ChatChunk(type='error', content=error_text).model_dump_json()}\n\n"

        return StreamingResponse(error_stream(), media_type="text/event-stream")

    # Build SSE response from completed agent run
    async def generate() -> AsyncGenerator[str, None]:
        yield f"data: {ChatChunk(type='agent', agent=agent_name, display_name=defn['display_name']).model_dump_json()}\n\n"
        if text_content:
            yield f"data: {ChatChunk(type='text', content=text_content).model_dump_json()}\n\n"
        yield f"data: {ChatChunk(type='done').model_dump_json()}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8010"))
    uvicorn.run("main:app", host=host, port=port, reload=True, log_level=LOG_LEVEL.lower())
