"""
Cost Tracker — per-agent token usage and cost attribution.

Tracks input tokens, output tokens, and estimated cost per agent
per invocation. Enables cost governance: budget envelopes, alerts,
and per-agent cost dashboards.

Token costs (approximate, April 2026):
  Opus 4.6:  $0.015/1K input, $0.075/1K output
  Sonnet 4.6: $0.003/1K input, $0.015/1K output
  Haiku 4.5:  $0.00025/1K input, $0.00125/1K output

Ref: Ch. 03 — Token Cost as Context Engineering Discipline
Ref: arXiv:2601.14470 — Tokenomics in Agentic Systems
"""

from __future__ import annotations

import time
import logging
from dataclasses import dataclass, field
from threading import Lock

logger = logging.getLogger("cost_tracker")

# Cost per 1K tokens (USD) — update as pricing changes
MODEL_COSTS = {
    "gpt-5-1": {"input": 0.010, "output": 0.030},
    "gpt-5.1": {"input": 0.010, "output": 0.030},
    "gpt-4o": {"input": 0.005, "output": 0.015},
    "opus-4.6": {"input": 0.015, "output": 0.075},
    "sonnet-4.6": {"input": 0.003, "output": 0.015},
    "haiku-4.5": {"input": 0.00025, "output": 0.00125},
    "default": {"input": 0.005, "output": 0.015},
}


@dataclass
class CostRecord:
    """Cost record for a single agent invocation."""

    agent: str
    model: str
    input_tokens: int = 0
    output_tokens: int = 0
    total_tokens: int = 0
    estimated_cost_usd: float = 0.0
    timestamp: float = field(default_factory=time.time)
    trajectory_id: str = ""


class CostTracker:
    """Tracks token usage and cost per agent."""

    def __init__(self, monthly_budget_usd: float = 1000.0) -> None:
        self._records: list[CostRecord] = []
        self._lock = Lock()
        self._monthly_budget = monthly_budget_usd
        self._budget_alerts_sent: set[str] = set()

    def record(
        self,
        agent: str,
        model: str,
        input_tokens: int,
        output_tokens: int,
        trajectory_id: str = "",
    ) -> CostRecord:
        """Record token usage for an agent invocation."""
        costs = MODEL_COSTS.get(model, MODEL_COSTS["default"])
        cost = (input_tokens * costs["input"] / 1000) + (output_tokens * costs["output"] / 1000)

        record = CostRecord(
            agent=agent,
            model=model,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            total_tokens=input_tokens + output_tokens,
            estimated_cost_usd=round(cost, 6),
            trajectory_id=trajectory_id,
        )

        with self._lock:
            self._records.append(record)

        logger.info(
            "Cost: agent=%s model=%s tokens=%d (in=%d out=%d) cost=$%.4f",
            agent, model, record.total_tokens,
            input_tokens, output_tokens, cost,
        )

        self._check_budget(agent)
        return record

    def get_agent_summary(self, agent: str) -> dict:
        """Get cost summary for a specific agent."""
        with self._lock:
            agent_records = [r for r in self._records if r.agent == agent]

        if not agent_records:
            return {"agent": agent, "invocations": 0, "total_cost_usd": 0}

        return {
            "agent": agent,
            "invocations": len(agent_records),
            "total_tokens": sum(r.total_tokens for r in agent_records),
            "total_input_tokens": sum(r.input_tokens for r in agent_records),
            "total_output_tokens": sum(r.output_tokens for r in agent_records),
            "total_cost_usd": round(sum(r.estimated_cost_usd for r in agent_records), 4),
            "avg_tokens_per_invocation": sum(r.total_tokens for r in agent_records) // len(agent_records),
            "avg_cost_per_invocation": round(
                sum(r.estimated_cost_usd for r in agent_records) / len(agent_records), 6
            ),
        }

    def get_summary(self) -> dict:
        """Get cost summary across all agents."""
        with self._lock:
            all_records = list(self._records)

        if not all_records:
            return {"total_invocations": 0, "total_cost_usd": 0, "by_agent": {}}

        by_agent: dict[str, float] = {}
        by_model: dict[str, float] = {}
        for r in all_records:
            by_agent[r.agent] = by_agent.get(r.agent, 0) + r.estimated_cost_usd
            by_model[r.model] = by_model.get(r.model, 0) + r.estimated_cost_usd

        total_cost = sum(r.estimated_cost_usd for r in all_records)

        return {
            "total_invocations": len(all_records),
            "total_tokens": sum(r.total_tokens for r in all_records),
            "total_cost_usd": round(total_cost, 4),
            "monthly_budget_usd": self._monthly_budget,
            "budget_utilization_pct": round(total_cost / self._monthly_budget * 100, 1) if self._monthly_budget else 0,
            "by_agent": {k: round(v, 4) for k, v in sorted(by_agent.items(), key=lambda x: -x[1])},
            "by_model": {k: round(v, 4) for k, v in sorted(by_model.items(), key=lambda x: -x[1])},
        }

    def _check_budget(self, agent: str) -> None:
        """Check if agent is approaching budget limits."""
        with self._lock:
            total_cost = sum(r.estimated_cost_usd for r in self._records)

        utilization = total_cost / self._monthly_budget if self._monthly_budget else 0

        if utilization >= 0.8 and "80pct" not in self._budget_alerts_sent:
            logger.warning(
                "BUDGET ALERT: 80%% utilization reached ($%.2f / $%.2f). Last agent: %s",
                total_cost, self._monthly_budget, agent,
            )
            self._budget_alerts_sent.add("80pct")

        if utilization >= 1.0 and "100pct" not in self._budget_alerts_sent:
            logger.error(
                "BUDGET EXCEEDED: $%.2f / $%.2f (%.0f%%). Last agent: %s",
                total_cost, self._monthly_budget, utilization * 100, agent,
            )
            self._budget_alerts_sent.add("100pct")


# Global singleton
cost_tracker = CostTracker()
