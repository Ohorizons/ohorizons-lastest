"""FastAPI service exposing OpenAI-compatible Chat Completions API.

Routes:
- GET  /healthz                   — liveness
- GET  /readyz                    — readiness
- GET  /v1/models                 — OpenAI-compatible model list
- GET  /v1/agents                 — list specialized agents
- POST /v1/chat/completions       — OpenAI-compatible chat (Azure OpenAI backend)
- POST /v1/agents/{agent_id}/chat — agent-flavoured chat (auto-injects system prompt)
"""
from __future__ import annotations

import json
import logging
import time
from typing import Annotated, Any

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field
from starlette.concurrency import run_in_threadpool

from . import a2a as a2a_mod
from . import cache as cache_mod
from . import purview_audit as purview_mod
from . import telemetry as telemetry_mod
from . import tool_hooks as tool_hooks_mod
from .agents import AGENTS, get_agent, list_agents
from .azure_openai import AadCredentials, AzureOpenAIClient
from .config import Settings
from .cosmos_memory import CosmosMemoryClient, CosmosMemoryUnavailable
from .toolbox import ToolboxManifest, build_manifest

settings = Settings.from_env()

logging.basicConfig(
    level=settings.log_level,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("foundry-agents")

app = FastAPI(
    title="Open Horizons Foundry Agents",
    description="OpenAI-compatible gateway with specialized agents backed by Azure OpenAI",
    version="1.0.0",
)


def _build_client() -> AzureOpenAIClient:
    if settings.auth_mode == "api-key":
        logger.info("using api-key auth for Azure OpenAI")
        return AzureOpenAIClient(
            endpoint=settings.azure_openai_endpoint,
            deployment=settings.azure_openai_deployment,
            api_version=settings.azure_openai_api_version,
            api_key=settings.azure_openai_api_key,
            timeout_seconds=settings.request_timeout_seconds,
        )
    logger.info("using AAD client-credentials auth for Azure OpenAI")
    creds = AadCredentials(
        tenant_id=settings.azure_tenant_id or "",
        client_id=settings.azure_client_id or "",
        client_secret=settings.azure_client_secret or "",
    )
    return AzureOpenAIClient(
        endpoint=settings.azure_openai_endpoint,
        deployment=settings.azure_openai_deployment,
        api_version=settings.azure_openai_api_version,
        aad_credentials=creds,
        timeout_seconds=settings.request_timeout_seconds,
    )


_client = _build_client()
_memory_client = CosmosMemoryClient.from_settings(settings)


def _build_toolbox() -> ToolboxManifest:
    try:
        return build_manifest(a2a_agent_ids=sorted(AGENTS.keys()))
    except (OSError, ValueError, KeyError) as exc:  # missing mcp-config.json etc.
        logger.warning("toolbox manifest unavailable: %s", exc)
        return ToolboxManifest(environment="dev", tools=[])


_toolbox = _build_toolbox()


def _semantic_embedder() -> "Any | None":
    """Local sentence-transformer (all-MiniLM-L6-v2, REQ-REDIS-003) for the semantic cache.

    Optional: only used when ``sentence-transformers`` is installed. Returns ``None`` (semantic
    cache disabled) otherwise — the exact cache still works without it.
    """
    try:  # pragma: no cover - optional heavy dependency
        from sentence_transformers import SentenceTransformer  # type: ignore

        model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
        return lambda text: list(map(float, model.encode(text)))
    except Exception:  # noqa: BLE001
        logger.info("sentence-transformers not available — semantic cache disabled (exact cache still active)")
        return None


def _build_prompt_cache() -> cache_mod.HierarchicalCache:
    if not settings.prompt_cache_enabled:
        # disabled: a no-op cache (no Redis, no embedder) — safe default
        return cache_mod.build_hierarchical_cache(redis_url=None, embedder=None)
    return cache_mod.build_hierarchical_cache(redis_url=settings.redis_url, embedder=_semantic_embedder())


_prompt_cache = _build_prompt_cache()


# ───────────────────────── auth ─────────────────────────
def require_auth(authorization: str | None = Header(default=None)) -> None:
    """Optional bearer-token check (only enforced if SERVICE_API_KEY is set)."""
    if settings.service_api_key is None:
        return
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    if token != settings.service_api_key:
        raise HTTPException(status_code=401, detail="invalid bearer token")


AuthDependency = Annotated[None, Depends(require_auth)]


# ───────────────────────── schemas ──────────────────────
class ChatMessage(BaseModel):
    role: str
    content: str | None = None
    name: str | None = None
    tool_calls: list[dict[str, Any]] | None = None
    tool_call_id: str | None = None


class ChatCompletionRequest(BaseModel):
    model: str | None = None
    messages: list[ChatMessage]
    temperature: float | None = None
    max_tokens: int | None = None
    stream: bool = False
    tools: list[dict[str, Any]] | None = None
    tool_choice: Any | None = None

    class Config:
        extra = "allow"


class AgentDescriptor(BaseModel):
    id: str
    name: str
    description: str
    suggested_temperature: float = Field(default=0.2)


# ───────────────────────── routes ───────────────────────
@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/readyz")
async def readyz() -> dict[str, str]:
    return {
        "status": "ready",
        "deployment": settings.azure_openai_deployment,
        "auth_mode": settings.auth_mode,
        "memory_provider": "cosmos" if settings.cosmos_memory_enabled else "disabled",
        "memory_database": settings.cosmos_database_name,
        "memory_container": settings.cosmos_container_name,
    }


@app.post(
    "/v1/memory/probe",
    responses={
        502: {"description": "Cosmos memory probe failed"},
        503: {"description": "Cosmos memory is disabled or not configured"},
    },
)
async def memory_probe(_: AuthDependency) -> dict[str, str]:
    try:
        result = await run_in_threadpool(_memory_client.probe)
    except CosmosMemoryUnavailable as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except (RuntimeError, ValueError, httpx.HTTPError) as exc:
        logger.exception("Cosmos memory probe failed")
        raise HTTPException(
            status_code=502,
            detail=f"Cosmos memory probe failed: {exc}",
        ) from exc
    # REQ-PURVIEW-001: the Cosmos memory store holds chat threads (pii / lgpd-protected) — emit a
    # Purview audit event for the read. Best-effort: no-op without PURVIEW_AUDIT_INGEST_URL.
    try:
        purview_mod.audit_classified_access(
            agent_id="foundry-agents.memory-probe",
            model_id=settings.azure_openai_deployment,
            user_id="service:foundry-agents",
            data_source=f"cosmos://{result.database}/{result.container}",
            data_classification=purview_mod.LGPD_PROTECTED,
            access_type=purview_mod.ACCESS_READ,
            purpose="memory.probe (REQ-VER liveness check on the agent thread store)",
        )
    except Exception:  # noqa: BLE001 - audit must never break the probe
        logger.debug("purview audit emit skipped", exc_info=True)
    return {
        "status": result.status,
        "database": result.database,
        "container": result.container,
        "tenant_id": result.tenant_id,
        "document_id": result.document_id,
    }


@app.get("/v1/agents")
async def get_agents(_: AuthDependency) -> list[AgentDescriptor]:
    return [
        AgentDescriptor(
            id=a.id,
            name=a.name,
            description=a.description,
            suggested_temperature=a.suggested_temperature,
        )
        for a in list_agents()
    ]


@app.get("/v1/models")
async def get_models(_: AuthDependency) -> dict[str, Any]:
    deployments = [settings.azure_openai_deployment]
    return {
        "object": "list",
        "data": [
            {
                "id": dep,
                "object": "model",
                "created": int(time.time()),
                "owned_by": "azure-openai",
            }
            for dep in deployments
        ],
    }


# ───────────────────── Foundry Toolbox (REQ-TOOLBOX-001..004) ───────────────
class ToolCallRequest(BaseModel):
    name: str
    arguments: dict[str, Any] = Field(default_factory=dict)
    write: bool = False
    approved: bool = False


@app.get("/v1/toolbox")
async def toolbox_summary(_: AuthDependency) -> dict[str, Any]:
    """Aggregated tool catalog summary (MCP servers + built-ins + OpenAPI + A2A)."""
    return _toolbox.summary()


@app.post("/v1/toolbox/list_tools")
async def toolbox_list_tools(_: AuthDependency) -> dict[str, Any]:
    """MCP ``list_tools`` response over the aggregated Toolbox catalog."""
    return _toolbox.to_mcp_list_tools()


@app.get("/v1/toolbox/health")
async def toolbox_health() -> dict[str, Any]:
    """Health for the Toolbox surface (drives `scripts/toolbox-fallback.sh`)."""
    summary = _toolbox.summary()
    mcp_count = summary["by_category"].get("mcp", 0)
    builtin_count = summary["by_category"].get("builtin", 0)
    healthy = mcp_count >= 1 and builtin_count >= 4
    body = {
        "status": "ok" if healthy else "degraded",
        "mcp_tools": mcp_count,
        "builtin_tools": builtin_count,
        "categories": sorted(summary["by_category"].keys()),
        "environment": summary["environment"],
    }
    return JSONResponse(body, status_code=200 if healthy else 503)


@app.post(
    "/v1/toolbox/call_tool",
    responses={
        202: {"description": "Tool call requires human approval (REQ-TOOLBOX-003)"},
        400: {"description": "Unsafe arguments rejected by the preToolUse hook"},
        403: {"description": "Session token budget exhausted (preToolUse cost gate)"},
        404: {"description": "Unknown tool"},
        501: {"description": "Downstream tool proxying is handled by the managed Foundry Toolbox"},
    },
)
async def toolbox_call_tool(req: ToolCallRequest, request: Request, _: AuthDependency) -> Any:
    """Run the preToolUse hook (cache → cost gate → approval → arg validation → audit),
    then hand off to the managed Toolbox for execution (``501`` here — this gateway is the
    GA-only surface). A cache hit short-circuits with the cached result.
    """
    tool = _toolbox.get(req.name)
    if tool is None:
        raise HTTPException(status_code=404, detail=f"unknown tool '{req.name}'")
    ctx = _cache_ctx_from_headers(request)
    budget_hdr = request.headers.get("x-th-budget-remaining-usd")
    pre = tool_hooks_mod.pre_tool_use(
        req.name,
        req.arguments,
        ctx,
        require_approval=tool.require_approval,
        approved=req.approved,
        write=req.write,
        budget_remaining_usd=float(budget_hdr) if budget_hdr else None,
    )
    logger.info("toolbox.pre_use %s -> %s", req.name, pre.audit.get("outcome"), extra={"audit": pre.audit})
    if pre.cache_hit:
        return JSONResponse({"status": "cache_hit", "tool": req.name, "tier": pre.cache_tier, "result": pre.cache_value})
    if not pre.ok:
        reason = pre.blocked_reason or "blocked"
        if "approval" in (pre.audit.get("outcome") or ""):
            return JSONResponse(
                {"status": "approval_required", "tool": req.name, "require_approval": tool.require_approval, "detail": reason},
                status_code=202,
            )
        status = 403 if pre.audit.get("outcome") == "blocked_budget" else 400
        return JSONResponse({"status": "blocked", "tool": req.name, "reason": reason}, status_code=status)
    return JSONResponse(
        {
            "status": "approved",
            "tool": req.name,
            "category": tool.category,
            "validated_args": pre.validated_args,
            "detail": "approved; execute via the managed Foundry Toolbox endpoint (postToolUse hook runs on its result)",
        },
        status_code=501,
    )


@app.get("/v1/cache/stats")
async def cache_stats(_: AuthDependency) -> dict[str, Any]:
    """Prompt/response cache hit-rate + per-tier/scope counters (REQ-CACHE-005 instrumentation)."""
    return {
        "enabled": _prompt_cache.enabled,
        "exact_backend": "redis" if _prompt_cache.exact.enabled else "disabled",
        "semantic_backend": "redis+sentence-transformers" if _prompt_cache.semantic.enabled else "disabled",
        **_prompt_cache.stats.to_metrics(),
    }


def _serialize_messages(messages: list[ChatMessage]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for m in messages:
        d = m.model_dump(exclude_none=True)
        out.append(d)
    return out


def _cache_ctx_from_headers(request: Request | None) -> dict[str, str]:
    """Per-request context from `x-th-*` headers: tenant/project/session (cache scoping) +
    user/team/request id (FinOps telemetry, REQ-FINOPS-001)."""
    if request is None:
        return {}
    h = request.headers
    return {
        k: v
        for k, v in {
            "tenant_id": h.get("x-th-tenant-id", ""),
            "project_id": h.get("x-th-project-id", ""),
            "session_id": h.get("x-th-session-id", ""),
            "user_id": h.get("x-th-user-id", ""),
            "team_id": h.get("x-th-team-id", ""),
            "request_id": h.get("x-th-request-id", "") or h.get("x-request-id", ""),
        }.items()
        if v
    }


def _emit_llm_telemetry(
    resp: Any,
    *,
    model: str | None,
    ctx: dict[str, str],
    agent_id: str,
    mode: str,
    latency_ms: float,
) -> None:
    """Best-effort 21-field `llm.call.completed` emit to Application Insights (REQ-FINOPS-001).
    Never raises — telemetry must not break a chat request."""
    cs = settings.app_insights_connection_string
    if not cs or not isinstance(resp, dict):
        return
    try:
        usage = resp.get("usage") or {}
        tool_calls = 0
        for choice in resp.get("choices") or []:
            tool_calls += len((choice.get("message") or {}).get("tool_calls") or [])
        attrs = telemetry_mod.build_llm_call_attributes(
            usage,
            request_id=ctx.get("request_id") or None,
            session_id=ctx.get("session_id", ""),
            user_id=ctx.get("user_id", ""),
            team_id=ctx.get("team_id", ""),
            model_name=str(resp.get("model") or model or settings.azure_openai_deployment),
            mode=mode,
            latency_total_ms=latency_ms,
            tool_calls_count=tool_calls,
        )
        if agent_id:
            attrs["agent_id"] = agent_id
        telemetry_mod.emit_llm_call_completed(attrs, connection_string=cs)
    except (RuntimeError, ValueError, KeyError, httpx.HTTPError, ImportError):  # pragma: no cover - best-effort
        logger.debug("llm telemetry emit skipped", exc_info=True)


def _streaming_response(msgs: list[dict[str, Any]], payload: ChatCompletionRequest, temperature: float | None) -> StreamingResponse:
    async def gen():
        try:
            async for chunk in _client.chat_completion_stream(
                messages=msgs,
                model=payload.model,
                temperature=temperature,
                max_tokens=payload.max_tokens,
                tools=payload.tools,
                tool_choice=payload.tool_choice,
            ):
                yield chunk
        except (RuntimeError, ValueError, httpx.HTTPError) as exc:
            logger.exception("stream failed")
            err = json.dumps({"error": {"type": type(exc).__name__, "message": str(exc)}})
            yield f"data: {err}\n\n".encode("utf-8")

    return StreamingResponse(gen(), media_type="text/event-stream")


async def _call_model(msgs: list[dict[str, Any]], payload: ChatCompletionRequest, temperature: float | None) -> Any:
    try:
        return await _client.chat_completion(
            messages=msgs,
            model=payload.model,
            temperature=temperature,
            max_tokens=payload.max_tokens,
            tools=payload.tools,
            tool_choice=payload.tool_choice,
        )
    except (RuntimeError, ValueError, httpx.HTTPError) as exc:
        logger.exception("completion failed")
        raise HTTPException(status_code=502, detail=f"upstream error: {exc}") from exc


def _is_cache_eligible(payload: ChatCompletionRequest, temperature: float | None) -> bool:
    # plain, non-streaming, non-tool, deterministic-ish; disabled by default (PROMPT_CACHE_ENABLED)
    return (
        _prompt_cache.enabled
        and not payload.stream
        and not payload.tools
        and (temperature is None or temperature <= 0.2)
    )


async def _do_completion(
    payload: ChatCompletionRequest,
    *,
    extra_system: str | None = None,
    forced_temperature: float | None = None,
    cache_ctx: dict[str, str] | None = None,
    agent_id: str = "",
) -> Any:
    msgs = _serialize_messages(payload.messages)
    if extra_system:
        msgs = [{"role": "system", "content": extra_system}, *msgs]
    temperature = payload.temperature if payload.temperature is not None else forced_temperature
    ctx = cache_ctx or {}

    if payload.stream:
        return _streaming_response(msgs, payload, temperature)

    cache_eligible = _is_cache_eligible(payload, temperature)
    if cache_eligible:
        hit = await run_in_threadpool(_prompt_cache.lookup, msgs, ctx, model=payload.model)
        if hit.hit:
            return JSONResponse(
                hit.value,
                headers={
                    "x-cache": hit.tier,
                    "x-cache-scope": hit.scope or "",
                    "x-cache-similarity": f"{hit.similarity:.4f}" if hit.similarity is not None else "",
                },
            )

    t0 = time.perf_counter()
    resp = await _call_model(msgs, payload, temperature)
    _emit_llm_telemetry(resp, model=payload.model, ctx=ctx, agent_id=agent_id, mode="non-streaming", latency_ms=(time.perf_counter() - t0) * 1000)
    if cache_eligible:
        await run_in_threadpool(_prompt_cache.store, msgs, resp, ctx, model=payload.model)
        return JSONResponse(resp, headers={"x-cache": "miss"})
    return JSONResponse(resp)


@app.post(
    "/v1/chat/completions",
    responses={502: {"description": "Azure OpenAI upstream error"}},
)
async def chat_completions(
    payload: ChatCompletionRequest,
    request: Request,
    _: AuthDependency,
) -> Any:
    return await _do_completion(payload, cache_ctx=_cache_ctx_from_headers(request))


@app.post(
    "/v1/agents/{agent_id}/chat",
    responses={
        404: {"description": "Agent was not found"},
        502: {"description": "Azure OpenAI upstream error"},
    },
)
async def agent_chat(
    agent_id: str,
    payload: ChatCompletionRequest,
    request: Request,
    _: AuthDependency,
) -> Any:
    agent = get_agent(agent_id)
    if agent is None:
        raise HTTPException(
            status_code=404,
            detail=f"unknown agent '{agent_id}'. Available: {sorted(AGENTS)}",
        )
    # A2A v1.0 context: continue the inbound chain (or start one), preserve the
    # caller's Entra Agent ID, extend the Purview lineage, log the linked span.
    a2a_ctx = a2a_mod.extract_context(request.headers).enter(agent.id)
    logger.info(
        "a2a hop agent=%s trace=%s chain=%s depth=%d caller=%s",
        agent.id,
        a2a_ctx.trace_id,
        ">".join(a2a_ctx.agent_chain),
        a2a_ctx.depth,
        a2a_ctx.caller_agent_id or "-",
        extra={"otel_attributes": a2a_ctx.otel_span_attributes(), "purview_lineage": a2a_ctx.purview_lineage()},
    )
    response = await _do_completion(
        payload,
        extra_system=agent.system_prompt,
        forced_temperature=agent.suggested_temperature,
        cache_ctx=_cache_ctx_from_headers(request),
        agent_id=agent.id,
    )
    for k, v in a2a_ctx.response_headers().items():
        response.headers[k] = v
    # REQ-PURVIEW-002 / TASK-05-009: also expose the lineage chain under the x-purview-* names.
    for k, v in purview_mod.purview_chain_headers(a2a_ctx).items():
        response.headers[k] = v
    return response


# ───────────────────────── access log ──────────────────
@app.middleware("http")
async def access_log(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start) * 1000
    logger.info(
        "%s %s -> %s in %.1fms",
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response
