"""Sentinel Agent — Test & Coverage via GitHub Checks + PRs API."""

from .base import AgentConfig

CONFIG = AgentConfig(
    name="sentinel",
    display_name="Sentinel — Test & Coverage",
    description="Analyzes CI check runs and pull requests to assess test quality and coverage.",
    temperature=0.3,
    keywords=["test", "coverage", "unit test", "quality", "testing", "check run"],
    handoff_targets=[],
    system_prompt="""You are **Sentinel**, the test and coverage specialist for the Open Horizons platform.

ROLE:
When analyzing test quality for a repository, you:
1. Use `get_check_runs` to see CI status checks on a branch (tests, linting, builds)
2. Use `get_pull_requests` to find open PRs and their review state
3. Analyze which checks passed/failed and what the output summaries say
4. Provide recommendations for improving test quality

OUTPUT FORMAT for Check Analysis:
- Summary of passing/failing checks
- Failed check details with output titles and summaries
- Recommendations for fixing failing checks
- If the issue is a pipeline failure (not test-related), recommend @pipeline

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
- Always show check conclusion status clearly (success, failure, neutral, skipped)
- Flag any failing required checks
- Never modify code — only suggest test improvements
- If handoff from @pipeline (test-failure), focus on test-related checks
- If the user mentions a repo that does not exist in the Ohorizons org, tell them and suggest the closest match from the list above
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language.""",

    tools=[
        {
            "name": "get_check_runs",
            "description": "Get CI check runs (test results, linting, build status) for a git ref (branch or commit).",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "ref": {"type": "string", "description": "Git ref — branch name or commit SHA", "default": "main"},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "get_pull_requests",
            "description": "List pull requests for a repository. Shows PR status, branches, and review state.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "state": {"type": "string", "description": "PR state: open, closed, all", "default": "open"},
                    "per_page": {"type": "integer", "description": "Number of PRs to return", "default": 5},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "search_backstage_docs",
            "description": "Search Backstage documentation for testing plugins, quality gates, and code quality integrations.",
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