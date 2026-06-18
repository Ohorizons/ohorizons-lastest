"""Microsoft Purview agentic audit + data lineage (REQ-PURVIEW-001, REQ-PURVIEW-002).

REQ-PURVIEW-001: whenever an agent (Foundry agent / Copilot agent / MCP-invoked tool) accesses
data classified ``sensitive`` / ``pii`` / ``lgpd-protected`` / ``bacen-restricted`` /
``aneel-restricted``, emit an audit event carrying ``agent_id``, ``model_id``, ``user_id`` (or
service principal), ``data_source``, ``data_classification``, ``access_type`` (read/write/delete),
``purpose``, ``timestamp``, ``session_id``, ``trace_id`` (correlates with Application Insights).

REQ-PURVIEW-002: propagate lineage through agent chains — depth, agent identity at each step,
transformation applied, final consumer (the payload :meth:`a2a.A2AContext.purview_lineage`
already produces). TASK-05-009 wants the chain on the wire as ``x-purview-chain`` /
``x-trace-id`` / ``x-caller-agent`` headers — :func:`purview_chain_headers` derives those from
an A2A context (aliasing the ``x-a2a-*`` headers).

Emission target: a Log Analytics / Purview audit ingestion endpoint (Purview surfaces it in the
LGPD audit dashboard). Best-effort — without ``PURVIEW_AUDIT_INGEST_URL`` (or an explicit
endpoint) the emitter is a no-op, so the gateway runs fine without it; emission never raises.
"""
from __future__ import annotations

import datetime as _dt
import os
import uuid
from typing import Any, Mapping

# Data classifications that trigger an audit event (REQ-PURVIEW-001 / COSMOS data tags).
SENSITIVE = "sensitive"
PII = "pii"
LGPD_PROTECTED = "lgpd-protected"
BACEN_RESTRICTED = "bacen-restricted"
ANEEL_RESTRICTED = "aneel-restricted"
AUDITED_CLASSIFICATIONS = frozenset({SENSITIVE, PII, LGPD_PROTECTED, BACEN_RESTRICTED, ANEEL_RESTRICTED})

# access_type values
ACCESS_READ = "read"
ACCESS_WRITE = "write"
ACCESS_DELETE = "delete"
_ACCESS_TYPES = frozenset({ACCESS_READ, ACCESS_WRITE, ACCESS_DELETE})

AUDIT_EVENT_NAME = "purview.agent.data_access"

# REQ-PURVIEW-001 mandatory fields
AUDIT_FIELDS = (
    "agent_id", "model_id", "user_id", "data_source", "data_classification",
    "access_type", "purpose", "timestamp", "session_id", "trace_id",
)


def is_classified(classification: str | None) -> bool:
    """True when the classification is one that must be audited (REQ-PURVIEW-001)."""
    return bool(classification) and str(classification).strip().lower() in AUDITED_CLASSIFICATIONS


