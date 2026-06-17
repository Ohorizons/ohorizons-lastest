"""Pipeline Agent — CI/CD Diagnostics via GitHub Actions API."""

from .base import AgentConfig

CONFIG = AgentConfig(
    name="pipeline",
    display_name="Pipeline — CI/CD Diagnostics",
    description="Diagnoses GitHub Actions pipeline failures using real workflow run data.",
    temperature=0.3,
    keywords=["pipeline", "ci/cd", "build fail", "workflow", "action fail", "deploy"],
    handoff_targets=["sentinel"],
    system_prompt="""You are **Pipeline**, the CI/CD diagnostics specialist for the Open Horizons platform.

ROLE:
When a developer reports a pipeline failure or asks about CI/CD issues, you:
1. Use `get_workflow_runs` to fetch recent workflow runs and identify failures
2. Use `get_workflow_run_jobs` to drill into which specific job/step failed
3. Analyze the failure pattern and provide actionable remediation steps
4. If the failure is caused by test failures, recommend tagging @sentinel

OUTPUT FORMAT:
- Start with a one-line diagnosis summary
- Show the failed run details (workflow, branch, event)
- List which jobs/steps failed
- Provide numbered remediation steps
- End with a handoff recommendation if applicable

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
- Always be specific about which step/job failed and why
- Reference exact status and conclusion values
- Never suggest modifying workflow files directly — only recommend changes
- If the failure pattern is unknown, say so honestly
- If the user mentions a repo that does not exist in the Ohorizons org, tell them and suggest the closest match from the list above
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language.""",

    tools=[
        {
            "name": "get_workflow_runs",
            "description": "Get recent GitHub Actions workflow runs for a repository. Can filter by status (completed, failure, success, in_progress).",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name in the Ohorizons org (e.g., 'ohorizons-demo', 'todo-app-full-stack', 'backstage')"},
                    "status": {"type": "string", "description": "Filter by status: completed, failure, success, in_progress", "default": ""},
                    "per_page": {"type": "integer", "description": "Number of runs to return (max 10)", "default": 5},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "get_workflow_run_jobs",
            "description": "Get jobs and steps for a specific workflow run. Shows which steps passed/failed with details.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "run_id": {"type": "string", "description": "Workflow run ID from get_workflow_runs"},
                },
                "required": ["repo", "run_id"],
            },
        },
        {
            "name": "search_backstage_docs",
            "description": "Search Backstage documentation for CI/CD plugin references, GitHub Actions integration, and deployment guides.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Documentation search query"},
                },
                "required": ["query"],
            },
        },
        {
            "name": "search_copilot_docs",
            "description": "Search GitHub Copilot documentation for CI/CD automation and agentic workflow patterns.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Copilot docs search query"},
                },
                "required": ["query"],
            },
        },
    ],
)