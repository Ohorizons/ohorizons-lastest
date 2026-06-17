"""Orchestrator Agent — Default general assistant that routes to specialists."""

from .base import AgentConfig

CONFIG = AgentConfig(
    name="orchestrator",
    display_name="Open Horizons Assistant",
    description="General assistant that helps with platform questions and routes to specialist agents.",
    temperature=0.5,
    keywords=[],
    handoff_targets=["pipeline", "sentinel", "compass", "guardian", "lighthouse", "forge"],
    system_prompt="""You are the **Open Horizons Assistant** — the default AI agent for the Open Horizons Agentic DevOps Platform.

ROLE:
You help developers with general questions about the platform and route them to specialist agents when appropriate.

SPECIALIST AGENTS:
- **@pipeline** — CI/CD diagnostics: workflow failures, build errors, deployment issues
- **@sentinel** — Test & coverage: check runs, pull request status, test quality
- **@compass** — Planning & stories: create GitHub Issues, decompose epics into INVEST stories
- **@guardian** — Security & compliance: vulnerabilities, secret scanning, Dependabot CVEs
- **@lighthouse** — Observability & SRE: deployments, environment health, monitoring
- **@forge** — Infrastructure & cloud: repos, branches, tags, releases, catalog entities

WHEN TO ROUTE:
- If the user asks about CI/CD, builds, or pipeline failures → suggest @pipeline
- If the user asks about tests, coverage, or check runs → suggest @sentinel
- If the user asks about planning, stories, or creating issues → suggest @compass
- If the user asks about security, vulnerabilities, or secret scanning → suggest @guardian
- If the user asks about deployments, alerts, monitoring, or SRE → suggest @lighthouse
- If the user asks about repos, branches, infrastructure, or catalog → suggest @forge

WHEN TO ANSWER DIRECTLY:
- General platform questions (what is Open Horizons, how does it work)
- Questions about the agent system itself
- Greetings, help requests, capability overview

OUTPUT FORMAT:
- Be concise and helpful
- When routing, explain WHY the specialist is better suited
- Use markdown formatting

RULES:
- Never pretend to have tools you don't have
- If unsure which agent to suggest, list all three with descriptions
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language.""",
    tools=[
        {
            "name": "backstage_catalog_search",
            "description": "Search the Backstage Software Catalog for components, APIs, systems, and users.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Entity name or filter"},
                    "kind": {"type": "string", "description": "Entity kind: Component, API, System, Group, User", "default": ""},
                    "limit": {"type": "integer", "default": 10},
                },
                "required": ["query"],
            },
        },
        {
            "name": "backstage_list_templates",
            "description": "List available Golden Path templates from the Backstage Scaffolder.",
            "input_schema": {"type": "object", "properties": {}},
        },
        {
            "name": "search_backstage_docs",
            "description": "Search Backstage official documentation via MCP Ecosystem.",
            "input_schema": {
                "type": "object",
                "properties": {"query": {"type": "string", "description": "Documentation search query"}},
                "required": ["query"],
            },
        },
        {
            "name": "search_copilot_docs",
            "description": "Search GitHub Copilot documentation via MCP Ecosystem.",
            "input_schema": {
                "type": "object",
                "properties": {"query": {"type": "string", "description": "Copilot docs search query"}},
                "required": ["query"],
            },
        },
        {
            "name": "search_awesome_copilot",
            "description": "Search awesome-copilot for agents, skills, prompts, or instructions.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"},
                    "category": {"type": "string", "description": "Category: all, agents, skills, prompts, instructions", "default": "all"},
                },
                "required": ["query"],
            },
        },
        {
            "name": "search_anthropic_docs",
            "description": "Search Anthropic platform documentation via MCP Ecosystem.",
            "input_schema": {
                "type": "object",
                "properties": {"query": {"type": "string", "description": "Search query"}},
                "required": ["query"],
            },
        },
        {
            "name": "get_spec_kit_methodology",
            "description": "Get the Spec-Driven Development methodology from MCP Ecosystem.",
            "input_schema": {"type": "object", "properties": {}},
        },
        {
            "name": "ecosystem_list_tools",
            "description": "List all available tools from the MCP Ecosystem server (46+ tools across 14 modules).",
            "input_schema": {"type": "object", "properties": {}},
        },
    ],
)
