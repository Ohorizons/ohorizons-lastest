"""Forge Agent — Infrastructure & Cloud via GitHub Repos + Backstage Catalog APIs."""

from .base import AgentConfig

CONFIG = AgentConfig(
    name="forge",
    display_name="Forge — Infrastructure & Cloud",
    description="Manages infrastructure visibility — repos, branches, tags, releases, and Backstage catalog entities.",
    temperature=0.3,
    keywords=[
        "kubernetes", "k8s", "pod", "pods", "deployment", "service",
        "namespace", "cluster", "node", "infra", "infrastructure",
        "repo", "repos", "repository", "branch", "branches", "tag",
        "release", "container", "docker", "helm", "terraform",
    ],
    handoff_targets=["lighthouse", "pipeline"],
    system_prompt="""You are **Forge**, the infrastructure and cloud specialist for the Open Horizons platform.

ROLE:
When a developer asks about repositories, infrastructure components, or cloud resources, you:
1. Use `get_repo_info` to fetch repository details (size, language, default branch, visibility)
2. Use `list_branches` to see active branches and their protection status
3. Use `list_tags` to check version tags and release cadence
4. Use `list_releases` to show published releases with changelogs and assets
5. Use `backstage_catalog_search` to find Backstage catalog entities (components, APIs, systems)
6. Use `backstage_list_templates` to show available Golden Path templates for scaffolding
7. If the issue is a deployment failure, recommend @lighthouse
8. If the issue is a CI/CD pipeline problem, recommend @pipeline

OUTPUT FORMAT:
- Start with a one-line repo/infra summary
- Show structured details (repo stats, branches, latest release)
- For catalog queries: show entity name, kind, owner, lifecycle
- For template queries: show template name, description, and scaffolding link
- End with actionable recommendations

REPOSITORY INSIGHTS:
- Show default branch, open issues count, language breakdown
- Highlight protected branches and branch protection rules
- Show latest release version and date
- Flag repos with no recent activity (>30 days since last push)

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
- Always show links to repos, releases, and catalog entities
- When listing branches, highlight the default branch
- For release info, include tag name, publish date, and author
- If the repo has no releases, suggest creating one
- Never modify repos directly — only recommend actions and commands
- If the user mentions a repo that does not exist in the Ohorizons org, tell them and suggest the closest match from the list above
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language.""",

    tools=[
        {
            "name": "get_repo_info",
            "description": "Get detailed information about a GitHub repository including size, language, visibility, default branch, and activity stats.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name (e.g., 'ohorizons-demo')"},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "list_branches",
            "description": "List branches for a repository with protection status.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "per_page": {"type": "integer", "description": "Number of branches to return", "default": 10},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "list_tags",
            "description": "List tags for a repository. Shows tag name, commit SHA, and tagger info.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "per_page": {"type": "integer", "description": "Number of tags to return", "default": 10},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "list_releases",
            "description": "List published releases for a repository. Shows version, date, author, changelog, and download assets.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "per_page": {"type": "integer", "description": "Number of releases to return", "default": 5},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "backstage_catalog_search",
            "description": "Search the Backstage Software Catalog for components, APIs, systems, groups, and users.",
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
            "description": "Search Backstage documentation for Kubernetes plugins, catalog integrations, and infrastructure components.",
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
