"""
Copilot Metrics Collector — GitHub Copilot Billing & Usage APIs

Collects:
- Org billing: seats, active, inactive, pending
- Copilot metrics: acceptances, suggestions, lines accepted (per day)
- Plan features: IDE chat, CLI, platform chat
"""

import httpx
import logging
from datetime import datetime

logger = logging.getLogger("collector.copilot")

GITHUB_API = "https://api.github.com"


async def collect_copilot_billing(org: str, token: str) -> dict:
    """Fetch Copilot billing/seat data for the organization."""
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    async with httpx.AsyncClient(timeout=30) as client:
        try:
            res = await client.get(f"{GITHUB_API}/orgs/{org}/copilot/billing", headers=headers)
            if res.status_code == 200:
                data = res.json()
                seats = data.get("seat_breakdown", {})
                return {
                    "collected_at": datetime.utcnow().isoformat(),
                    "total_seats": seats.get("total", 0),
                    "active_this_cycle": seats.get("active_this_cycle", 0),
                    "inactive_this_cycle": seats.get("inactive_this_cycle", 0),
                    "pending_invitation": seats.get("pending_invitation", 0),
                    "added_this_cycle": seats.get("added_this_cycle", 0),
                    "plan_type": data.get("plan_type", "unknown"),
                    "ide_chat": data.get("ide_chat", "unknown"),
                    "cli": data.get("cli", "unknown"),
                    "platform_chat": data.get("platform_chat", "unknown"),
                    "public_code_suggestions": data.get("public_code_suggestions", "unknown"),
                }
            logger.warning("Copilot billing API returned %d", res.status_code)
            return {"error": f"HTTP {res.status_code}", "collected_at": datetime.utcnow().isoformat()}
        except Exception as e:
            logger.error("Failed to fetch Copilot billing: %s", e)
            return {"error": str(e), "collected_at": datetime.utcnow().isoformat()}


async def collect_copilot_metrics(org: str, token: str, days: int = 28) -> dict:
    """Fetch Copilot usage metrics (acceptances, suggestions, lines) per day."""
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    async with httpx.AsyncClient(timeout=30) as client:
        try:
            res = await client.get(
                f"{GITHUB_API}/orgs/{org}/copilot/metrics?per_page={days}", headers=headers
            )
            if res.status_code == 200:
                metrics = res.json()
                if not isinstance(metrics, list) or len(metrics) == 0:
                    return {"available": False, "collected_at": datetime.utcnow().isoformat()}

                total_acceptances = 0
                total_suggestions = 0
                total_lines = 0
                daily = []
                for day in metrics:
                    acc = day.get("copilot_ide_code_completions", {}).get("total_code_acceptances", 0)
                    sug = day.get("copilot_ide_code_completions", {}).get("total_code_suggestions", 0)
                    lines = day.get("copilot_ide_code_completions", {}).get("total_code_lines_accepted", 0)
                    total_acceptances += acc
                    total_suggestions += sug
                    total_lines += lines
                    daily.append({"date": day.get("date", ""), "acceptances": acc, "suggestions": sug, "lines": lines})

                acceptance_rate = round((total_acceptances / total_suggestions * 100), 1) if total_suggestions > 0 else 0

                return {
                    "available": True,
                    "collected_at": datetime.utcnow().isoformat(),
                    "period_days": len(metrics),
                    "total_acceptances": total_acceptances,
                    "total_suggestions": total_suggestions,
                    "total_lines_accepted": total_lines,
                    "acceptance_rate": acceptance_rate,
                    "daily": daily,
                }
            logger.warning("Copilot metrics API returned %d", res.status_code)
            return {"available": False, "collected_at": datetime.utcnow().isoformat()}
        except Exception as e:
            logger.error("Failed to fetch Copilot metrics: %s", e)
            return {"available": False, "error": str(e), "collected_at": datetime.utcnow().isoformat()}
