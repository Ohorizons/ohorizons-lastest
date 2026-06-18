"""
Middleware module for Open Horizons Agent API.

Provides cross-cutting concerns for the agentic execution layer:
  - Trajectory logging (every tool call, decision, outcome)
  - Per-agent cost tracking (token usage attribution)
  - Pre/post tool-use governance hooks (validate, block, redact)
"""

from middleware.trajectory import TrajectoryLogger, trajectory_logger
from middleware.cost_tracker import CostTracker, cost_tracker
from middleware.hooks import ToolHookPipeline, tool_hooks

__all__ = [
    "TrajectoryLogger",
    "trajectory_logger",
    "CostTracker",
    "cost_tracker",
    "ToolHookPipeline",
    "tool_hooks",
]
