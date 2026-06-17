"""
Backstage Plugin — Backstage MCP Actions + Catalog API as Semantic Kernel functions.
"""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from semantic_kernel.functions import kernel_function

logger = logging.getLogger("plugins.backstage")

BACKSTAGE_URL = os.getenv("BACKSTAGE_URL", "http://localhost:7007")
MCP_ACTIONS_URL = f"{BACKSTAGE_URL}/api/mcp-actions/v1"


class BackstagePlugin:
    """Backstage Software Catalog and Scaffolder tools."""

    @kernel_function(
        name="backstage_catalog_search",
        description="Search the Backstage Software Catalog for components, APIs, systems, and users.",
    )
    async def backstage_catalog_search(
        self,
        query: Annotated[str, "Entity name or filter"],
        kind: Annotated[str, "Entity kind: Component, API, System, Group, User"] = "",
        limit: Annotated[int, "Max results to return"] = 10,
    ) -> str:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                params: dict[str, Any] = {"filter": f"metadata.name={query}"}
                if kind:
                    params["filter"] = f"kind={kind}"
                r = await client.get(f"{BACKSTAGE_URL}/api/catalog/entities", params=params)
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

    @kernel_function(
        name="backstage_list_templates",
        description="List available Golden Path templates from the Backstage Scaffolder.",
    )
    async def backstage_list_templates(self) -> str:
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