def build_audit_event(
    *,
    agent_id: str,
    model_id: str,
    user_id: str,
    data_source: str,
    data_classification: str,
    access_type: str,
    purpose: str,
    session_id: str = "",
    trace_id: str | None = None,
    lineage: Mapping[str, Any] | None = None,
    extra: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    """Build a REQ-PURVIEW-001 audit event (+ REQ-PURVIEW-002 lineage chain when supplied)."""
    at = str(access_type).strip().lower()
    if at not in _ACCESS_TYPES:
        raise ValueError(f"access_type must be one of {sorted(_ACCESS_TYPES)}, got {access_type!r}")
    cls = str(data_classification).strip().lower()
    event: dict[str, Any] = {
        "event": AUDIT_EVENT_NAME,
        "agent_id": agent_id or "unknown",
        "model_id": model_id or "unknown",
        "user_id": user_id or "",
        "data_source": data_source or "unknown",
        "data_classification": cls,
        "access_type": at,
        "purpose": purpose or "unspecified",
        "timestamp": _dt.datetime.now(_dt.timezone.utc).isoformat(),
        "session_id": session_id,
        "trace_id": trace_id or uuid.uuid4().hex,
        "is_classified": is_classified(cls),
    }
    if lineage:
        event["lineage"] = dict(lineage)  # depth / steps[] / final_consumer (REQ-PURVIEW-002)
    if extra:
        for k, v in extra.items():
            event.setdefault(k, v)
    return event


def validate_audit_event(event: Mapping[str, Any]) -> None:
    missing = [f for f in AUDIT_FIELDS if f not in event]
    if missing:
        raise ValueError(f"purview audit event missing fields: {', '.join(missing)}")


# ── lineage headers on the wire (TASK-05-009) ───────────────────────────────
def purview_chain_headers(a2a_ctx: Any) -> dict[str, str]:
    """``x-purview-chain`` / ``x-trace-id`` / ``x-caller-agent`` from an :class:`a2a.A2AContext`.

    These are the names TASK-05-009 calls for; the ``x-a2a-*`` headers carry the same data —
    this is the alias view auditors / downstream Purview tooling expect.
    """
    if a2a_ctx is None:
        return {}
    chain = ">".join(getattr(a2a_ctx, "agent_chain", []) or [])
    lineage = getattr(a2a_ctx, "lineage", []) or []
    return {
        "x-purview-chain": ">".join(
            (f"{s.agent_id}:{s.transformation}" if hasattr(s, "agent_id") else str(s)) for s in lineage
        ) or chain,
        "x-trace-id": str(getattr(a2a_ctx, "trace_id", "")),
        "x-caller-agent": str(getattr(a2a_ctx, "caller_agent_id", "") or (chain.rsplit(">", 1)[-1] if chain else "")),
    }


# ── emission ────────────────────────────────────────────────────────────────
def _resolve_endpoint(endpoint: str | None) -> str | None:
    return endpoint or os.environ.get("PURVIEW_AUDIT_INGEST_URL") or os.environ.get("PURVIEW_AUDIT_ENDPOINT") or None


def emit_data_access_event(
    event: Mapping[str, Any],
    *,
    ingestion_endpoint: str | None = None,
    headers: Mapping[str, str] | None = None,
    client: Any = None,
) -> bool:
    """POST the audit event to the Purview / Log Analytics audit ingestion endpoint.

    Returns ``True`` on a 2xx; ``False`` when no endpoint is configured (no-op). Never raises —
    audit emission must not break a data access. Validates the event first.
    """
    url = _resolve_endpoint(ingestion_endpoint)
    if not url:
        return False
    try:
        validate_audit_event(event)
        if client is None:
            import httpx  # type: ignore

            client = httpx
        resp = client.post(url, json=dict(event), headers=dict(headers or {"Content-Type": "application/json"}), timeout=5.0)
        status = getattr(resp, "status_code", 200)
        return 200 <= int(status) < 300
    except Exception:  # noqa: BLE001 - best-effort; the caller logs at debug
        return False


def audit_classified_access(
    *,
    agent_id: str,
    model_id: str,
    user_id: str,
    data_source: str,
    data_classification: str,
    access_type: str,
    purpose: str,
    session_id: str = "",
    trace_id: str | None = None,
    lineage: Mapping[str, Any] | None = None,
    ingestion_endpoint: str | None = None,
    client: Any = None,
) -> dict[str, Any] | None:
    """Build + emit an audit event **iff** the classification is one that must be audited.

    Returns the event (always built when classified, for the caller to also log via App
    Insights with the matching ``trace_id``); ``None`` when the classification is not audited.
    """
    if not is_classified(data_classification):
        return None
    event = build_audit_event(
        agent_id=agent_id, model_id=model_id, user_id=user_id, data_source=data_source,
        data_classification=data_classification, access_type=access_type, purpose=purpose,
        session_id=session_id, trace_id=trace_id, lineage=lineage,
    )
    emit_data_access_event(event, ingestion_endpoint=ingestion_endpoint, client=client)
    return event
