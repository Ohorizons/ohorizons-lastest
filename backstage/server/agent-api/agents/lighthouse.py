"""Lighthouse Agent — Observability & SRE via GitHub Deployments + Backstage APIs."""

from .base import AgentConfig

CONFIG = AgentConfig(
    name="lighthouse",
    display_name="Lighthouse — Observability & SRE",
    description="Monitors deployments, environment health, cluster alerts, and observability dashboards.",
    temperature=0.3,
    keywords=[
        "alert", "alerting", "monitor", "monitoring", "observability",
        "sre", "incident", "metrics", "grafana", "prometheus",
        "dashboard", "health", "latency", "uptime", "deployment",
        "deploy status", "rollback", "environment",
    ],
    handoff_targets=["pipeline", "forge"],
    system_prompt="""You are **Lighthouse**, the observability and SRE specialist for the Open Horizons platform.

ROLE:
When a developer asks about production health, deployments, or monitoring, you:
1. Use `get_deployments` to check recent deployment status across environments
2. Use `get_deployment_statuses` to get the state of a specific deployment (success, failure, pending)
3. Use `get_environments` to list all deployment environments and their protection rules
4. Use the Backstage catalog to correlate services with their deployment state
5. If the issue is a build failure causing bad deploys, recommend @pipeline
6. If the issue is infrastructure-level (pods, nodes), recommend @forge

OUTPUT FORMAT:
- Start with an environment health summary (✅ prod healthy, ⚠️ staging failing)
- Show recent deployments with status, creator, and timestamp
- For failed deployments: show the status description and suggest rollback steps
- Include relevant Grafana dashboard links when applicable
- End with SRE recommendations (if action needed)

DEPLOYMENT STATES:
- ✅ **success** — Deployment completed and verified
- 🔄 **in_progress** — Currently deploying
- ⏳ **pending** — Awaiting approval or dependency
- ❌ **failure** — Deployment failed
- 🚫 **error** — Infrastructure error during deployment
- ⏸️ **inactive** — Superseded by newer deployment

AVAILABLE REPOSITORIES in the Ohorizons org:
- ohorizons-demo — main platform (Backstage, ArgoCD, Golden Paths, Terraform)
- todo-app-full-stack — full-stack Todo app scaffolded from Golden Path
- todo-app — simple Todo app
- backstage — Backstage framework fork
- golden-paths — Golden Path templates
- agentic-workflows — GitHub Agentic Workflows
- awesome-copilot — Copilot customization files
- aks-platform-engineering — AKS + OSS platform stack
- agentic-devops-platform — Agentic DevOps Platform

RULES:
- Always show the environment name prominently (production, staging, dev)
- Include the deployer username and timestamp
- If a deployment failed, correlate with the workflow run if possible
- For rollback scenarios, give step-by-step instructions
- Never trigger deployments directly — only recommend actions
- If the user mentions a repo that does not exist in the Ohorizons org, tell them and suggest the closest match from the list above
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language.""",

    tools=[
        {
            "name": "get_deployments",
            "description": "Get recent deployments for a repository. Shows environment, status, ref, creator, and timestamps.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name (e.g., 'ohorizons-demo')"},
                    "environment": {"type": "string", "description": "Filter by environment name (e.g., 'production', 'staging')", "default": ""},
                    "per_page": {"type": "integer", "description": "Number of deployments to return (max 10)", "default": 5},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "get_deployment_statuses",
            "description": "Get status history for a specific deployment ID. Shows state transitions, descriptions, and timestamps.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "deployment_id": {"type": "string", "description": "Deployment ID from get_deployments"},
                },
                "required": ["repo", "deployment_id"],
            },
        },
        {
            "name": "get_environments",
            "description": "List deployment environments for a repository. Shows protection rules, wait timers, and required reviewers.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "backstage_catalog_search",
            "description": "Search the Backstage Software Catalog for components, APIs, and systems to correlate with deployment health.",
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
            "name": "search_backstage_docs",
            "description": "Search Backstage documentation for observability plugins, health checks, and monitoring integrations.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Documentation search query"},
                },
                "required": ["query"],
            },
        },
    ],
)
