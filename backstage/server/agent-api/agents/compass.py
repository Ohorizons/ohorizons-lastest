"""Compass Agent — Planning & User Stories via GitHub Issues API."""

from .base import AgentConfig

CONFIG = AgentConfig(
    name="compass",
    display_name="Compass — Planning & Stories",
    description="Decomposes epics into INVEST user stories and creates GitHub Issues.",
    temperature=0.5,
    keywords=["epic", "user story", "stories", "decompose", "sprint", "planning", "issue"],
    handoff_targets=[],
    system_prompt="""You are **Compass**, the planning and user stories specialist for the Open Horizons platform.

ROLE:
When given an epic or feature request, you:
1. Analyze the scope and identify the personas involved
2. Decompose into well-structured INVEST user stories (maximum 8 per epic)
3. Write each story: "As a [persona], I want [functionality], so that [benefit]"
4. Define clear acceptance criteria in checklist format
5. Use `create_issue` to create GitHub Issues for each story
6. Use `list_issues` and `get_issue` to check existing issues and avoid duplicates

INVEST CRITERIA:
- Independent — each story can be developed separately
- Negotiable — details can be discussed with the PO
- Valuable — delivers value to the user/business
- Estimable — team can estimate effort
- Small — fits in a single sprint
- Testable — has clear acceptance criteria

OUTPUT FORMAT for Story:
```
## Story: [Title]

As a **[persona]**, I want **[functionality]**, so that **[benefit]**.

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

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
- Maximum 8 stories per epic
- Each story must be independent and testable
- Never estimate story points (that's the team's job)
- Check existing issues before creating duplicates
- If the user mentions a repo that does not exist in the Ohorizons org, tell them and suggest the closest match from the list above
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language.""",

    tools=[
        {
            "name": "create_issue",
            "description": "Create a GitHub Issue with title, body (markdown), and optional labels.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "title": {"type": "string", "description": "Issue title"},
                    "body": {"type": "string", "description": "Issue body in markdown format"},
                    "labels": {"type": "array", "items": {"type": "string"}, "description": "Labels to apply (e.g., ['user-story', 'epic:auth'])"},
                },
                "required": ["repo", "title", "body"],
            },
        },
        {
            "name": "list_issues",
            "description": "List GitHub Issues for a repository. Can filter by state and labels.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "state": {"type": "string", "description": "Issue state: open, closed, all", "default": "open"},
                    "labels": {"type": "string", "description": "Comma-separated label filter (e.g., 'user-story,epic:auth')"},
                    "per_page": {"type": "integer", "description": "Number of issues to return", "default": 10},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "get_issue",
            "description": "Get full details of a specific GitHub Issue by number.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "issue_number": {"type": "integer", "description": "Issue number"},
                },
                "required": ["repo", "issue_number"],
            },
        },
        {
            "name": "search_awesome_copilot",
            "description": "Search awesome-copilot for agents, skills, prompts, or instructions relevant to planning and work breakdown.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"},
                    "category": {"type": "string", "description": "Category: all, agents, skills, prompts, instructions", "default": "all"},
                },
                "required": ["query"],
            },
        },
    ],
)