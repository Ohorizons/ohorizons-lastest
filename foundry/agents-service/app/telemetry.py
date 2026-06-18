"""Foundry-agents gateway runtime telemetry — the 21-field LLM-call schema (REQ-FINOPS-001).

Mirrors ``new-features/foundry/lightspeed-shim/app/telemetry.py`` so Foundry traffic lands in
the *same* Application Insights workspace as the Lightspeed shim's ``llm.call.completed`` events
(and the Copilot Metrics ingest's ``copilot.*`` events) — see ``docs/finops/metrics.md`` and the
Q1/Q2/Q8 KQL in ``docs/finops/kql-queries.md``. Emission is gated by
``APPLICATIONINSIGHTS_CONNECTION_STRING``; without it the helper is a no-op (returns ``False``).
"""
from __future__ import annotations

import datetime as _dt
import os
import uuid
from typing import Any, Mapping

LLM_CALL_FIELDS = (
    "timestamp", "request_id", "session_id", "user_id", "team_id", "feature_id",
    "model_provider", "model_name", "mode",
    "tokens_input", "tokens_output", "tokens_cached_read", "tokens_cached_write_5m", "tokens_cached_write_1h",
    "latency_ttft_ms", "latency_total_ms", "outcome", "cost_usd", "ai_credits_consumed",
    "tool_calls_count", "tool_results_total_tokens",
)
NUMERIC_FIELDS = {
    "tokens_input", "tokens_output", "tokens_cached_read", "tokens_cached_write_5m", "tokens_cached_write_1h",
    "latency_ttft_ms", "latency_total_ms", "cost_usd", "ai_credits_consumed",
    "tool_calls_count", "tool_results_total_tokens",
}
_MODEL_TIER_BY_PREFIX = {
    "gpt-4o-mini": "CHEAP", "gpt-4.1-mini": "CHEAP", "gpt-4o": "WORKHORSE", "gpt-4.1": "WORKHORSE",
    "gpt-5": "PREMIUM", "o1": "PREMIUM", "o3": "PREMIUM",
    "claude-haiku": "CHEAP", "claude-sonnet": "WORKHORSE", "claude-opus": "PREMIUM",
    "gemini": "LONG_CTX", "text-embedding": "BUNDLED",
}
# Azure OpenAI list-price heuristic (USD per 1K tokens) — matches the cost dashboard's rate.
_RATE_PER_1K = {"input": 0.00001 * 1000, "output": 0.00003 * 1000}


def infer_model_tier(model_name: str) -> str:
    m = (model_name or "").lower()
    for prefix, tier in _MODEL_TIER_BY_PREFIX.items():
        if m.startswith(prefix):
            return tier
    return "WORKHORSE"


def estimate_cost_usd(tokens_input: int, tokens_output: int) -> float:
    return round((tokens_input / 1000.0) * _RATE_PER_1K["input"] + (tokens_output / 1000.0) * _RATE_PER_1K["output"], 6)


def build_llm_call_attributes(
    usage: Mapping[str, Any],
    *,
    request_id: str | None = None,
    session_id: str = "",
    user_id: str = "",
    team_id: str = "",
    feature_id: str = "foundry-agents",
    model_name: str = "",
    model_provider: str = "azure-openai",
    mode: str = "non-streaming",
    latency_total_ms: float = 0.0,
    latency_ttft_ms: float = 0.0,
    outcome: str = "success",
    tool_calls_count: int = 0,
    tool_results_total_tokens: int = 0,
) -> dict[str, Any]:
    tin = int(usage.get("prompt_tokens", usage.get("input_tokens", 0)) or 0)
    tout = int(usage.get("completion_tokens", usage.get("output_tokens", 0)) or 0)
    details = usage.get("prompt_tokens_details") or {}
    cached_read = int(details.get("cached_tokens", usage.get("cached_read_tokens", 0)) or 0)
    attrs: dict[str, Any] = {
        "timestamp": _dt.datetime.now(_dt.timezone.utc).isoformat(),
        "request_id": request_id or uuid.uuid4().hex,
        "session_id": session_id,
        "user_id": user_id,
        "team_id": team_id,
        "feature_id": feature_id,
        "model_provider": model_provider,
        "model_name": model_name or "unknown",
        "mode": mode,
        "tokens_input": tin,
        "tokens_output": tout,
        "tokens_cached_read": cached_read,
        "tokens_cached_write_5m": 0,
        "tokens_cached_write_1h": 0,
        "latency_ttft_ms": float(latency_ttft_ms),
        "latency_total_ms": float(latency_total_ms),
        "outcome": outcome,
        "cost_usd": estimate_cost_usd(tin, tout),
        "ai_credits_consumed": 0,  # Foundry uses Azure spend, not Copilot AI Credits
        "tool_calls_count": int(tool_calls_count),
        "tool_results_total_tokens": int(tool_results_total_tokens),
    }
    # carry the tier as an extra (not one of the 21, but useful for the dashboards)
    attrs["model_tier"] = infer_model_tier(attrs["model_name"])
    return attrs


def validate_llm_call_attributes(attributes: Mapping[str, Any]) -> None:
    missing = [f for f in LLM_CALL_FIELDS if f not in attributes]
    if missing:
        raise ValueError(f"missing LLM telemetry fields: {', '.join(missing)}")


# ── App Insights emission (same wire format as the lightspeed shim) ──────────
def parse_connection_string(connection_string: str) -> dict[str, str]:
    parts: dict[str, str] = {}
    for item in connection_string.split(";"):
        if not item.strip() or "=" not in item:
            continue
        k, v = item.split("=", 1)
        parts[k.strip().lower()] = v.strip()
    return parts


def _track_endpoint(cs: str) -> str:
    return parse_connection_string(cs).get("ingestionendpoint", "https://dc.services.visualstudio.com").rstrip("/") + "/v2/track"


def _instrumentation_key(cs: str) -> str:
    key = parse_connection_string(cs).get("instrumentationkey")
    if not key:
        raise ValueError("Application Insights connection string missing InstrumentationKey")
    return key


def build_event_envelope(attributes: Mapping[str, Any], *, instrumentation_key: str) -> dict[str, Any]:
    validate_llm_call_attributes(attributes)
    props = {k: str(v) for k, v in attributes.items()}
    meas = {k: float(attributes[k]) for k in NUMERIC_FIELDS if k in attributes}
    return {
        "name": "Microsoft.ApplicationInsights.Event",
        "time": str(attributes["timestamp"]),
        "iKey": instrumentation_key,
        "tags": {"ai.cloud.role": "foundry-agents", "ai.operation.id": str(attributes["request_id"]), "ai.user.id": str(attributes["user_id"])},
        "data": {"baseType": "EventData", "baseData": {"ver": 2, "name": "llm.call.completed", "id": uuid.uuid4().hex, "properties": props, "measurements": meas}},
    }


def emit_llm_call_completed(attributes: Mapping[str, Any], *, connection_string: str | None = None, client: Any = None) -> bool:
    cs = connection_string or os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING", "")
    if not cs:
        return False
    envelope = build_event_envelope(attributes, instrumentation_key=_instrumentation_key(cs))
    if client is None:  # lazy httpx import (already an agents-service dep)
        import httpx  # type: ignore

        client = httpx
    resp = client.post(_track_endpoint(cs), json=envelope, timeout=5.0)
    resp.raise_for_status()
    try:
        result = resp.json()
    except ValueError:
        return True
    if int(result.get("itemsAccepted", 0)) < 1:
        raise RuntimeError(f"App Insights ingestion rejected llm.call.completed: {result}")
    return True
