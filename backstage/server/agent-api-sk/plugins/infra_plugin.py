"""
Infrastructure Plugin — Kubernetes API tools as Semantic Kernel functions.

Connects to the Kubernetes API via kubectl proxy or direct API.
For local kind cluster: uses kubeconfig context.
For AKS: uses in-cluster or kubeconfig credentials.
"""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from semantic_kernel.functions import kernel_function

logger = logging.getLogger("plugins.infra")

# Default to kind cluster API via kubectl proxy or direct access
KUBE_API_URL = os.getenv("KUBE_API_URL", "http://localhost:8001")
KUBE_TOKEN = os.getenv("KUBE_TOKEN", "")


def _kube_headers() -> dict[str, str]:
    h: dict[str, str] = {"Accept": "application/json"}
    if KUBE_TOKEN:
        h["Authorization"] = f"Bearer {KUBE_TOKEN}"
    return h


async def _kube_get(path: str) -> Any:
    try:
        async with httpx.AsyncClient(timeout=15, verify=False) as client:
            r = await client.get(f"{KUBE_API_URL}{path}", headers=_kube_headers())
            if r.status_code == 200:
                return r.json()
            return {"error": f"Kubernetes API {r.status_code}", "message": r.text[:300]}
    except httpx.ConnectError:
        return {"error": "Kubernetes API not reachable. Run: kubectl proxy --port=8001"}
    except Exception as e:
        return {"error": str(e)}


class InfraPlugin:
    """Kubernetes cluster tools for the Forge agent."""

    @kernel_function(
        name="kube_list_namespaces",
        description="List all Kubernetes namespaces in the cluster.",
    )
    async def kube_list_namespaces(self) -> str:
        data = await _kube_get("/api/v1/namespaces")
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        namespaces = []
        for ns in data.get("items", []):
            namespaces.append({
                "name": ns.get("metadata", {}).get("name"),
                "status": ns.get("status", {}).get("phase"),
                "labels": ns.get("metadata", {}).get("labels", {}),
                "created_at": ns.get("metadata", {}).get("creationTimestamp"),
            })
        return json.dumps({"namespaces": namespaces, "total": len(namespaces)})

    @kernel_function(
        name="kube_list_pods",
        description="List pods in a namespace with their status, restarts, and age.",
    )
    async def kube_list_pods(
        self,
        namespace: Annotated[str, "Kubernetes namespace"] = "backstage",
    ) -> str:
        data = await _kube_get(f"/api/v1/namespaces/{namespace}/pods")
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        pods = []
        for pod in data.get("items", []):
            containers = []
            for cs in pod.get("status", {}).get("containerStatuses", []):
                containers.append({
                    "name": cs.get("name"),
                    "ready": cs.get("ready"),
                    "restart_count": cs.get("restartCount"),
                    "state": list(cs.get("state", {}).keys())[0] if cs.get("state") else "unknown",
                })
            pods.append({
                "name": pod.get("metadata", {}).get("name"),
                "namespace": namespace,
                "phase": pod.get("status", {}).get("phase"),
                "node": pod.get("spec", {}).get("nodeName"),
                "containers": containers,
                "created_at": pod.get("metadata", {}).get("creationTimestamp"),
            })
        return json.dumps({"pods": pods, "total": len(pods)})

    @kernel_function(
        name="kube_list_deployments",
        description="List deployments in a namespace with replica counts and conditions.",
    )
    async def kube_list_deployments(
        self,
        namespace: Annotated[str, "Kubernetes namespace"] = "backstage",
    ) -> str:
        data = await _kube_get(f"/apis/apps/v1/namespaces/{namespace}/deployments")
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        deployments = []
        for dep in data.get("items", []):
            status = dep.get("status", {})
            deployments.append({
                "name": dep.get("metadata", {}).get("name"),
                "namespace": namespace,
                "replicas": status.get("replicas", 0),
                "ready_replicas": status.get("readyReplicas", 0),
                "available_replicas": status.get("availableReplicas", 0),
                "updated_replicas": status.get("updatedReplicas", 0),
                "image": dep.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [{}])[0].get("image"),
                "created_at": dep.get("metadata", {}).get("creationTimestamp"),
            })
        return json.dumps({"deployments": deployments, "total": len(deployments)})

    @kernel_function(
        name="kube_list_services",
        description="List services in a namespace with type, ports, and cluster IPs.",
    )
    async def kube_list_services(
        self,
        namespace: Annotated[str, "Kubernetes namespace"] = "backstage",
    ) -> str:
        data = await _kube_get(f"/api/v1/namespaces/{namespace}/services")
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        services = []
        for svc in data.get("items", []):
            spec = svc.get("spec", {})
            ports = []
            for p in spec.get("ports", []):
                ports.append({
                    "name": p.get("name"),
                    "port": p.get("port"),
                    "target_port": p.get("targetPort"),
                    "protocol": p.get("protocol"),
                    "node_port": p.get("nodePort"),
                })
            services.append({
                "name": svc.get("metadata", {}).get("name"),
                "namespace": namespace,
                "type": spec.get("type"),
                "cluster_ip": spec.get("clusterIP"),
                "ports": ports,
            })
        return json.dumps({"services": services, "total": len(services)})

    @kernel_function(
        name="kube_get_events",
        description="List recent Kubernetes events in a namespace. Shows warnings, errors, and status changes.",
    )
    async def kube_get_events(
        self,
        namespace: Annotated[str, "Kubernetes namespace"] = "backstage",
        limit: Annotated[int, "Max events to return"] = 15,
    ) -> str:
        data = await _kube_get(f"/api/v1/namespaces/{namespace}/events")
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        events = []
        items = sorted(
            data.get("items", []),
            key=lambda e: e.get("metadata", {}).get("creationTimestamp", ""),
            reverse=True,
        )
        for ev in items[:limit]:
            events.append({
                "type": ev.get("type"),
                "reason": ev.get("reason"),
                "message": ev.get("message", "")[:200],
                "object": f"{ev.get('involvedObject', {}).get('kind', '')}/{ev.get('involvedObject', {}).get('name', '')}",
                "count": ev.get("count"),
                "first_seen": ev.get("firstTimestamp"),
                "last_seen": ev.get("lastTimestamp"),
            })
        return json.dumps({"events": events, "total": len(events)})

    @kernel_function(
        name="kube_cluster_health",
        description="Get overall cluster health: node status, resource usage summary, and component status.",
    )
    async def kube_cluster_health(self) -> str:
        nodes_data = await _kube_get("/api/v1/nodes")
        if isinstance(nodes_data, dict) and "error" in nodes_data:
            return json.dumps(nodes_data)

        nodes = []
        for node in nodes_data.get("items", []):
            conditions = {}
            for c in node.get("status", {}).get("conditions", []):
                conditions[c.get("type")] = c.get("status")
            allocatable = node.get("status", {}).get("allocatable", {})
            nodes.append({
                "name": node.get("metadata", {}).get("name"),
                "roles": [k.replace("node-role.kubernetes.io/", "") for k in node.get("metadata", {}).get("labels", {}) if "node-role" in k],
                "ready": conditions.get("Ready"),
                "memory_pressure": conditions.get("MemoryPressure"),
                "disk_pressure": conditions.get("DiskPressure"),
                "cpu_allocatable": allocatable.get("cpu"),
                "memory_allocatable": allocatable.get("memory"),
            })
        return json.dumps({"nodes": nodes, "total": len(nodes)})
