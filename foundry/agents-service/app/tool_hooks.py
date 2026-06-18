"""MCP tool ``preToolUse`` / ``postToolUse`` hooks (REQ-HOOK-001, REQ-HOOK-002).

Implemented once at the Foundry Toolbox layer (rather than per individual MCP server),
since the Toolbox is the single endpoint every IDE/agent calls through.

* :func:`pre_tool_use`  — cache lookup (skip the call on hit), cost gate (block when the
  session budget is exhausted), argument validation (deny ``/etc/``, ``~``, ``..`` and
  other unsafe path tokens), audit-log entry.
* :func:`post_tool_use` — cache write (when the result is cacheable), large-result
  truncation (>5K-token estimate), secret/PII redaction, cost-tracking emit.

All helpers are pure / stdlib-only; the cache + approval policy come in as objects so this
module has no hard dependency on Redis or the manifest internals.
"""
from __future__ import annotations

import datetime as _dt
import re
from dataclasses import dataclass, field
from typing import Any, Mapping

# token estimate ≈ chars / 4 (good enough for the 5K-token truncation gate)
_LARGE_RESULT_TOKEN_LIMIT = 5000
_CHARS_PER_TOKEN = 4
_LARGE_RESULT_CHAR_LIMIT = _LARGE_RESULT_TOKEN_LIMIT * _CHARS_PER_TOKEN

# Unsafe path / argument tokens (REQ-HOOK-001 (c)). Conservative denylist applied to any
# string argument value.
_UNSAFE_PATH_PATTERNS = (
    re.compile(r"(^|[\s\"'=:])/etc/"),
    re.compile(r"(^|[\s\"'=:])/root/"),
    re.compile(r"(^|[\s\"'=:])/var/run/"),
    re.compile(r"(^|[\s\"'=:])/proc/"),
    re.compile(r"(^|[\s\"'=:])/sys/"),
    re.compile(r"~(/|$)"),          # home expansion
    re.compile(r"(^|[/\\])\.\.([/\\]|$)"),  # parent traversal
    re.compile(r"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"),  # env-var interpolation in a path arg
)

