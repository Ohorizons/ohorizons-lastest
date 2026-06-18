"""Agent-to-Agent (A2A v1.0) context propagation (REQ-A2A-001).

Each A2A hop must: (a) propagate a ``trace_id`` for end-to-end observability,
(b) preserve the caller's Entra Agent ID identity at the callee, (c) carry the Purview
lineage chain (REQ-PURVIEW-002 — depth, agent identity at each step, transformation,
final consumer), and (d) emit an OTel span linking caller↔callee.

This module gives the gateway the wire format (HTTP headers) + the in-process context
object + helpers to extract it from an inbound request, propagate it to an outbound A2A
call, and render OTel span attributes. The actual span export rides the existing
Application Insights / Azure Monitor OTLP pipeline (see ``lightspeed-shim/app/telemetry.py``).
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from typing import Any, Mapping

# Header names (lower-case; FastAPI/Starlette normalizes). `traceparent` is the W3C
# Trace Context header; the rest are the A2A-specific extensions.
H_TRACEPARENT = "traceparent"
H_TRACE_ID = "x-a2a-trace-id"
H_CALLER_AGENT = "x-a2a-caller-agent"
H_CHAIN = "x-a2a-chain"
H_LINEAGE = "x-a2a-lineage"
H_PROTOCOL = "x-a2a-protocol"
A2A_PROTOCOL_VERSION = "a2a/1.0"


def new_trace_id() -> str:
    """A 32-hex-char trace id (W3C trace-id shape)."""
    return uuid.uuid4().hex


def _trace_id_from_traceparent(traceparent: str | None) -> str | None:
    # traceparent = "<version>-<trace-id>-<parent-id>-<flags>"
    if not traceparent:
        return None
    parts = traceparent.split("-")
    if len(parts) >= 3 and len(parts[1]) == 32 and parts[1] != "0" * 32:
        return parts[1]
    return None


@dataclass
class LineageStep:
    agent_id: str
    transformation: str = "passthrough"

    def to_str(self) -> str:
        return f"{self.agent_id}:{self.transformation}"

    @classmethod
    def parse(cls, token: str) -> "LineageStep":
        agent, _, transform = token.partition(":")
        return cls(agent_id=agent or "unknown", transformation=transform or "passthrough")


@dataclass
class A2AContext:
    trace_id: str
    caller_agent_id: str | None = None
    agent_chain: list[str] = field(default_factory=list)
    lineage: list[LineageStep] = field(default_factory=list)
    protocol: str = A2A_PROTOCOL_VERSION

    @property
    def depth(self) -> int:
        return len(self.agent_chain)

    @property
    def final_consumer(self) -> str | None:
        return self.agent_chain[-1] if self.agent_chain else None

    # ── enter a hop: the gateway is now serving `agent_id` ──
    def enter(self, agent_id: str, *, transformation: str = "passthrough") -> "A2AContext":
        self.agent_chain.append(agent_id)
        self.lineage.append(LineageStep(agent_id=agent_id, transformation=transformation))
        return self

    # ── outbound headers for the next A2A call ──
    def outbound_headers(self) -> dict[str, str]:
        """Headers for an outbound A2A call. The callee `.enter()`s its own id on receipt
        (W3C-style propagation: the sender carries its context, the receiver appends itself)."""
        return {
            H_TRACEPARENT: f"00-{self.trace_id}-{uuid.uuid4().hex[:16]}-01",
            H_TRACE_ID: self.trace_id,
            H_CALLER_AGENT: self.final_consumer or self.caller_agent_id or "",
            H_CHAIN: ">".join(self.agent_chain),
            H_LINEAGE: ">".join(s.to_str() for s in self.lineage),
            H_PROTOCOL: self.protocol,
        }

    # ── OTel span attributes (REQ-A2A-001 (d)) ──
    def otel_span_attributes(self, *, span_kind: str = "internal") -> dict[str, Any]:
        return {
            "a2a.protocol": self.protocol,
            "a2a.trace_id": self.trace_id,
            "a2a.caller_agent_id": self.caller_agent_id or "",
            "a2a.chain": ">".join(self.agent_chain),
            "a2a.depth": self.depth,
            "a2a.final_consumer": self.final_consumer or "",
            "a2a.lineage": ">".join(s.to_str() for s in self.lineage),
            "span.kind": span_kind,
        }

    # ── Purview lineage payload (REQ-PURVIEW-002) ──
    def purview_lineage(self) -> dict[str, Any]:
        return {
            "trace_id": self.trace_id,
            "depth": self.depth,
            "steps": [
                {"position": i, "agent_id": s.agent_id, "transformation": s.transformation}
                for i, s in enumerate(self.lineage)
            ],
            "final_consumer": self.final_consumer,
        }

    def response_headers(self) -> dict[str, str]:
        return {
            H_TRACE_ID: self.trace_id,
            H_CHAIN: ">".join(self.agent_chain),
            H_PROTOCOL: self.protocol,
        }


def extract_context(headers: Mapping[str, str]) -> A2AContext:
    """Build an :class:`A2AContext` from an inbound request's headers (case-insensitive)."""
    h = {k.lower(): v for k, v in headers.items()}
    trace_id = (
        _trace_id_from_traceparent(h.get(H_TRACEPARENT))
        or (h.get(H_TRACE_ID) or "").strip()
        or new_trace_id()
    )
    chain_raw = (h.get(H_CHAIN) or "").strip()
    chain = [c for c in chain_raw.split(">") if c] if chain_raw else []
    lineage_raw = (h.get(H_LINEAGE) or "").strip()
    lineage = [LineageStep.parse(t) for t in lineage_raw.split(">") if t] if lineage_raw else []
    caller = (h.get(H_CALLER_AGENT) or "").strip() or (chain[-1] if chain else None)
    protocol = (h.get(H_PROTOCOL) or "").strip() or A2A_PROTOCOL_VERSION
    return A2AContext(
        trace_id=trace_id,
        caller_agent_id=caller,
        agent_chain=chain,
        lineage=lineage,
        protocol=protocol,
    )
