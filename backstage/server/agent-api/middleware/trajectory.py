"""
Trajectory Logger — records every step of agent reasoning.

A trajectory is the complete sequence of:
  intent → context_snapshot → tool_calls → decisions → outcome

This is NOT standard application logging. Trajectory logging captures
the agent's reasoning path so that when an agent misbehaves, you can
replay its trajectory to understand WHY.

Ref: Ch. 05 — Observability for Agent Trajectories
Ref: arXiv:2604.02547 — Behavioral Drivers of Coding Agent Success
"""

from __future__ import annotations

import time
import uuid
import logging
from dataclasses import dataclass, field

logger = logging.getLogger("trajectory")


@dataclass
class TrajectoryStep:
    """A single step in an agent trajectory."""

    step_id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    timestamp: float = field(default_factory=time.time)
    step_type: str = ""  # "intent", "context", "tool_call", "tool_result", "decision", "output"
    agent: str = ""
    content: str = ""
    metadata: dict = field(default_factory=dict)


@dataclass
class Trajectory:
    """Complete trajectory for one agent invocation."""

    trajectory_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    agent: str = ""
    user: str = ""
    started_at: float = field(default_factory=time.time)
    finished_at: float | None = None
    steps: list[TrajectoryStep] = field(default_factory=list)
    outcome: str = ""  # "success", "error", "timeout"
    token_usage: dict = field(default_factory=dict)

    @property
    def duration_seconds(self) -> float | None:
        if self.finished_at is None:
            return None
        return self.finished_at - self.started_at

    @property
    def tool_call_count(self) -> int:
        return sum(1 for s in self.steps if s.step_type == "tool_call")

    @property
    def step_count(self) -> int:
        return len(self.steps)

    def to_dict(self) -> dict:
        return {
            "trajectory_id": self.trajectory_id,
            "agent": self.agent,
            "user": self.user,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "duration_seconds": self.duration_seconds,
            "step_count": self.step_count,
            "tool_call_count": self.tool_call_count,
            "outcome": self.outcome,
            "token_usage": self.token_usage,
            "steps": [
                {
                    "step_id": s.step_id,
                    "timestamp": s.timestamp,
                    "step_type": s.step_type,
                    "agent": s.agent,
                    "content": s.content[:500],  # Truncate for storage
                    "metadata": s.metadata,
                }
                for s in self.steps
            ],
        }


class TrajectoryLogger:
    """Manages trajectory recording for all agent invocations."""

    def __init__(self, max_trajectories: int = 10000) -> None:
        self._trajectories: dict[str, Trajectory] = {}
        self._max = max_trajectories

    def start(self, agent: str, user: str = "", message: str = "") -> str:
        """Start recording a new trajectory. Returns trajectory_id."""
        self._evict_if_full()
        trajectory = Trajectory(agent=agent, user=user)

        # First step: record the intent (what the user asked)
        trajectory.steps.append(TrajectoryStep(
            step_type="intent",
            agent=agent,
            content=message[:1000],
            metadata={"user": user},
        ))

        self._trajectories[trajectory.trajectory_id] = trajectory
        logger.info(
            "Trajectory started: %s agent=%s user=%s",
            trajectory.trajectory_id[:8], agent, user or "anonymous",
        )
        return trajectory.trajectory_id

    def log_context(self, trajectory_id: str, context_summary: str) -> None:
        """Log the context snapshot loaded for this invocation."""
        t = self._trajectories.get(trajectory_id)
        if t:
            t.steps.append(TrajectoryStep(
                step_type="context",
                agent=t.agent,
                content=context_summary,
            ))

    def log_tool_call(
        self,
        trajectory_id: str,
        tool_name: str,
        tool_input: dict,
    ) -> None:
        """Log an agent's tool invocation."""
        t = self._trajectories.get(trajectory_id)
        if t:
            t.steps.append(TrajectoryStep(
                step_type="tool_call",
                agent=t.agent,
                content=tool_name,
                metadata={"input": {k: str(v)[:200] for k, v in tool_input.items()}},
            ))

    def log_tool_result(
        self,
        trajectory_id: str,
        tool_name: str,
        result: str,
    ) -> None:
        """Log the result of a tool invocation."""
        t = self._trajectories.get(trajectory_id)
        if t:
            t.steps.append(TrajectoryStep(
                step_type="tool_result",
                agent=t.agent,
                content=f"{tool_name}: {result[:500]}",
            ))

    def log_decision(self, trajectory_id: str, decision: str) -> None:
        """Log an agent decision or reasoning step."""
        t = self._trajectories.get(trajectory_id)
        if t:
            t.steps.append(TrajectoryStep(
                step_type="decision",
                agent=t.agent,
                content=decision,
            ))

    def finish(
        self,
        trajectory_id: str,
        outcome: str = "success",
        token_usage: dict | None = None,
    ) -> Trajectory | None:
        """Finish recording a trajectory."""
        t = self._trajectories.get(trajectory_id)
        if t:
            t.finished_at = time.time()
            t.outcome = outcome
            t.token_usage = token_usage or {}

            logger.info(
                "Trajectory finished: %s agent=%s outcome=%s steps=%d tools=%d duration=%.1fs",
                trajectory_id[:8], t.agent, outcome,
                t.step_count, t.tool_call_count,
                t.duration_seconds or 0,
            )
            return t
        return None

    def get(self, trajectory_id: str) -> Trajectory | None:
        return self._trajectories.get(trajectory_id)

    def get_by_agent(self, agent: str, limit: int = 50) -> list[dict]:
        """Get recent trajectories for an agent (for observability dashboard)."""
        results = [
            t.to_dict()
            for t in self._trajectories.values()
            if t.agent == agent and t.finished_at is not None
        ]
        results.sort(key=lambda x: x["started_at"], reverse=True)
        return results[:limit]

    def summary(self) -> dict:
        """Return aggregate statistics for all trajectories."""
        total = len(self._trajectories)
        completed = sum(1 for t in self._trajectories.values() if t.finished_at)
        by_agent: dict[str, int] = {}
        by_outcome: dict[str, int] = {}
        total_duration = 0.0
        total_tools = 0

        for t in self._trajectories.values():
            by_agent[t.agent] = by_agent.get(t.agent, 0) + 1
            if t.finished_at:
                by_outcome[t.outcome] = by_outcome.get(t.outcome, 0) + 1
                total_duration += t.duration_seconds or 0
                total_tools += t.tool_call_count

        return {
            "total_trajectories": total,
            "completed": completed,
            "by_agent": by_agent,
            "by_outcome": by_outcome,
            "avg_duration_seconds": total_duration / completed if completed else 0,
            "avg_tool_calls": total_tools / completed if completed else 0,
        }

    def _evict_if_full(self) -> None:
        if len(self._trajectories) >= self._max:
            # Remove oldest completed trajectory
            oldest_id = None
            oldest_time = float("inf")
            for tid, t in self._trajectories.items():
                if t.finished_at and t.started_at < oldest_time:
                    oldest_time = t.started_at
                    oldest_id = tid
            if oldest_id:
                del self._trajectories[oldest_id]


# Global singleton
trajectory_logger = TrajectoryLogger()