# Secret / PII redaction (REQ-HOOK-002 (c)). Regex + small denylist of key-ish field names.
_SECRET_PATTERNS = [
    (re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"), "<redacted-email>"),
    (re.compile(r"\bgh[pousr]_[A-Za-z0-9]{16,}\b"), "<redacted-github-token>"),
    (re.compile(r"\bsk-[A-Za-z0-9]{16,}\b"), "<redacted-api-key>"),
    (re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b"), "<redacted-slack-token>"),
    (re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"), "<redacted-jwt>"),
    (re.compile(r"(?i)\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"), "<redacted-aws-key>"),
    (re.compile(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b(?=.{0,40}(secret|key|token|password))",), "<redacted-secret-guid>"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----"), "<redacted-private-key>"),
]
_SENSITIVE_KEY_RE = re.compile(r"(?i)(password|passwd|secret|api[_-]?key|access[_-]?key|client[_-]?secret|token|bearer|connection[_-]?string|sas[_-]?token)")


# ── pre-tool-use ────────────────────────────────────────────────────────────
@dataclass
class PreToolUseResult:
    ok: bool                       # False ⇒ blocked
    blocked_reason: str | None = None
    cache_hit: bool = False
    cache_tier: str | None = None
    cache_value: Any = None
    validated_args: dict[str, Any] = field(default_factory=dict)
    audit: dict[str, Any] = field(default_factory=dict)


def _validate_args(args: Mapping[str, Any]) -> tuple[bool, str | None, dict[str, Any]]:
    """Reject obviously-dangerous string args; return ``(ok, reason, args_copy)``."""
    out = dict(args)
    for k, v in args.items():
        if isinstance(v, str):
            for pat in _UNSAFE_PATH_PATTERNS:
                if pat.search(v):
                    return False, f"argument '{k}' contains an unsafe path/interpolation token: {pat.pattern}", out
        elif isinstance(v, (list, tuple)):
            for item in v:
                if isinstance(item, str):
                    for pat in _UNSAFE_PATH_PATTERNS:
                        if pat.search(item):
                            return False, f"argument '{k}[]' contains an unsafe token: {pat.pattern}", out
    return True, None, out


def pre_tool_use(
    tool_name: str,
    args: Mapping[str, Any],
    ctx: Mapping[str, Any],
    *,
    require_approval: str = "never",
    approved: bool = False,
    write: bool = False,
    cache_lookup: "Any | None" = None,   # callable(tool_name, args, ctx) -> (tier, value) | None
    budget_remaining_usd: float | None = None,
) -> PreToolUseResult:
    """REQ-HOOK-001: cache → cost gate → arg validation → audit, in that order."""
    now = _dt.datetime.now(_dt.timezone.utc).isoformat()
    audit = {
        "event": "tool.pre_use",
        "ts": now,
        "tool": tool_name,
        "user_id": ctx.get("user_id", ""),
        "session_id": ctx.get("session_id", ""),
        "tenant_id": ctx.get("tenant_id", ""),
        "write": write,
        "require_approval": require_approval,
    }
    # (a) cache lookup — skip the call entirely on hit
    if cache_lookup is not None:
        try:
            hit = cache_lookup(tool_name, args, ctx)
        except Exception:  # noqa: BLE001 - a flaky cache must never block a tool call
            hit = None
        if hit is not None:
            tier, value = hit
            audit["outcome"] = "cache_hit"
            audit["cache_tier"] = tier
            return PreToolUseResult(ok=True, cache_hit=True, cache_tier=tier, cache_value=value, validated_args=dict(args), audit=audit)
    # (b) cost gate
    if budget_remaining_usd is not None and budget_remaining_usd <= 0:
        audit["outcome"] = "blocked_budget"
        return PreToolUseResult(ok=False, blocked_reason="session token budget exhausted", validated_args=dict(args), audit=audit)
    # (b') approval gate (write/shell tools)
    if require_approval == "always" and not approved:
        audit["outcome"] = "blocked_approval"
        return PreToolUseResult(ok=False, blocked_reason="tool requires approval (require_approval=always)", validated_args=dict(args), audit=audit)
    if require_approval == "read_only" and write and not approved:
        audit["outcome"] = "blocked_approval"
        return PreToolUseResult(ok=False, blocked_reason="write call on a read_only tool requires approval", validated_args=dict(args), audit=audit)
    # (c) argument validation
    ok, reason, validated = _validate_args(args)
    if not ok:
        audit["outcome"] = "blocked_unsafe_args"
        audit["reason"] = reason
        return PreToolUseResult(ok=False, blocked_reason=reason, validated_args=validated, audit=audit)
    # (d) audit log entry (the caller ships it; we just stamp the outcome)
    audit["outcome"] = "allowed"
    return PreToolUseResult(ok=True, validated_args=validated, audit=audit)


# ── post-tool-use ───────────────────────────────────────────────────────────
@dataclass
class PostToolUseResult:
    result: Any
    truncated: bool = False
    redacted: bool = False
    cached: bool = False
    estimated_tokens: int = 0
    cost_record: dict[str, Any] = field(default_factory=dict)
    audit: dict[str, Any] = field(default_factory=dict)


def _estimate_tokens(text: str) -> int:
    return (len(text) + _CHARS_PER_TOKEN - 1) // _CHARS_PER_TOKEN


def _redact_str(s: str) -> tuple[str, bool]:
    out = s
    changed = False
    for pat, repl in _SECRET_PATTERNS:
        new = pat.sub(repl, out)
        if new != out:
            changed = True
            out = new
    return out, changed


def redact(value: Any) -> tuple[Any, bool]:
    """Recursively redact secrets/PII from strings, lists, and dicts (sensitive keys → masked)."""
    if isinstance(value, str):
        return _redact_str(value)
    if isinstance(value, list):
        changed = False
        out_list = []
        for item in value:
            red, c = redact(item)
            changed = changed or c
            out_list.append(red)
        return out_list, changed
    if isinstance(value, dict):
        changed = False
        out_dict: dict[Any, Any] = {}
        for k, v in value.items():
            if isinstance(k, str) and _SENSITIVE_KEY_RE.search(k) and isinstance(v, (str, int, float)):
                out_dict[k] = "<redacted>"
                changed = True
            else:
                red, c = redact(v)
                changed = changed or c
                out_dict[k] = red
        return out_dict, changed
    return value, False


def _truncate(value: Any) -> tuple[Any, bool, int]:
    text = value if isinstance(value, str) else str(value)
    est = _estimate_tokens(text)
    if est <= _LARGE_RESULT_TOKEN_LIMIT:
        return value, False, est
    head = text[: _LARGE_RESULT_CHAR_LIMIT - 80]
    truncated = head + f"\n…[truncated: {est} est. tokens > {_LARGE_RESULT_TOKEN_LIMIT}; {len(text) - len(head)} chars dropped]"
    return truncated, True, _estimate_tokens(truncated)


def post_tool_use(
    tool_name: str,
    result: Any,
    ctx: Mapping[str, Any],
    *,
    cacheable: bool = True,
    cache_store: "Any | None" = None,   # callable(tool_name, args_or_key, result, ctx) -> None
    cache_key: Any = None,
    estimated_cost_usd: float = 0.0,
) -> PostToolUseResult:
    """REQ-HOOK-002: redact → truncate → cache write → cost emit."""
    now = _dt.datetime.now(_dt.timezone.utc).isoformat()
    redacted_result, redacted = redact(result)
    final_result, truncated, est_tokens = _truncate(redacted_result)
    cached = False
    if cacheable and not truncated and cache_store is not None:
        try:
            cache_store(tool_name, cache_key, final_result, ctx)
            cached = True
        except Exception:  # noqa: BLE001
            cached = False
    cost_record = {
        "event": "tool.cost",
        "ts": now,
        "tool": tool_name,
        "user_id": ctx.get("user_id", ""),
        "tenant_id": ctx.get("tenant_id", ""),
        "estimated_tokens": est_tokens,
        "estimated_cost_usd": round(estimated_cost_usd, 6),
    }
    audit = {
        "event": "tool.post_use",
        "ts": now,
        "tool": tool_name,
        "redacted": redacted,
        "truncated": truncated,
        "cached": cached,
        "estimated_tokens": est_tokens,
    }
    return PostToolUseResult(
        result=final_result,
        truncated=truncated,
        redacted=redacted,
        cached=cached,
        estimated_tokens=est_tokens,
        cost_record=cost_record,
        audit=audit,
    )
