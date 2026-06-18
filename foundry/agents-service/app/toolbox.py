"""Foundry Toolbox manifest — single MCP-compatible tool catalog (REQ-TOOLBOX-001..004).

The production Toolbox is an Azure AI Foundry **preview** capability deployed against a
Foundry workspace; this module is the application-side, GA-only counterpart that the
foundry-agents gateway exposes (and the documented fallback per REQ-FALLBACK-001): it
aggregates, into one ``list_tools`` surface, four tool categories —

  * ``mcp``      — every non-subsumed MCP server from ``mcp-servers/mcp-config.json``
  * ``builtin``  — the four Foundry built-in tools (Web Search, Code Interpreter,
                   File Search, Azure AI Search)
  * ``openapi``  — OpenAPI-described tool wrappers (config-driven; empty by default)
  * ``a2a``      — Agent-to-Agent connections (the specialized agents in ``agents.py``)

Every tool carries a ``require_approval`` policy ∈ {``never``, ``read_only``, ``always``}
(REQ-TOOLBOX-003 — read tools never, write tools always, bash/shell always) and every
downstream MCP server declares an ``auth`` mode ∈ {``managed_identity``,
``oauth_passthrough``, ``key``, ``local``} (REQ-TOOLBOX-004 — MI preferred; OAuth
identity passthrough for user-context tools; key-based only for non-Entra-aware servers,
with a documented rotation owner).
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# ── policy defaults ─────────────────────────────────────────────────────────
APPROVAL_NEVER = "never"
APPROVAL_READ_ONLY = "read_only"
APPROVAL_ALWAYS = "always"
_APPROVAL_LEVELS = (APPROVAL_NEVER, APPROVAL_READ_ONLY, APPROVAL_ALWAYS)

AUTH_MANAGED_IDENTITY = "managed_identity"
AUTH_OAUTH_PASSTHROUGH = "oauth_passthrough"
AUTH_KEY = "key"
AUTH_LOCAL = "local"
_AUTH_MODES = (AUTH_MANAGED_IDENTITY, AUTH_OAUTH_PASSTHROUGH, AUTH_KEY, AUTH_LOCAL)

# Per-MCP-server posture. `require_approval` is the conservative server-level default
# (individual tool calls a Toolbox client surfaces will still honour their own marker if
# the server advertises one); `auth` follows REQ-TOOLBOX-004; `key_rotation_owner` is
# mandatory metadata for any `key`-auth server.
_MCP_SERVER_POSTURE: dict[str, dict[str, str]] = {
    "azure":       {"require_approval": APPROVAL_ALWAYS,    "auth": AUTH_MANAGED_IDENTITY},
    "aks":         {"require_approval": APPROVAL_ALWAYS,    "auth": AUTH_MANAGED_IDENTITY},
    "foundry":     {"require_approval": APPROVAL_READ_ONLY, "auth": AUTH_MANAGED_IDENTITY},
    "backstage":   {"require_approval": APPROVAL_READ_ONLY, "auth": AUTH_MANAGED_IDENTITY},
    "github":      {"require_approval": APPROVAL_ALWAYS,    "auth": AUTH_OAUTH_PASSTHROUGH},
    "figma":       {"require_approval": APPROVAL_READ_ONLY, "auth": AUTH_OAUTH_PASSTHROUGH},
    "terraform":   {"require_approval": APPROVAL_ALWAYS,    "auth": AUTH_KEY, "key_rotation_owner": "platform-eng"},
    "playwright":  {"require_approval": APPROVAL_READ_ONLY, "auth": AUTH_LOCAL},
    "devbox":      {"require_approval": APPROVAL_ALWAYS,    "auth": AUTH_OAUTH_PASSTHROUGH},
    "filesystem":  {"require_approval": APPROVAL_ALWAYS,    "auth": AUTH_LOCAL},
    "git":         {"require_approval": APPROVAL_ALWAYS,    "auth": AUTH_LOCAL},
}
_DEFAULT_MCP_POSTURE = {"require_approval": APPROVAL_READ_ONLY, "auth": AUTH_LOCAL}

# The four Foundry built-in tools (Row 2 of the validated diagram). Web/File/AI-Search
# are read-only retrieval; Code Interpreter executes code → always-approve.
_BUILTIN_TOOLS: list[dict[str, str]] = [
    {"name": "web_search", "require_approval": APPROVAL_NEVER, "description": "Foundry built-in web search (Bing-grounded)"},
    {"name": "file_search", "require_approval": APPROVAL_NEVER, "description": "Foundry built-in file/vector search over uploaded documents"},
    {"name": "azure_ai_search", "require_approval": APPROVAL_NEVER, "description": "Foundry built-in Azure AI Search retrieval tool"},
    {"name": "code_interpreter", "require_approval": APPROVAL_ALWAYS, "description": "Foundry built-in sandboxed Python code interpreter"},
]


def _repo_root() -> Path:
    # this file: <repo>/new-features/foundry/agents-service/app/toolbox.py
    return Path(__file__).resolve().parents[4]


def _mcp_config_path() -> Path:
    override = os.environ.get("MCP_CONFIG_PATH")
    if override:
        return Path(override)
    return _repo_root() / "mcp-servers" / "mcp-config.json"


def _is_subsumed(entry: dict[str, Any]) -> bool:
    return bool(
        entry.get("subsumed_by_native_tool")
        or entry.get("subsumed_by")
        or entry.get("native")
        or entry.get("azure_native")
        or entry.get("aks_native")
    )


def load_mcp_servers(config_path: str | os.PathLike[str] | None = None) -> dict[str, dict[str, Any]]:
    """Return the non-subsumed MCP servers from ``mcp-config.json`` keyed by name."""
    path = Path(config_path) if config_path is not None else _mcp_config_path()
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    servers = raw.get("mcpServers") or raw.get(".mcpServers") or raw
    return {name: entry for name, entry in servers.items() if isinstance(entry, dict) and not _is_subsumed(entry)}


@dataclass(frozen=True)
class ToolboxTool:
    name: str
    category: str  # mcp | builtin | openapi | a2a
    require_approval: str
    description: str = ""
    endpoint: str | None = None
    auth: str | None = None
    extra: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.require_approval not in _APPROVAL_LEVELS:
            raise ValueError(f"invalid require_approval {self.require_approval!r} for tool {self.name!r}")
        if self.auth is not None and self.auth not in _AUTH_MODES:
            raise ValueError(f"invalid auth {self.auth!r} for tool {self.name!r}")
        if self.auth == AUTH_KEY and not self.extra.get("key_rotation_owner"):
            raise ValueError(f"key-auth tool {self.name!r} must declare key_rotation_owner")

    def to_mcp_tool(self) -> dict[str, Any]:
        out: dict[str, Any] = {
            "name": self.name,
            "description": self.description,
            "category": self.category,
            "require_approval": self.require_approval,
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": True},
        }
        if self.endpoint:
            out["endpoint"] = self.endpoint
        if self.auth:
            out["auth"] = self.auth
        if self.extra:
            out["metadata"] = dict(self.extra)
        return out


@dataclass(frozen=True)
class ToolboxManifest:
    environment: str
    tools: list[ToolboxTool]

    # ── views ──
    def by_category(self, category: str) -> list[ToolboxTool]:
        return [t for t in self.tools if t.category == category]

    @property
    def categories(self) -> set[str]:
        return {t.category for t in self.tools}

    def get(self, name: str) -> ToolboxTool | None:
        for t in self.tools:
            if t.name == name:
                return t
        return None

    def to_mcp_list_tools(self) -> dict[str, Any]:
        """MCP ``list_tools`` response shape."""
        return {"tools": [t.to_mcp_tool() for t in self.tools]}

    def summary(self) -> dict[str, Any]:
        counts = {c: len(self.by_category(c)) for c in sorted(self.categories)}
        return {
            "environment": self.environment,
            "total_tools": len(self.tools),
            "by_category": counts,
            "mcp_servers": [t.name for t in self.by_category("mcp")],
            "builtin_tools": [t.name for t in self.by_category("builtin")],
            "a2a_targets": [t.name for t in self.by_category("a2a")],
            "downstream_auth": {t.name: t.auth for t in self.by_category("mcp")},
            "key_auth_owners": {
                t.name: t.extra.get("key_rotation_owner")
                for t in self.by_category("mcp")
                if t.auth == AUTH_KEY
            },
        }


def _normalize_approval(value: Any, default: str) -> str:
    if isinstance(value, str) and value in _APPROVAL_LEVELS:
        return value
    return default


def build_manifest(
    *,
    environment: str | None = None,
    mcp_config_path: str | os.PathLike[str] | None = None,
    a2a_agent_ids: list[str] | None = None,
    openapi_tools: list[dict[str, Any]] | None = None,
) -> ToolboxManifest:
    """Aggregate MCP servers + Foundry built-ins + OpenAPI wrappers + A2A connections."""
    env = environment or os.environ.get("THREE_HORIZONS_ENVIRONMENT") or os.environ.get("ENVIRONMENT") or "dev"
    tools: list[ToolboxTool] = []

    # (a) MCP servers
    for name, entry in load_mcp_servers(mcp_config_path).items():
        posture = {**_DEFAULT_MCP_POSTURE, **_MCP_SERVER_POSTURE.get(name, {})}
        # an explicit per-entry override in mcp-config.json wins
        entry_auth = (entry.get("auth", {}) or {}).get("type") if isinstance(entry.get("auth"), dict) else entry.get("auth")
        auth = entry_auth if entry_auth in _AUTH_MODES else posture["auth"]
        approval = _normalize_approval(entry.get("require_approval"), posture["require_approval"])
        endpoint = entry.get("url") or (("local:" + entry["command"]) if entry.get("command") else None)
        extra: dict[str, Any] = {}
        owner = posture.get("key_rotation_owner") or entry.get("key_rotation_owner")
        if auth == AUTH_KEY and owner:
            extra["key_rotation_owner"] = owner
        tools.append(
            ToolboxTool(
                name=f"mcp.{name}",
                category="mcp",
                require_approval=approval,
                description=f"MCP server '{name}' (aggregated via Foundry Toolbox)",
                endpoint=endpoint,
                auth=auth,
                extra=extra,
            )
        )

    # (b) Foundry built-ins
    for b in _BUILTIN_TOOLS:
        tools.append(
            ToolboxTool(
                name=f"builtin.{b['name']}",
                category="builtin",
                require_approval=b["require_approval"],
                description=b["description"],
            )
        )

    # (c) OpenAPI tool wrappers (config-driven; empty slot by default so the category exists)
    for ow in openapi_tools or []:
        tools.append(
            ToolboxTool(
                name=f"openapi.{ow['name']}",
                category="openapi",
                require_approval=_normalize_approval(ow.get("require_approval"), APPROVAL_ALWAYS),
                description=ow.get("description", f"OpenAPI tool wrapper '{ow['name']}'"),
                endpoint=ow.get("endpoint"),
            )
        )
    if not any(t.category == "openapi" for t in tools):
        tools.append(
            ToolboxTool(
                name="openapi._placeholder",
                category="openapi",
                require_approval=APPROVAL_ALWAYS,
                description="OpenAPI tool-wrapper category (no wrappers registered in this environment)",
                extra={"placeholder": True},
            )
        )

    # (d) A2A connections — the specialized agents are reachable agent-to-agent
    for aid in a2a_agent_ids or []:
        tools.append(
            ToolboxTool(
                name=f"a2a.{aid}",
                category="a2a",
                require_approval=APPROVAL_READ_ONLY,
                description=f"Agent-to-Agent connection to specialized agent '{aid}' (A2A v1.0)",
                extra={"protocol": "a2a/1.0"},
            )
        )

    return ToolboxManifest(environment=env, tools=tools)


# ── tool-call approval enforcement (REQ-TOOLBOX-003) ────────────────────────
class ApprovalRequired(Exception):
    """Raised when a tool call needs human approval that was not supplied."""

    def __init__(self, tool_name: str, policy: str) -> None:
        self.tool_name = tool_name
        self.policy = policy
        super().__init__(f"tool '{tool_name}' requires approval (policy={policy})")


def enforce_approval(manifest: ToolboxManifest, tool_name: str, *, approved: bool, write: bool = False) -> None:
    """Gate a tool call per its ``require_approval`` policy.

    ``approved`` is the caller's signal that the MCP client surfaced (and the user
    accepted) an approval prompt. ``write`` indicates the specific call mutates state
    (only relevant for ``read_only`` tools).
    """
    tool = manifest.get(tool_name)
    if tool is None:
        raise KeyError(f"unknown tool '{tool_name}'")
    policy = tool.require_approval
    if policy == APPROVAL_NEVER:
        return
    if policy == APPROVAL_READ_ONLY and not write:
        return
    if not approved:
        raise ApprovalRequired(tool_name, policy)
