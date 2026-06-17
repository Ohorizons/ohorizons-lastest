"""
Pipeline & DORA Collector — GitHub Actions Workflow Runs

Collects:
- Deployment frequency
- Change failure rate
- Lead time for changes
- Mean time to recovery
"""

import httpx
import logging
from datetime import datetime, timedelta

logger = logging.getLogger("collector.pipelines")

GITHUB_API = "https://api.github.com"


async def collect_dora_metrics(org: str, repo: str, token: str, days: int = 30) -> dict:
    """Calculate DORA metrics from GitHub Actions workflow runs."""
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    since = datetime.utcnow() - timedelta(days=days)
    since_str = since.strftime("%Y-%m-%d")

    async with httpx.AsyncClient(timeout=30) as client:
        try:
            # Fetch workflow runs
            res = await client.get(
                f"{GITHUB_API}/repos/{org}/{repo}/actions/runs?per_page=100&created=%3E{since_str}",
                headers=headers,
            )
            if res.status_code != 200:
                return {"error": f"HTTP {res.status_code}", "collected_at": datetime.utcnow().isoformat()}

            runs = res.json().get("workflow_runs", [])
            completed = [r for r in runs if r.get("status") == "completed"]
            failed = [r for r in completed if r.get("conclusion") == "failure"]
            successful = [r for r in completed if r.get("conclusion") == "success"]

            # Deployment Frequency
            deploy_count = len(completed)
            deploy_per_day = round(deploy_count / max(days, 1), 2)

            # Change Failure Rate
            cfr = round(len(failed) / max(len(completed), 1) * 100, 1)

            # DORA classification
            def classify_df(per_day):
                if per_day >= 1: return "elite"
                if per_day >= 1/7: return "high"
                if per_day >= 1/30: return "medium"
                return "low"

            def classify_cfr(pct):
                if pct <= 5: return "elite"
                if pct <= 10: return "high"
                if pct <= 15: return "medium"
                return "low"

            # Weekly trend
            weekly = {}
            for r in completed:
                dt = datetime.fromisoformat(r["created_at"].replace("Z", "+00:00"))
                week_key = dt.strftime("%Y-W%U")
                weekly[week_key] = weekly.get(week_key, 0) + 1

            return {
                "collected_at": datetime.utcnow().isoformat(),
                "period_days": days,
                "repo": f"{org}/{repo}",
                "deployment_frequency": {
                    "count": deploy_count,
                    "per_day": deploy_per_day,
                    "classification": classify_df(deploy_per_day),
                },
                "change_failure_rate": {
                    "percentage": cfr,
                    "failed": len(failed),
                    "total": len(completed),
                    "classification": classify_cfr(cfr),
                },
                "weekly_trend": [{"week": k, "count": v} for k, v in sorted(weekly.items())],
                "total_successful": len(successful),
            }
        except Exception as e:
            logger.error("Failed to collect DORA metrics: %s", e)
            return {"error": str(e), "collected_at": datetime.utcnow().isoformat()}
