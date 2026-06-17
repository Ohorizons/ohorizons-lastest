"""Prometheus + Grafana tools using MAF @tool decorator."""

import os
import json
import logging
from typing import Annotated

import httpx
from agent_framework import tool

logger = logging.getLogger("tools.observability")

PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://host.docker.internal:9090")
GRAFANA_URL = os.getenv("GRAFANA_URL", "http://host.docker.internal:3000")
GRAFANA_TOKEN = os.getenv("GRAFANA_TOKEN", "")


@tool
async def prometheus_query(query: Annotated[str, "PromQL query"]) -> str:
    """Execute a PromQL instant query against Prometheus."""
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.get(f"{PROMETHEUS_URL}/api/v1/query", params={"query": query})
            if r.status_code == 200:
                data = r.json()
                if data.get("status") == "success":
                    results = [{"metric": i.get("metric", {}), "value": i.get("value", [None, None])[1]}
                               for i in data.get("data", {}).get("result", [])[:20]]
                    return json.dumps({"results": results, "total": len(results)})
            return json.dumps({"error": f"Prometheus {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Prometheus not reachable (port 9090)"})


@tool
async def prometheus_alerts() -> str:
    """List active Prometheus alerts (firing and pending)."""
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.get(f"{PROMETHEUS_URL}/api/v1/alerts")
            if r.status_code == 200:
                alerts = [{"alertname": a.get("labels", {}).get("alertname"), "state": a.get("state"),
                           "severity": a.get("labels", {}).get("severity"),
                           "summary": a.get("annotations", {}).get("summary", "")[:200]}
                          for a in r.json().get("data", {}).get("alerts", [])]
                return json.dumps({"alerts": alerts, "total": len(alerts)})
            return json.dumps({"error": f"Prometheus {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Prometheus not reachable"})


@tool
async def prometheus_targets() -> str:
    """List Prometheus scrape targets and their health."""
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.get(f"{PROMETHEUS_URL}/api/v1/targets")
            if r.status_code == 200:
                targets = [{"job": t.get("labels", {}).get("job"), "health": t.get("health"),
                            "instance": t.get("labels", {}).get("instance")}
                           for t in r.json().get("data", {}).get("activeTargets", [])]
                return json.dumps({"targets": targets, "total": len(targets)})
            return json.dumps({"error": f"Prometheus {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Prometheus not reachable"})


@tool
async def grafana_list_dashboards() -> str:
    """List available Grafana dashboards."""
    headers: dict[str, str] = {"Accept": "application/json"}
    if GRAFANA_TOKEN:
        headers["Authorization"] = f"Bearer {GRAFANA_TOKEN}"
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.get(f"{GRAFANA_URL}/api/search", headers=headers, params={"type": "dash-db"})
            if r.status_code == 200:
                dashboards = [{"uid": d.get("uid"), "title": d.get("title"),
                               "url": f"{GRAFANA_URL}{d.get('url', '')}"} for d in r.json()[:20]]
                return json.dumps({"dashboards": dashboards, "total": len(dashboards)})
            return json.dumps({"error": f"Grafana {r.status_code}"})
    except httpx.ConnectError:
        return json.dumps({"error": "Grafana not reachable (port 3000)"})
