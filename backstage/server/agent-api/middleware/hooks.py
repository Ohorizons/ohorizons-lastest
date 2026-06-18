"""Pre/post tool-use governance hooks for the multi-agent runtime.

Every agent (orchestrator, pipeline, sentinel, compass, guardian, lighthouse,
forge) inherits ``BaseAgent`` and runs every tool call through the single
choke point ``BaseAgent._execute_tool``. This module is the governance layer
that wraps that choke point:

- **pre_tool_use** runs *before* a tool executes. It classifies the tool
  (read-only vs mutating: deploy, integration config, infrastructure), blocks
  dangerous argument patterns (path traversal, secret exfiltration, destructive
  shell/IaC/Kubernetes/SQL operations), and records an audit entry.
- **post_tool_use** runs *after* a tool executes. It scans the result for secret
  leakage and redacts it, and truncates oversized payloads before they reach the
  model.

This mirrors the foundry agents-service ``tool_hooks`` so the harness gateway and
the in-cluster agent runtime enforce the same policy. It is deliberately
stdlib-only (no extra dependencies) and safe to import from anywhere in the
agent-api package.

Enforcement is configurable via the ``AGENT_HOOKS_ENFORCE`` environment variable
(default ``true``). When set to ``false``, denials become audited warnings rather
than hard blocks, which is useful for a staged rollout in an existing tenant.
"""

from __future__ import annotations

import logging
import os
import re
import time
from collections import deque
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger("agents.hooks")

# Maximum characters a tool result may return to the model before truncation.
_MAX_RESULT_CHARS = 24_000

# Ring-buffer size for the in-memory hook audit trail (observability endpoint).
_AUDIT_BUFFER = 2_000


class ToolClass(str, Enum):
    """Risk classification for a tool, derived from its name."""

    READ_ONLY = "read_only"
    MUTATING = "mutating"
    UNKNOWN = "unknown"


# ── Tool classification ──────────────────────────────────────────────────────
# Read-only verbs: safe to call without a mutation guard.
_READ_PREFIXES = (
    "get_", "list_", "search_", "read_", "fetch_", "describe_", "lookup_",
    "query_", "find_", "show_", "check_", "analyze_", "scan_", "diff_",
)
_READ_SUFFIXES = ("_search", "_lookup", "_status", "_metrics", "_logs")

# Mutating verbs: create or change state (deployments, integration config, infra).
_MUTATING_PREFIXES = (
    "create_", "update_", "delete_", "remove_", "apply_", "deploy_",
    "merge_", "dispatch_", "trigger_", "put_", "post_", "set_", "patch_",
    "destroy_", "rollback_", "restart_", "scale_", "promote_", "approve_",
    "write_", "push_", "tag_", "release_", "provision_", "configure_",
)

# Explicit overrides where the name heuristic is ambiguous or wrong.
_TOOL_CLASS_OVERRIDES: dict[str, ToolClass] = {
    "github_api": ToolClass.MUTATING,  # can create issues/comments/dispatches
}


def classify_tool(tool_name: str) -> ToolClass:
    """Classify a tool by its name. Mutating wins ties (fail safe)."""
    name = (tool_name or "").lower()
    if name in _TOOL_CLASS_OVERRIDES:
        return _TOOL_CLASS_OVERRIDES[name]
    if any(name.startswith(p) for p in _MUTATING_PREFIXES):
        return ToolClass.MUTATING
    if any(name.startswith(p) for p in _READ_PREFIXES) or any(
        name.endswith(s) for s in _READ_SUFFIXES
    ):
        return ToolClass.READ_ONLY
    return ToolClass.UNKNOWN


# ── Dangerous argument patterns (deny regardless of tool class) ──────────────
# Each entry: (compiled regex, human-readable reason). Matched against the
# stringified argument values, case-insensitive.
_DENY_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\.\./"), "path traversal (../) in arguments"),
    (re.compile(r"\brm\s+-rf?\b", re.I), "destructive shell command (rm -rf)"),
    (re.compile(r"\bgit\s+push\b.*--force\b|--force-with-lease\b", re.I), "force push"),
    (re.compile(r"\bdrop\s+table\b", re.I), "destructive SQL (DROP TABLE)"),
    (re.compile(r"\btruncate\s+table\b", re.I), "destructive SQL (TRUNCATE TABLE)"),
    (re.compile(r"\bdelete\s+from\b(?!.*\bwhere\b)", re.I), "unscoped SQL DELETE"),
    (re.compile(r"\bterraform\s+destroy\b", re.I), "infrastructure destroy (terraform destroy)"),
    (re.compile(r"\bkubectl\s+delete\b.*\b--all\b", re.I), "bulk Kubernetes delete (--all)"),
    (re.compile(r"--no-verify\b", re.I), "bypass of commit/push verification (--no-verify)"),
    (re.compile(r"\bchmod\s+777\b", re.I), "insecure permissions (chmod 777)"),
    (re.compile(r"curl\b[^|]*\|\s*(?:ba)?sh\b", re.I), "pipe-to-shell remote execution"),
    # Secret exfiltration: reading well-known secret material into an argument.
    (re.compile(r"(?:/etc/shadow|/\.ssh/id_|\.aws/credentials|\.kube/config)", re.I),
     "access to sensitive credential files"),
]


# ── Secret patterns (redacted from tool *results*) ───────────────────────────
_SECRET_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"(?i)\b(?:api[_-]?key|secret|token|password|passwd|pwd)\s*[:=]\s*['\"]?([A-Za-z0-9_./+-]{12,})"),
     "credential assignment"),
    (re.compile(r"\bgh[pos]_[A-Za-z0-9]{20,}\b"), "GitHub token"),
    (re.compile(r"\bsk-[A-Za-z0-9]{20,}\b"), "OpenAI-style key"),
    (re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"), "JWT"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"), "private key block"),
    (re.compile(r"(?i)\bAccountKey=[^;]+"), "Azure connection account key"),
]

