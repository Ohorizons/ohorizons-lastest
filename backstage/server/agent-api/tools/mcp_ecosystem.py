"""
MCP Ecosystem client — connects to the local MCP Ecosystem server (46 tools).

Server: http://localhost:3100 (Docker: mcp-servers/docker-compose.yml)
Protocol: JSON-RPC over HTTP (Streamable HTTP transport)

Tool categories:
  - spec-kit: Spec-Driven Development methodology
  - agent-framework: Microsoft Agent Framework patterns
  - gh-aw: GitHub Agentic Workflows
  - anthropics-skills: Anthropic skills catalog
  - agents-md: AGENTS.md format
  - awesome-copilot: Skills/agents/prompts lookup
  - github-copilot-docs: GitHub Copilot documentation
  - anthropic-docs: Anthropic platform docs
  - backstage-docs: Backstage documentation + API reference
"""

import json
import logging
import os
from typing import Any

import httpx

logger = logging.getLogger("tools.mcp_ecosystem")

MCP_ECOSYSTEM_URL = os.environ.get(
    "MCP_ECOSYSTEM_URL",
    "http://mcp-ecosystem.ai-services.svc.cluster.local:3100/mcp",
)


_session_id: str | None = None
_initialized: bool = False


async def _raw_post(payload: dict, headers: dict[str, str]) -> httpx.Response:
    """Low-level POST to MCP endpoint."""
    async with httpx.AsyncClient(timeout=30) as client:
        return await client.post(MCP_ECOSYSTEM_URL, json=payload, headers=headers)


async def _ensure_initialized() -> None:
    """Send initialize + initialized notification if not yet done for this session."""
    global _session_id, _initialized
    if _initialized and _session_id:
        return

    _session_id = None
    _initialized = False

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }

    # Step 1: initialize
    init_payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2025-03-26",
            "capabilities": {},
            "clientInfo": {"name": "agent-api", "version": "1.0.0"},
        },
    }
    r = await _raw_post(init_payload, headers)
    if "mcp-session-id" in r.headers:
        _session_id = r.headers["mcp-session-id"]
        headers["mcp-session-id"] = _session_id

    # Step 2: notifications/initialized
    notif_payload = {
        "jsonrpc": "2.0",
        "method": "notifications/initialized",
    }
    await _raw_post(notif_payload, headers)
    _initialized = True
    logger.info("MCP session initialized: %s", _session_id)


async def _ecosystem_call(method: str, params: dict | None = None) -> Any:
    """Call MCP Ecosystem server via JSON-RPC over Streamable HTTP."""
    global _session_id, _initialized
    try:
        await _ensure_initialized()
    except Exception as e:
        logger.warning("MCP init failed: %s", e)
        _initialized = False
        _session_id = None
        return {"error": f"MCP init failed: {e}"}

    payload = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": method,
        "params": params or {},
    }
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }
    if _session_id:
        headers["mcp-session-id"] = _session_id
    try:
        r = await _raw_post(payload, headers)
        # If session expired, reinitialize
        if r.status_code == 404:
            _initialized = False
            _session_id = None
            await _ensure_initialized()
            if _session_id:
                headers["mcp-session-id"] = _session_id
            r = await _raw_post(payload, headers)
        if r.status_code == 200:
            ct = r.headers.get("content-type", "")
            if "text/event-stream" in ct:
                # Parse SSE: find last JSON-RPC result line
                for line in r.text.split("\n"):
                    if line.startswith("data: "):
                        try:
                            data = json.loads(line[6:])
                            if "result" in data:
                                return data["result"]
                        except json.JSONDecodeError:
                            continue
                return {"error": "No result in SSE stream"}
            data = r.json()
            if "result" in data:
                return data["result"]
            if "error" in data:
                return {"error": data["error"].get("message", "MCP error")}
        return {"error": f"MCP Ecosystem HTTP {r.status_code}"}
    except httpx.ConnectError:
        return {"error": "MCP Ecosystem server not reachable at " + MCP_ECOSYSTEM_URL}
    except Exception as e:
        return {"error": f"MCP Ecosystem call failed: {e}"}


async def ecosystem_list_tools() -> str:
    """List all available tools from MCP Ecosystem (46 tools)."""
    result = await _ecosystem_call("tools/list")
    if isinstance(result, dict) and "error" in result:
        return json.dumps(result)
    tools = []
    for tool in result.get("tools", []):
        tools.append({
            "name": tool.get("name"),
            "description": tool.get("description", "")[:150],
        })
    return json.dumps({"tools": tools, "count": len(tools)})


async def ecosystem_call_tool(tool_name: str, arguments: dict | None = None) -> str:
    """Call a specific tool on the MCP Ecosystem server."""
    result = await _ecosystem_call("tools/call", {
        "name": tool_name,
        "arguments": arguments or {},
    })
    if isinstance(result, dict):
        return json.dumps(result)
    return str(result)


async def search_backstage_docs(query: str) -> str:
    """Search Backstage documentation via MCP Ecosystem."""
    return await ecosystem_call_tool("backstagedocs_search", {"query": query})


async def search_copilot_docs(query: str) -> str:
    """Search GitHub Copilot documentation via MCP Ecosystem."""
    return await ecosystem_call_tool("ghaw_get_workflow_patterns", {})


async def search_anthropic_docs(query: str) -> str:
    """Search Anthropic platform documentation via MCP Ecosystem."""
    return await ecosystem_call_tool("anthropicdocs_search", {"query": query})


async def get_spec_kit_methodology() -> str:
    """Get Spec-Driven Development methodology from MCP Ecosystem."""
    return await ecosystem_call_tool("speckit_get_methodology", {})


async def search_awesome_copilot(query: str, category: str = "all") -> str:
    """Search awesome-copilot for agents, skills, prompts, or instructions."""
    return await ecosystem_call_tool("awesome_search", {
        "query": query,
    })


# ── Tool dispatcher ──────────────────────────────────────────────
ECOSYSTEM_TOOL_REGISTRY = {
    "ecosystem_list_tools": ecosystem_list_tools,
    "ecosystem_call_tool": ecosystem_call_tool,
    "search_backstage_docs": search_backstage_docs,
    "search_copilot_docs": search_copilot_docs,
    "search_anthropic_docs": search_anthropic_docs,
    "get_spec_kit_methodology": get_spec_kit_methodology,
    "search_awesome_copilot": search_awesome_copilot,
}


async def execute_ecosystem_tool(name: str, input_data: dict) -> str:
    """Dispatch an MCP Ecosystem tool call."""
    func = ECOSYSTEM_TOOL_REGISTRY.get(name)
    if not func:
        return json.dumps({"error": f"Unknown ecosystem tool: {name}"})
    try:
        return await func(**input_data)
    except TypeError as e:
        return json.dumps({"error": f"Invalid params for {name}: {e}"})
    except Exception as e:
        logger.error("Ecosystem tool %s failed: %s", name, e)
        return json.dumps({"error": f"Tool failed: {e}"})
