"""
Security Plugin — GitHub Security API tools as Semantic Kernel functions.

Covers: Dependabot alerts, Code Scanning alerts, Secret Scanning alerts.
"""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from dotenv import load_dotenv
from semantic_kernel.functions import kernel_function

load_dotenv()

logger = logging.getLogger("plugins.security")

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_API = "https://api.github.com"
GITHUB_OWNER = os.getenv("GITHUB_OWNER", "Ohorizons")


def _headers() -> dict[str, str]:
    h = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    if GITHUB_TOKEN:
        h["Authorization"] = f"Bearer {GITHUB_TOKEN}"
    return h


async def _get(path: str, params: dict | None = None) -> Any:
    url = f"{GITHUB_API}{path}"
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(url, headers=_headers(), params=params or {})
        if r.status_code == 200:
            return r.json()
        return {"error": f"GitHub API {r.status_code}", "message": r.text[:300]}


class SecurityPlugin:
    """GitHub Security API tools for the Guardian agent."""

    @kernel_function(
        name="get_dependabot_alerts",
        description="List Dependabot vulnerability alerts for a repository. Shows CVEs, severity, and affected packages.",
    )
    async def get_dependabot_alerts(
        self,
        repo: Annotated[str, "Repository name"],
        state: Annotated[str, "Alert state: open, dismissed, fixed, auto_dismissed"] = "open",
        severity: Annotated[str, "Filter by severity: low, medium, high, critical"] = "",
        per_page: Annotated[int, "Number of alerts to return"] = 10,
    ) -> str:
        params: dict[str, Any] = {"state": state, "per_page": per_page}
        if severity:
            params["severity"] = severity

        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/dependabot/alerts", params)
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        alerts = []
        for alert in data[:per_page]:
            vuln = alert.get("security_vulnerability", {})
            alerts.append({
                "number": alert.get("number"),
                "state": alert.get("state"),
                "severity": vuln.get("severity"),
                "package": vuln.get("package", {}).get("name"),
                "ecosystem": vuln.get("package", {}).get("ecosystem"),
                "vulnerable_range": vuln.get("vulnerable_version_range"),
                "patched_version": vuln.get("first_patched_version", {}).get("identifier"),
                "summary": alert.get("security_advisory", {}).get("summary", "")[:200],
                "cve_id": alert.get("security_advisory", {}).get("cve_id"),
                "html_url": alert.get("html_url"),
                "created_at": alert.get("created_at"),
            })
        return json.dumps({"alerts": alerts, "total": len(alerts)})

    @kernel_function(
        name="get_code_scanning_alerts",
        description="List code scanning (CodeQL/SAST) alerts for a repository. Shows security issues found in source code.",
    )
    async def get_code_scanning_alerts(
        self,
        repo: Annotated[str, "Repository name"],
        state: Annotated[str, "Alert state: open, dismissed, fixed"] = "open",
        severity: Annotated[str, "Filter by severity: error, warning, note"] = "",
        per_page: Annotated[int, "Number of alerts to return"] = 10,
    ) -> str:
        params: dict[str, Any] = {"state": state, "per_page": per_page}
        if severity:
            params["severity"] = severity

        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/code-scanning/alerts", params)
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        alerts = []
        for alert in data[:per_page]:
            rule = alert.get("rule", {})
            location = alert.get("most_recent_instance", {}).get("location", {})
            alerts.append({
                "number": alert.get("number"),
                "state": alert.get("state"),
                "severity": rule.get("security_severity_level"),
                "rule_id": rule.get("id"),
                "rule_description": rule.get("description", "")[:200],
                "tool": alert.get("tool", {}).get("name"),
                "file": location.get("path"),
                "start_line": location.get("start_line"),
                "html_url": alert.get("html_url"),
                "created_at": alert.get("created_at"),
            })
        return json.dumps({"alerts": alerts, "total": len(alerts)})

    @kernel_function(
        name="get_secret_scanning_alerts",
        description="List secret scanning alerts for a repository. Shows exposed secrets and credentials found in code.",
    )
    async def get_secret_scanning_alerts(
        self,
        repo: Annotated[str, "Repository name"],
        state: Annotated[str, "Alert state: open, resolved"] = "open",
        per_page: Annotated[int, "Number of alerts to return"] = 10,
    ) -> str:
        params: dict[str, Any] = {"state": state, "per_page": per_page}

        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/secret-scanning/alerts", params)
        if isinstance(data, dict) and "error" in data:
            return json.dumps(data)

        alerts = []
        for alert in data[:per_page]:
            alerts.append({
                "number": alert.get("number"),
                "state": alert.get("state"),
                "secret_type": alert.get("secret_type_display_name"),
                "resolution": alert.get("resolution"),
                "resolved_by": alert.get("resolved_by", {}).get("login") if alert.get("resolved_by") else None,
                "html_url": alert.get("html_url"),
                "created_at": alert.get("created_at"),
                "push_protection_bypassed": alert.get("push_protection_bypassed"),
            })
        return json.dumps({"alerts": alerts, "total": len(alerts)})

    @kernel_function(
        name="get_repo_security_overview",
        description="Get a security overview for a repository: vulnerability alerts count, security features status.",
    )
    async def get_repo_security_overview(
        self,
        repo: Annotated[str, "Repository name"],
    ) -> str:
        # Fetch counts in parallel-style (sequential for simplicity)
        dependabot = await _get(f"/repos/{GITHUB_OWNER}/{repo}/dependabot/alerts", {"state": "open", "per_page": 1})
        code_scan = await _get(f"/repos/{GITHUB_OWNER}/{repo}/code-scanning/alerts", {"state": "open", "per_page": 1})
        secrets = await _get(f"/repos/{GITHUB_OWNER}/{repo}/secret-scanning/alerts", {"state": "open", "per_page": 1})

        def _count(data: Any) -> int | str:
            if isinstance(data, list):
                return len(data)
            if isinstance(data, dict) and "error" in data:
                return data.get("message", "unavailable")[:100]
            return 0

        return json.dumps({
            "repo": repo,
            "dependabot_open": _count(dependabot),
            "code_scanning_open": _count(code_scan),
            "secret_scanning_open": _count(secrets),
        })