_REDACTION = "***REDACTED***"


@dataclass
class PreToolUseResult:
    """Outcome of the pre-tool-use hook."""

    allowed: bool
    tool_class: ToolClass
    risk: str  # "low" | "medium" | "high"
    reason: str = ""
    args: dict = field(default_factory=dict)


@dataclass
class PostToolUseResult:
    """Outcome of the post-tool-use hook."""

    result: str
    redactions: int = 0
    truncated: bool = False


@dataclass
class HookAuditEntry:
    """A single recorded hook decision for the observability trail."""

    timestamp: float
    agent: str
    tool: str
    phase: str  # "pre" | "post"
    tool_class: str
    risk: str
    decision: str  # "allow" | "deny" | "warn" | "sanitize"
    reason: str = ""

    def to_dict(self) -> dict:
        return {
            "timestamp": self.timestamp,
            "agent": self.agent,
            "tool": self.tool,
            "phase": self.phase,
            "tool_class": self.tool_class,
            "risk": self.risk,
            "decision": self.decision,
            "reason": self.reason,
        }


def _flatten_args(args: dict) -> str:
    """Stringify argument values for pattern matching."""
    try:
        return " ".join(str(v) for v in args.values())
    except Exception:  # noqa: BLE001 - defensive: never let auditing crash a call
        return str(args)


class ToolHookPipeline:
    """Pre/post tool-use governance for every agent tool call."""

    def __init__(self, enforce: bool | None = None) -> None:
        if enforce is None:
            enforce = os.getenv("AGENT_HOOKS_ENFORCE", "true").lower() != "false"
        self.enforce = enforce
        self._audit: deque[HookAuditEntry] = deque(maxlen=_AUDIT_BUFFER)
        self._counts = {"allow": 0, "deny": 0, "warn": 0, "sanitize": 0}

    # ── pre-tool-use ─────────────────────────────────────────────────────────
    def pre_tool_use(self, agent: str, tool_name: str, args: dict) -> PreToolUseResult:
        """Validate and authorize a tool call before it executes."""
        tool_class = classify_tool(tool_name)
        args = args or {}
        haystack = _flatten_args(args)

        for pattern, reason in _DENY_PATTERNS:
            if pattern.search(haystack):
                decision = "deny" if self.enforce else "warn"
                self._record(agent, tool_name, "pre", tool_class, "high", decision, reason)
                if self.enforce:
                    logger.warning(
                        "Hook BLOCKED %s.%s: %s", agent, tool_name, reason,
                    )
                    return PreToolUseResult(
                        allowed=False, tool_class=tool_class, risk="high",
                        reason=reason, args=args,
                    )
                logger.warning(
                    "Hook WARN (enforce off) %s.%s: %s", agent, tool_name, reason,
                )
                return PreToolUseResult(
                    allowed=True, tool_class=tool_class, risk="high",
                    reason=f"warn: {reason}", args=args,
                )

        # No dangerous pattern. Mutating tools are allowed but audited as medium
        # risk so deployment/integration actions are always on the record.
        risk = "medium" if tool_class is ToolClass.MUTATING else "low"
        self._record(agent, tool_name, "pre", tool_class, risk, "allow")
        return PreToolUseResult(
            allowed=True, tool_class=tool_class, risk=risk, args=args,
        )

    # ── post-tool-use ────────────────────────────────────────────────────────
    def post_tool_use(self, agent: str, tool_name: str, result: str) -> PostToolUseResult:
        """Sanitize a tool result before it is returned to the model."""
        if not isinstance(result, str):
            result = str(result)

        redactions = 0
        for pattern, _label in _SECRET_PATTERNS:
            result, n = pattern.subn(_REDACTION, result)
            redactions += n

        truncated = False
        if len(result) > _MAX_RESULT_CHARS:
            result = result[:_MAX_RESULT_CHARS] + "\n…[truncated by tool hook]"
            truncated = True

        if redactions or truncated:
            reason_parts = []
            if redactions:
                reason_parts.append(f"{redactions} secret(s) redacted")
            if truncated:
                reason_parts.append("result truncated")
            self._record(
                agent, tool_name, "post",
                classify_tool(tool_name), "low", "sanitize",
                ", ".join(reason_parts),
            )

        return PostToolUseResult(result=result, redactions=redactions, truncated=truncated)

    # ── audit + observability ────────────────────────────────────────────────
    def _record(
        self,
        agent: str,
        tool: str,
        phase: str,
        tool_class: ToolClass,
        risk: str,
        decision: str,
        reason: str = "",
    ) -> None:
        self._counts[decision] = self._counts.get(decision, 0) + 1
        self._audit.append(HookAuditEntry(
            timestamp=time.time(),
            agent=agent,
            tool=tool,
            phase=phase,
            tool_class=tool_class.value,
            risk=risk,
            decision=decision,
            reason=reason,
        ))

    def recent(self, limit: int = 100, agent: str | None = None) -> list[dict]:
        """Return the most recent hook decisions (newest first)."""
        items = list(self._audit)
        if agent:
            items = [e for e in items if e.agent == agent]
        items.sort(key=lambda e: e.timestamp, reverse=True)
        return [e.to_dict() for e in items[:limit]]

    def summary(self) -> dict:
        """Aggregate counters for the observability endpoint."""
        return {
            "enforce": self.enforce,
            "counts": dict(self._counts),
            "audit_buffer_used": len(self._audit),
            "audit_buffer_max": _AUDIT_BUFFER,
        }


# Shared singleton used by every agent through BaseAgent._execute_tool.
tool_hooks = ToolHookPipeline()
