"""
KPI Engine — Calculates AI Impact KPIs from collected metrics.

Takes raw collector data and produces structured KPIs for the dashboard.
"""

import logging
from datetime import datetime

logger = logging.getLogger("analyzers.kpi_engine")


def calculate_impact_summary(
    copilot_billing: dict,
    copilot_metrics: dict,
    org_activity: dict,
    dora: dict,
    security: dict,
) -> dict:
    """Calculate consolidated AI Impact KPIs from all collected data."""

    # Copilot Adoption
    total_seats = copilot_billing.get("total_seats", 0)
    active_seats = copilot_billing.get("active_this_cycle", 0)
    adoption_rate = round(active_seats / max(total_seats, 1) * 100, 1)

    # Copilot Productivity
    acceptance_rate = copilot_metrics.get("acceptance_rate", 0)
    total_suggestions = copilot_metrics.get("total_suggestions", 0)
    total_acceptances = copilot_metrics.get("total_acceptances", 0)
    total_lines = copilot_metrics.get("total_lines_accepted", 0)

    # Developer Velocity
    avg_merge_time = org_activity.get("avg_merge_time_hours", 0)
    merge_rate = org_activity.get("merge_rate_pct", 0)
    contributors = org_activity.get("unique_contributors", 0)

    # DORA
    deploy_freq = dora.get("deployment_frequency", {}).get("per_day", 0)
    deploy_class = dora.get("deployment_frequency", {}).get("classification", "low")
    cfr = dora.get("change_failure_rate", {}).get("percentage", 0)
    cfr_class = dora.get("change_failure_rate", {}).get("classification", "low")

    # Security
    risk_level = security.get("risk_level", "unknown")
    total_vulns = security.get("total_open_issues", 0)

    # Estimated ROI (simplified: accepted suggestions * avg dev hourly cost savings)
    # Assumption: each accepted suggestion saves ~30 seconds of dev time
    estimated_hours_saved = round(total_acceptances * 0.5 / 60, 1)  # 30 sec per acceptance
    estimated_cost_saved = round(estimated_hours_saved * 75, 0)  # $75/hr avg dev cost

    # AI Impact Score (0-100, weighted composite)
    score_adoption = min(adoption_rate, 100) * 0.2
    score_acceptance = min(acceptance_rate, 100) * 0.25
    score_velocity = min(merge_rate, 100) * 0.2
    score_dora = {"elite": 25, "high": 20, "medium": 12, "low": 5}.get(deploy_class, 5)
    score_security = {"low": 10, "medium": 6, "high": 3, "critical": 0, "unknown": 5}.get(risk_level, 5)
    ai_impact_score = round(score_adoption + score_acceptance + score_velocity + score_dora + score_security)

    return {
        "calculated_at": datetime.utcnow().isoformat(),
        "ai_impact_score": ai_impact_score,
        "adoption": {
            "total_seats": total_seats,
            "active_seats": active_seats,
            "adoption_rate": adoption_rate,
            "plan_type": copilot_billing.get("plan_type", "unknown"),
        },
        "productivity": {
            "acceptance_rate": acceptance_rate,
            "total_suggestions": total_suggestions,
            "total_acceptances": total_acceptances,
            "total_lines_accepted": total_lines,
            "estimated_hours_saved": estimated_hours_saved,
            "estimated_cost_saved_usd": estimated_cost_saved,
        },
        "velocity": {
            "avg_merge_time_hours": avg_merge_time,
            "merge_rate_pct": merge_rate,
            "unique_contributors": contributors,
            "deploy_frequency_per_day": deploy_freq,
            "deploy_classification": deploy_class,
        },
        "quality": {
            "change_failure_rate": cfr,
            "cfr_classification": cfr_class,
            "risk_level": risk_level,
            "total_vulnerabilities": total_vulns,
        },
    }
