"""Backstage Catalog API tools using MAF @tool decorator."""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from agent_framework import tool

logger = logging.getLogger("tools.backstage")

BACKSTAGE_URL = os.getenv("BACKSTAGE_URL", "http://host.docker.internal:7007")


@tool
async def backstage_catalog_search(
    query: Annotated[str, "Entity name or filter"],
    kind: Annotated[str, "Entity kind: Component, API, System, Group, User"] = "",
    limit: Annotated[int, "Max results"] = 10,
) -> str:
    """Search the Backstage Software Catalog for components, APIs, systems, and users."""
    try:
        params: dict[str, Any] = {"filter": f"metadata.name={query}"}
        if kind:
            params["filter"] = f"kind={kind}"
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(f"{BACKSTAGE_URL}/api/catalog/entities", params=params)
            if r.status_code == 200:
                results = [{"kind": e.get("kind"), "name": e["metadata"]["name"],
                            "description": e["metadata"].get("description", "")[:200],
                            "type": e.get("spec", {}).get("type"),
                            "owner": e.get("spec", {}).get("owner")} for e in r.json()[:limit]]
                return json.dumps({"entities": results, "total": len(results)})
            return json.dumps({"error": f"Catalog API {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Backstage not reachable"})


@tool
async def backstage_list_templates() -> str:
    """List available Golden Path templates from the Backstage Scaffolder."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(f"{BACKSTAGE_URL}/api/catalog/entities", params={"filter": "kind=Template"})
            if r.status_code == 200:
                templates = [{"name": e["metadata"]["name"], "title": e["metadata"].get("title", ""),
                              "description": e["metadata"].get("description", "")[:200],
                              "tags": e["metadata"].get("tags", [])} for e in r.json()]
                return json.dumps({"templates": templates, "total": len(templates)})
            return json.dumps({"error": f"Catalog API {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Backstage not reachable"})
