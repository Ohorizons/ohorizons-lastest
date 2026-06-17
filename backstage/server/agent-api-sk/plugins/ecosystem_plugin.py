"""
MCP Ecosystem Plugin — tools from the MCP Ecosystem server as Semantic Kernel functions.
"""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from semantic_kernel.functions import kernel_function

logger = logging.getLogger("plugins.ecosystem")

MCP_ECOSYSTEM_URL = os.getenv("MCP_ECOSYSTEM_URL", "http://localhost:3100")


async def _ecosystem_call(method: str, params: dict | None = None) -> Any:
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": method,
        "params": params or {},
    }
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.post(MCP_ECOSYSTEM_URL, json=payload)
            if r.status_code == 200:
                data = r.json()
                if "result" in data:
                    return data["result"]
                if "error" in data:
                    return {"error": data["error"].get("message", "MCP error")}
            return {"error": f"MCP Ecosystem HTTP {r.status_code}"}
    except httpx.ConnectError:
        return {"error": "MCP Ecosystem server not running. Start with: cd mcp-servers && docker-compose up -d"}
    except Exception as e:
        return {"error": f"MCP Ecosystem call failed: {e}"}


async def _call_tool(tool_name: str, arguments: dict | None = None) -> str:
    result = await _ecosystem_call("tools/call", {
        "name": tool_name,
        "arguments": arguments or {},
    })
    return json.dumps(result) if isinstance(result, dict) else str(result)


class EcosystemPlugin:
    """MCP Ecosystem documentation search tools."""

    @kernel_function(
        name="search_backstage_docs",
        description="Search Backstage official documentation via MCP Ecosystem.",
    )
    async def search_backstage_docs(
        self,
        query: Annotated[str, "Documentation search query"],
    ) -> str:
        return await _call_tool("backstageDocSearch", {"query": query})

    @kernel_function(
        name="search_copilot_docs",
        description="Search GitHub Copilot documentation via MCP Ecosystem.",
    )
    async def search_copilot_docs(
        self,
        query: Annotated[str, "Copilot docs search query"],
    ) -> str:
        return await _call_tool("githubCopilotDocSearch", {"query": query})

    @kernel_function(
        name="search_copilot_docs",
        description="Search Anthropic platform documentation via MCP Ecosystem.",
    )
    async def search_copilot_docs(
        self,
        query: Annotated[str, "Anthropic docs search query"],
    ) -> str:
        return await _call_tool("copilotDocSearch", {"query": query})

    @kernel_function(
        name="get_spec_kit_methodology",
        description="Get Spec-Driven Development methodology from MCP Ecosystem.",
    )
    async def get_spec_kit_methodology(self) -> str:
        return await _call_tool("specKitGetMethodology", {})

    @kernel_function(
        name="search_awesome_copilot",
        description="Search awesome-copilot for agents, skills, prompts, or instructions.",
    )
    async def search_awesome_copilot(
        self,
        query: Annotated[str, "Search query"],
        category: Annotated[str, "Category: all, agents, skills, prompts"] = "all",
    ) -> str:
        return await _call_tool("awesomeCopilotSearch", {
            "query": query,
            "category": category,
        })
