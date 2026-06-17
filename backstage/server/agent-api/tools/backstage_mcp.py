"""
Backstage MCP Actions client — calls Backstage MCP Actions backend.

Endpoint: http://localhost:7007/api/mcp-actions/v1 (Streamable HTTP)
Auth: dangerouslyDisableDefaultAuthPolicy=true (no token needed for local demo)

Tools exposed by Backstage MCP Actions (from catalog + scaffolder plugins):
  - catalog entity search
  - scaffolder template list
  - scaffolder create from template
"""

import json
import logging
import os
from typing import Any

import httpx

logger = logging.getLogger("tools.backstage_mcp")

BACKSTAGE_URL = os.environ.get(
    "BACKSTAGE_URL",
    "http://ohorizons-backstage.backstage.svc.cluster.local:7007",
)
MCP_ACTIONS_URL = f"{BACKSTAGE_URL}/api/mcp-actions/v1"


async def _mcp_call(method: str, params: dict | None = None) -> Any:
    """Call Backstage MCP Actions via JSON-RPC over HTTP."""
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": method,
        "params": params or {},
    }
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.post(MCP_ACTIONS_URL, json=payload)
            if r.status_code == 200:
                data = r.json()
                if "result" in data:
                    return data["result"]
                if "error" in data:
                    return {"error": data["error"].get("message", "MCP error")}
            return {"error": f"MCP Actions HTTP {r.status_code}", "body": r.text[:300]}
    except httpx.ConnectError:
        return {"error": "Backstage MCP Actions not reachable (is Backstage running?)"}
    except Exception as e:
        return {"error": f"MCP call failed: {e}"}


async def backstage_list_tools() -> str:
    """List available MCP tools from Backstage."""
    result = await _mcp_call("tools/list")
    if isinstance(result, dict) and "error" in result:
        return json.dumps(result)
    tools = []
    for tool in result.get("tools", []):
        tools.append({
            "name": tool.get("name"),
            "description": tool.get("description", "")[:200],
        })
    return json.dumps({"tools": tools, "count": len(tools)})


async def backstage_call_tool(tool_name: str, arguments: dict | None = None) -> str:
    """Call a specific MCP tool on Backstage."""
    result = await _mcp_call("tools/call", {
        "name": tool_name,
        "arguments": arguments or {},
    })
    return json.dumps(result) if isinstance(result, dict) else str(result)


async def backstage_catalog_search(query: str, kind: str = "", limit: int = 10) -> str:
    """Search Backstage Software Catalog entities."""
    # Try MCP first, fall back to direct API
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            params: dict[str, Any] = {"filter": f"metadata.name={query}"}
            if kind:
                params["filter"] = f"kind={kind}"
            r = await client.get(
                f"{BACKSTAGE_URL}/api/catalog/entities",
                params=params,
            )
            if r.status_code == 200:
                entities = r.json()[:limit]
                results = []
                for e in entities:
                    results.append({
                        "kind": e.get("kind"),
                        "name": e.get("metadata", {}).get("name"),
                        "namespace": e.get("metadata", {}).get("namespace"),
                        "description": e.get("metadata", {}).get("description", "")[:200],
                        "type": e.get("spec", {}).get("type"),
                        "owner": e.get("spec", {}).get("owner"),
                        "lifecycle": e.get("spec", {}).get("lifecycle"),
                    })
                return json.dumps({"entities": results, "total": len(results)})
            return json.dumps({"error": f"Catalog API {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Backstage not reachable"})
    except Exception as e:
        return json.dumps({"error": str(e)})


async def backstage_list_templates() -> str:
    """List available Golden Path templates from Backstage Scaffolder."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(
                f"{BACKSTAGE_URL}/api/catalog/entities",
                params={"filter": "kind=Template"},
            )
            if r.status_code == 200:
                templates = []
                for e in r.json():
                    templates.append({
                        "name": e.get("metadata", {}).get("name"),
                        "title": e.get("metadata", {}).get("title", ""),
                        "description": e.get("metadata", {}).get("description", "")[:200],
                        "type": e.get("spec", {}).get("type"),
                        "owner": e.get("spec", {}).get("owner"),
                        "tags": e.get("metadata", {}).get("tags", []),
                    })
                return json.dumps({"templates": templates, "total": len(templates)})
            return json.dumps({"error": f"Catalog API {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Backstage not reachable"})
    except Exception as e:
        return json.dumps({"error": str(e)})


# ── Tool dispatcher ──────────────────────────────────────────────
BACKSTAGE_TOOL_REGISTRY = {
    "backstage_catalog_search": backstage_catalog_search,
    "backstage_list_templates": backstage_list_templates,
    "backstage_list_tools": backstage_list_tools,
    "backstage_call_tool": backstage_call_tool,
}


async def execute_backstage_tool(name: str, input_data: dict) -> str:
    """Dispatch a Backstage MCP tool call."""
    func = BACKSTAGE_TOOL_REGISTRY.get(name)
    if not func:
        return json.dumps({"error": f"Unknown Backstage tool: {name}"})
    try:
        return await func(**input_data)
    except TypeError as e:
        return json.dumps({"error": f"Invalid params for {name}: {e}"})
    except Exception as e:
        logger.error("Backstage tool %s failed: %s", name, e)
        return json.dumps({"error": f"Tool failed: {e}"})
