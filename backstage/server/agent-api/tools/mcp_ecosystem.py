"""
MCP Ecosystem client — connects to the local MCP Ecosystem server (79 tools / 17 modules).

Server: http://localhost:3100/mcp (Docker: mcp-servers/docker-compose.yml)
Protocol: JSON-RPC over HTTP (Streamable HTTP transport)

Tool modules (group · module · tool prefix):
  Group A — Agent & AI frameworks
    - spec-kit ............ speckit_*     Spec-Driven Development methodology
    - anthropics-skills ... anthropics_*  Anthropic skills catalog + specs
    - agent-framework ..... agentfw_*     Microsoft Agent Framework patterns
    - gh-aw ............... ghaw_*        GitHub Agentic Workflows
    - agents-md ........... agentsmd_*    AGENTS.md format spec + templates
    - github-copilot-docs . copilotdocs_* GitHub Copilot documentation (deep)
  Group B — Backstage ecosystem
    - backstage-docs ...... backstagedocs_*    Backstage docs + API reference
    - backstage-plugins ... backstageplugins_* Plugin directory (core + community)
    - backstage-ui ........ backstageui_*      Backstage UI components + storybook
    - spotify-backstage ... spotifybackstage_* Spotify Portal / upstream docs
    - backstage-org ....... backstageorg_*     github.com/backstage repos
  Group C — Official documentation
    - microsoft-learn ..... mslearn_*     ALL Microsoft Learn (Azure/AKS/Foundry/CAF/WAF), federated
    - vscode-docs ......... vscode_*      code.visualstudio.com/docs (all themes)
    - github-docs ......... ghdocs_*      docs.github.com (Actions, GHAS, OIDC, Packages, …)
    - anthropic-docs ...... anthropicdocs_* Complete Claude docs (llms-full.txt)
    - azure-caf ........... caf_*         Cloud Adoption Framework
    - azure-waf ........... waf_*         Well-Architected Framework
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
    """List all available tools from MCP Ecosystem (79 tools across 17 modules)."""
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
    return await ecosystem_call_tool("copilotdocs_search", {"query": query})


async def search_anthropic_docs(query: str) -> str:
    """Search the complete Anthropic/Claude documentation via MCP Ecosystem."""
    return await ecosystem_call_tool("anthropicdocs_search", {"query": query})


async def get_spec_kit_methodology() -> str:
    """Get Spec-Driven Development methodology from MCP Ecosystem."""
    return await ecosystem_call_tool("speckit_get_methodology", {})


async def search_microsoft_learn(query: str) -> str:
    """Search ALL of Microsoft Learn (Azure, AKS, AI Foundry, CAF, WAF) via federation."""
    return await ecosystem_call_tool("mslearn_search", {"query": query})


async def fetch_microsoft_learn(url: str) -> str:
    """Fetch a full Microsoft Learn page as markdown by URL."""
    return await ecosystem_call_tool("mslearn_fetch", {"url": url})


async def search_vscode_docs(query: str, section: str = "copilot") -> str:
    """Search VS Code documentation (code.visualstudio.com/docs)."""
    return await ecosystem_call_tool("vscode_search", {"query": query, "section": section})


async def search_github_docs(query: str, section: str = "get-started") -> str:
    """Search GitHub documentation (docs.github.com): Actions, GHAS, OIDC, Packages."""
    return await ecosystem_call_tool("ghdocs_search", {"query": query, "section": section})


async def search_caf(query: str, section: str = "ready") -> str:
    """Search the Azure Cloud Adoption Framework (CAF)."""
    return await ecosystem_call_tool("caf_search", {"query": query, "section": section})


async def search_waf(query: str, section: str = "reliability") -> str:
    """Search the Azure Well-Architected Framework (WAF)."""
    return await ecosystem_call_tool("waf_search", {"query": query, "section": section})


# ── Tool dispatcher ──────────────────────────────────────────────
ECOSYSTEM_TOOL_REGISTRY = {
    "ecosystem_list_tools": ecosystem_list_tools,
    "ecosystem_call_tool": ecosystem_call_tool,
    "search_backstage_docs": search_backstage_docs,
    "search_copilot_docs": search_copilot_docs,
    "search_anthropic_docs": search_anthropic_docs,
    "get_spec_kit_methodology": get_spec_kit_methodology,
    "search_microsoft_learn": search_microsoft_learn,
    "fetch_microsoft_learn": fetch_microsoft_learn,
    "search_vscode_docs": search_vscode_docs,
    "search_github_docs": search_github_docs,
    "search_caf": search_caf,
    "search_waf": search_waf,
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
