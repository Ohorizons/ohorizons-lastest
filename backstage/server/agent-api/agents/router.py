"""
Agent Router — Detects which agent should handle a message.

3-agent system: Pipeline, Sentinel, Compass.
Uses @mention detection (highest priority), then keyword matching,
then falls back to the orchestrator (general assistant).
"""

from __future__ import annotations

import re
import logging

logger = logging.getLogger("router")

# @mention → agent name
MENTION_MAP: dict[str, str] = {
    "@pipeline": "pipeline",
    "@sentinel": "sentinel",
    "@compass": "compass",
    "@guardian": "guardian",
    "@lighthouse": "lighthouse",
    "@forge": "forge",
}

# Agent name → trigger keywords
KEYWORD_MAP: dict[str, list[str]] = {
    "pipeline": [
        "pipeline", "ci/cd", "cicd", "build fail", "workflow fail",
        "action fail", "deploy fail", "github action", "workflow run",
        "build error", "pipeline error", "diagnose pipeline",
        "runbook", "failure history", "build", "deploy",
    ],
    "sentinel": [
        "test", "coverage", "unit test", "integration test",
        "e2e test", "test plan", "uncovered", "test gap",
        "coverage report", "coverage diff", "testing",
        "quality gate", "test code", "check run",
    ],
    "compass": [
        "epic", "user story", "stories", "decompose",
        "sprint planning", "planning", "requirements",
        "acceptance criteria", "backlog", "invest",
        "issue", "create issue", "task",
    ],
    "guardian": [
        "security", "vulnerability", "cve", "dependabot",
        "secret", "secret scanning", "code scanning", "ghas",
        "advisory", "compliance", "sbom", "supply chain",
        "exploit", "patch", "scan security",
    ],
    "lighthouse": [
        "alert", "alerting", "monitor", "monitoring", "observability",
        "sre", "incident", "metrics", "grafana", "prometheus",
        "dashboard", "health", "latency", "uptime",
        "deploy status", "rollback", "environment",
    ],
    "forge": [
        "kubernetes", "k8s", "pod", "pods", "namespace",
        "cluster", "node", "infra", "infrastructure",
        "repo", "repos", "repository", "branch", "branches",
        "tag", "release", "container", "docker", "helm", "terraform",
    ],
}

AGENT_DISPLAY_NAMES: dict[str, str] = {
    "pipeline": "Pipeline — CI/CD Diagnostics",
    "sentinel": "Sentinel — Test & Coverage",
    "compass": "Compass — Planning & Stories",
    "guardian": "Guardian — Security & Compliance",
    "lighthouse": "Lighthouse — Observability & SRE",
    "forge": "Forge — Infrastructure & Cloud",
    "orchestrator": "Open Horizons Assistant",
}


def detect_agent(message: str) -> str:
    """Detect which agent should handle this message.

    Priority:
      1. Explicit @mention
      2. Keyword match (first match wins)
      3. Default to orchestrator
    """
    msg = message.lower().strip()

    # 1. Explicit @mention
    for mention, agent_name in MENTION_MAP.items():
        if mention in msg:
            logger.info("Routed to %s via @mention", agent_name)
            return agent_name

    # 2. Keyword detection
    for agent_name, keywords in KEYWORD_MAP.items():
        for kw in keywords:
            if kw in msg:
                logger.info("Routed to %s via keyword '%s'", agent_name, kw)
                return agent_name

    # 3. Default
    logger.info("No agent match — using orchestrator")
    return "orchestrator"


def strip_mention(message: str) -> str:
    """Remove @mention prefix from a message."""
    return re.sub(r"@\w+\s*", "", message).strip()


def get_all_agent_names() -> list[str]:
    """Return all registered agent names."""
    return list(MENTION_MAP.values()) + ["orchestrator"]
