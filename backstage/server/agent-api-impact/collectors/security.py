"""
Security Collector — GitHub Advanced Security APIs

Collects:
- Dependabot alerts (vulnerability severity counts)
- Code scanning alerts (CodeQL findings)
- Secret scanning alerts
"""

import httpx
import logging
from datetime import datetime

logger = logging.getLogger("collector.security")

GITHUB_API = "https://api.github.com"


async def collect_security_posture(org: str, repo: str, token: str) -> dict:
    """Collect security posture from GHAS APIs."""
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}

    async with httpx.AsyncClient(timeout=30) as client:
        result = {
            "collected_at": datetime.utcnow().isoformat(),
            "repo": f"{org}/{repo}",
            "dependabot": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0},
            "code_scanning": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0},
            "code_quality": {
                "maintainability": 0,
                "reliability": 0,
                "correctness": 0,
                "total": 0,
                "autofix_available": 0,
            },
            "secret_scanning": {"count": 0},
            "features": {"dependabot": "unknown", "code_scanning": "unknown", "secret_scanning": "unknown"},
        }

        # Dependabot
        try:
            res = await client.get(
                f"{GITHUB_API}/repos/{org}/{repo}/dependabot/alerts?state=open&per_page=100",
                headers=headers,
            )
            if res.status_code == 200:
                result["features"]["dependabot"] = "enabled"
                alerts = res.json()
                for a in alerts:
                    sev = a.get("security_vulnerability", {}).get("severity", "low")
                    if sev in result["dependabot"]:
                        result["dependabot"][sev] += 1
                result["dependabot"]["total"] = len(alerts)
            elif res.status_code == 403:
                result["features"]["dependabot"] = "disabled"
        except Exception as e:
            logger.warning("Dependabot fetch failed: %s", e)

        # Code Scanning
        try:
            res = await client.get(
                f"{GITHUB_API}/repos/{org}/{repo}/code-scanning/alerts?state=open&per_page=100",
                headers=headers,
            )
            if res.status_code == 200:
                result["features"]["code_scanning"] = "enabled"
                alerts = res.json()
                for a in alerts:
                    rule = a.get("rule", {})
                    sev = rule.get("security_severity_level")
                    if sev and sev in result["code_scanning"]:
                        result["code_scanning"][sev] += 1
                    if not sev:
                        tags = rule.get("tags", []) or []
                        is_quality_alert = any(
                            tag in [
                                "quality",
                                "maintainability",
                                "reliability",
                                "correctness",
                                "performance",
                                "style",
                            ]
                            for tag in tags
                        )
                        if is_quality_alert:
                            result["code_quality"]["total"] += 1
                            if "maintainability" in tags:
                                result["code_quality"]["maintainability"] += 1
                            if "reliability" in tags:
                                result["code_quality"]["reliability"] += 1
                            if "correctness" in tags:
                                result["code_quality"]["correctness"] += 1

                    if a.get("most_recent_instance", {}).get("fix_available"):
                        result["code_quality"]["autofix_available"] += 1

                result["code_scanning"]["total"] = sum(
                    result["code_scanning"][severity]
                    for severity in ["critical", "high", "medium", "low"]
                )
            elif res.status_code in (403, 404):
                result["features"]["code_scanning"] = "disabled"
        except Exception as e:
            logger.warning("Code scanning fetch failed: %s", e)

        # Secret Scanning
        try:
            res = await client.get(
                f"{GITHUB_API}/repos/{org}/{repo}/secret-scanning/alerts?state=open&per_page=100",
                headers=headers,
            )
            if res.status_code == 200:
                result["features"]["secret_scanning"] = "enabled"
                data = res.json()
                result["secret_scanning"]["count"] = len(data) if isinstance(data, list) else 0
            elif res.status_code in (403, 404):
                result["features"]["secret_scanning"] = "disabled"
        except Exception as e:
            logger.warning("Secret scanning fetch failed: %s", e)

        total_vulns = result["dependabot"]["total"] + result["code_scanning"]["total"] + result["secret_scanning"]["count"]
        result["total_open_issues"] = total_vulns
        result["risk_level"] = "critical" if result["dependabot"]["critical"] + result["code_scanning"]["critical"] > 0 else \
                               "high" if result["dependabot"]["high"] + result["code_scanning"]["high"] > 0 else \
                               "medium" if total_vulns > 10 else "low"

        return result
