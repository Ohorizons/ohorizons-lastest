"""
Observability Plugin — Prometheus + Grafana API tools as Semantic Kernel functions.

Connects to Prometheus (http://localhost:9090) and Grafana (http://localhost:3000)
running in the kind cluster via NodePort.
"""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from semantic_kernel.functions import kernel_function

logger = logging.getLogger("plugins.observability")

PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://localhost:9090")
GRAFANA_URL = os.getenv("GRAFANA_URL", "http://localhost:3000")
GRAFANA_TOKEN = os.getenv("GRAFANA_TOKEN", "")


class ObservabilityPlugin:
    """Prometheus and Grafana tools for the Lighthouse agent."""

    # ── Prometheus Tools ───────────────────────────────────────────

    @kernel_function(
        name="prometheus_query",
        description="Execute a PromQL instant query against Prometheus. Returns current metric values.",
    )
    async def prometheus_query(
        self,
        query: Annotated[str, "PromQL query (e.g., 'up', 'rate(http_requests_total[5m])')"],
    ) -> str:
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.get(f"{PROMETHEUS_URL}/api/v1/query", params={"query": query})
                if r.status_code == 200:
                    data = r.json()
                    if data.get("status") == "success":
                        results = []
                        for item in data.get("data", {}).get("result", [])[:20]:
                            results.append({
                                "metric": item.get("metric", {}),
                                "value": item.get("value", [None, None])[1],
                                "timestamp": item.get("value", [None])[0],
                            })
                        return json.dumps({"status": "success", "results": results, "total": len(results)})
                    return json.dumps({"error": data.get("error", "Query failed")})
                return json.dumps({"error": f"Prometheus HTTP {r.status_code}"})
        except httpx.ConnectError:
            return json.dumps({"error": "Prometheus not reachable. Is it running on port 9090?"})
        except Exception as e:
            return json.dumps({"error": str(e)})

    @kernel_function(
        name="prometheus_alerts",
        description="List active Prometheus alerts. Shows firing and pending alerts with labels and annotations.",
    )
    async def prometheus_alerts(self) -> str:
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.get(f"{PROMETHEUS_URL}/api/v1/alerts")
                if r.status_code == 200:
                    data = r.json()
                    alerts = []
                    for alert in data.get("data", {}).get("alerts", []):
                        alerts.append({
                            "alertname": alert.get("labels", {}).get("alertname"),
                            "state": alert.get("state"),
                            "severity": alert.get("labels", {}).get("severity"),
                            "namespace": alert.get("labels", {}).get("namespace"),
                            "summary": alert.get("annotations", {}).get("summary", "")[:200],
                            "description": alert.get("annotations", {}).get("description", "")[:200],
                            "active_at": alert.get("activeAt"),
                        })
                    return json.dumps({"alerts": alerts, "total": len(alerts)})
                return json.dumps({"error": f"Prometheus HTTP {r.status_code}"})
        except httpx.ConnectError:
            return json.dumps({"error": "Prometheus not reachable"})
        except Exception as e:
            return json.dumps({"error": str(e)})

    @kernel_function(
        name="prometheus_targets",
        description="List Prometheus scrape targets and their health status (up/down).",
    )
    async def prometheus_targets(self) -> str:
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.get(f"{PROMETHEUS_URL}/api/v1/targets")
                if r.status_code == 200:
                    data = r.json()
                    targets = []
                    for t in data.get("data", {}).get("activeTargets", []):
                        targets.append({
                            "job": t.get("labels", {}).get("job"),
                            "instance": t.get("labels", {}).get("instance"),
                            "health": t.get("health"),
                            "scrape_url": t.get("scrapeUrl"),
                            "last_scrape": t.get("lastScrape"),
                            "last_error": t.get("lastError", "")[:200] if t.get("lastError") else None,
                        })
                    return json.dumps({"targets": targets, "total": len(targets)})
                return json.dumps({"error": f"Prometheus HTTP {r.status_code}"})
        except httpx.ConnectError:
            return json.dumps({"error": "Prometheus not reachable"})
        except Exception as e:
            return json.dumps({"error": str(e)})

    # ── Grafana Tools ──────────────────────────────────────────────

    @kernel_function(
        name="grafana_list_dashboards",
        description="List available Grafana dashboards with their titles and URLs.",
    )
    async def grafana_list_dashboards(self) -> str:
        headers: dict[str, str] = {"Accept": "application/json"}
        if GRAFANA_TOKEN:
            headers["Authorization"] = f"Bearer {GRAFANA_TOKEN}"

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.get(f"{GRAFANA_URL}/api/search", headers=headers, params={"type": "dash-db"})
                if r.status_code == 200:
                    dashboards = []
                    for d in r.json()[:20]:
                        dashboards.append({
                            "uid": d.get("uid"),
                            "title": d.get("title"),
                            "url": f"{GRAFANA_URL}{d.get('url', '')}",
                            "tags": d.get("tags", []),
                            "type": d.get("type"),
                        })
                    return json.dumps({"dashboards": dashboards, "total": len(dashboards)})
                return json.dumps({"error": f"Grafana HTTP {r.status_code}"})
        except httpx.ConnectError:
            return json.dumps({"error": "Grafana not reachable. Is it running on port 3000?"})
        except Exception as e:
            return json.dumps({"error": str(e)})

    @kernel_function(
        name="grafana_get_alerts",
        description="List Grafana alert rules and their current state (firing, normal, pending).",
    )
    async def grafana_get_alerts(self) -> str:
        headers: dict[str, str] = {"Accept": "application/json"}
        if GRAFANA_TOKEN:
            headers["Authorization"] = f"Bearer {GRAFANA_TOKEN}"

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.get(f"{GRAFANA_URL}/api/v1/provisioning/alert-rules", headers=headers)
                if r.status_code == 200:
                    rules = []
                    for rule in r.json()[:20]:
                        rules.append({
                            "uid": rule.get("uid"),
                            "title": rule.get("title"),
                            "condition": rule.get("condition"),
                            "folder_uid": rule.get("folderUID"),
                            "is_paused": rule.get("isPaused"),
                        })
                    return json.dumps({"alert_rules": rules, "total": len(rules)})
                return json.dumps({"error": f"Grafana HTTP {r.status_code}"})
        except httpx.ConnectError:
            return json.dumps({"error": "Grafana not reachable"})
        except Exception as e:
            return json.dumps({"error": str(e)})
