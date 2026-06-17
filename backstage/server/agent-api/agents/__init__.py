"""Agent registry — loads and exposes all agents."""

from .base import BaseAgent, AgentConfig
from .pipeline import CONFIG as pipeline_config
from .sentinel import CONFIG as sentinel_config
from .compass import CONFIG as compass_config
from .guardian import CONFIG as guardian_config
from .lighthouse import CONFIG as lighthouse_config
from .forge import CONFIG as forge_config
from .orchestrator import CONFIG as orchestrator_config

AGENT_CONFIGS: dict[str, AgentConfig] = {
    "pipeline": pipeline_config,
    "sentinel": sentinel_config,
    "compass": compass_config,
    "guardian": guardian_config,
    "lighthouse": lighthouse_config,
    "forge": forge_config,
    "orchestrator": orchestrator_config,
}


def create_agent(name: str, tool_executor) -> BaseAgent:
    """Create an agent instance by name."""
    config = AGENT_CONFIGS.get(name)
    if not config:
        raise ValueError(f"Unknown agent: {name}")
    return BaseAgent(config=config, tool_executor=tool_executor)


def get_agent_config(name: str) -> AgentConfig | None:
    """Get agent config by name."""
    return AGENT_CONFIGS.get(name)
