"""Kubernetes API tools using MAF @tool decorator."""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from agent_framework import tool

logger = logging.getLogger("tools.infra")

KUBE_API_URL = os.getenv("KUBE_API_URL", "http://host.docker.internal:8001")
KUBE_TOKEN = os.getenv("KUBE_TOKEN", "")


async def _kube_get(path: str) -> Any:
    headers: dict[str, str] = {"Accept": "application/json"}
    if KUBE_TOKEN:
        headers["Authorization"] = f"Bearer {KUBE_TOKEN}"
    try:
        async with httpx.AsyncClient(timeout=15, verify=False) as client:
            r = await client.get(f"{KUBE_API_URL}{path}", headers=headers)
            return r.json() if r.status_code == 200 else {"error": f"K8s API {r.status_code}"}
    except httpx.ConnectError:
        return {"error": "Kubernetes API not reachable. Run: kubectl proxy --port=8001"}


@tool
async def kube_list_namespaces() -> str:
    """List all Kubernetes namespaces."""
    data = await _kube_get("/api/v1/namespaces")
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    ns = [{"name": n["metadata"]["name"], "status": n["status"]["phase"]} for n in data.get("items", [])]
    return json.dumps({"namespaces": ns, "total": len(ns)})


@tool
async def kube_list_pods(namespace: Annotated[str, "Kubernetes namespace"] = "backstage") -> str:
    """List pods in a namespace with status and restarts."""
    data = await _kube_get(f"/api/v1/namespaces/{namespace}/pods")
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    pods = []
    for p in data.get("items", []):
        containers = [{"name": c.get("name"), "ready": c.get("ready"), "restarts": c.get("restartCount")}
                      for c in p.get("status", {}).get("containerStatuses", [])]
        pods.append({"name": p["metadata"]["name"], "phase": p["status"]["phase"], "containers": containers})
    return json.dumps({"pods": pods, "total": len(pods)})


@tool
async def kube_list_deployments(namespace: Annotated[str, "Kubernetes namespace"] = "backstage") -> str:
    """List deployments with replica counts and images."""
    data = await _kube_get(f"/apis/apps/v1/namespaces/{namespace}/deployments")
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    deps = []
    for d in data.get("items", []):
        s = d.get("status", {})
        deps.append({"name": d["metadata"]["name"], "replicas": s.get("replicas", 0),
                      "ready": s.get("readyReplicas", 0),
                      "image": d["spec"]["template"]["spec"]["containers"][0].get("image")})
    return json.dumps({"deployments": deps, "total": len(deps)})


@tool
async def kube_get_events(
    namespace: Annotated[str, "Kubernetes namespace"] = "backstage",
    limit: Annotated[int, "Max events"] = 15,
) -> str:
    """List recent Kubernetes events (warnings, errors, status changes)."""
    data = await _kube_get(f"/api/v1/namespaces/{namespace}/events")
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    items = sorted(data.get("items", []), key=lambda e: e.get("metadata", {}).get("creationTimestamp", ""), reverse=True)
    events = [{"type": e.get("type"), "reason": e.get("reason"), "message": e.get("message", "")[:200],
               "object": f"{e.get('involvedObject', {}).get('kind')}/{e.get('involvedObject', {}).get('name')}"}
              for e in items[:limit]]
    return json.dumps({"events": events, "total": len(events)})


@tool
async def kube_cluster_health() -> str:
    """Get cluster health: node status and conditions."""
    data = await _kube_get("/api/v1/nodes")
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    nodes = []
    for n in data.get("items", []):
        conditions = {c["type"]: c["status"] for c in n.get("status", {}).get("conditions", [])}
        alloc = n.get("status", {}).get("allocatable", {})
        nodes.append({"name": n["metadata"]["name"], "ready": conditions.get("Ready"),
                      "cpu": alloc.get("cpu"), "memory": alloc.get("memory")})
    return json.dumps({"nodes": nodes, "total": len(nodes)})
