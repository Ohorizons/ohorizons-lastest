"""Agent Router — @mention → keyword → orchestrator."""

from __future__ import annotations

import re
import logging

logger = logging.getLogger("router")

MENTION_MAP: dict[str, str] = {
    "@pipeline": "pipeline",
    "@sentinel": "sentinel",
    "@compass": "compass",
    "@guardian": "guardian",
    "@lighthouse": "lighthouse",
    "@forge": "forge",
}

KEYWORD_MAP: dict[str, list[str]] = {
    "guardian": [
        "security", "vulnerability", "CVE", "dependabot", "compliance",
        "SBOM", "secret scan", "code scan", "CodeQL", "SAST",
        "supply chain", "license", "advisory", "patch", "exposed secret",
    ],
    "lighthouse": [
        "alert", "metrics", "latency", "logs", "incident", "SLO",
        "uptime", "prometheus", "grafana", "monitoring", "observability",
        "dashboard", "scrape", "target", "firing", "health check",
    ],
    "forge": [
        "kubernetes", "k8s", "cluster", "infra", "infrastructure",
        "namespace", "pod", "deployment", "service", "node",
        "replica", "scale", "rollout", "event", "kubectl",
        "container", "restart", "crash", "oom", "pending",
    ],
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
    msg = message.lower().strip()
    for mention, agent_name in MENTION_MAP.items():
        if mention in msg:
            return agent_name
    for agent_name, keywords in KEYWORD_MAP.items():
        for kw in keywords:
            if kw in msg:
                return agent_name
    return "orchestrator"


def strip_mention(message: str) -> str:
    return re.sub(r"@\w+\s*", "", message).strip()
