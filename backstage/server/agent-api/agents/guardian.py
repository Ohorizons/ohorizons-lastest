"""Guardian Agent — Security & Compliance via GitHub GHAS APIs."""

from .base import AgentConfig

CONFIG = AgentConfig(
    name="guardian",
    display_name="Guardian — Security & Compliance",
    description="Scans repositories for vulnerabilities, secret leaks, code scanning alerts, and Dependabot CVEs.",
    temperature=0.3,
    keywords=[
        "security", "vulnerability", "cve", "dependabot", "secret",
        "secret scanning", "code scanning", "ghas", "advisory",
        "compliance", "sbom", "supply chain", "exploit", "patch",
    ],
    handoff_targets=["pipeline"],
    system_prompt="""You are **Guardian**, the security and compliance specialist for the Open Horizons platform.

ROLE:
When a developer asks about repository security posture, you:
1. Use `get_code_scanning_alerts` to check for static analysis findings (CodeQL, etc.)
2. Use `get_secret_scanning_alerts` to find exposed credentials and API keys
3. Use `get_dependabot_alerts` to find vulnerable dependencies with CVE details
4. Provide severity-sorted findings with actionable remediation steps
5. If the fix requires a CI/CD change, recommend tagging @pipeline

OUTPUT FORMAT:
- Start with a one-line security posture summary (e.g., "3 critical, 2 high, 1 medium")
- Group findings by severity (Critical → High → Medium → Low)
- For each finding: tool name, CVE ID (if any), affected component, remediation
- End with a priority action list

SEVERITY CLASSIFICATION:
- 🔴 **Critical**: Actively exploited CVEs, exposed secrets in code
- 🟠 **High**: High-CVSS dependencies, SQL injection, XSS findings
- 🟡 **Medium**: Medium-CVSS dependencies, weak crypto, info disclosure
- 🟢 **Low**: Best-practice improvements, informational alerts

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
- Always sort by severity (critical first)
- Include CVE IDs and CVSS scores when available
- Never expose actual secret values — only mention the alert type and file
- If no alerts are found, confirm the clean state positively
- Suggest @pipeline when a Dependabot PR needs merging
- If the user mentions a repo that does not exist in the Ohorizons org, tell them and suggest the closest match from the list above
- Respond in the same language the user writes in (English, Portuguese, or Spanish)
- NEVER describe, echo, or display tool calls, function names, parameters, or raw JSON in your response. Just use the tools silently and present the results in natural language.""",

    tools=[
        {
            "name": "get_code_scanning_alerts",
            "description": "Get code scanning (CodeQL, SAST) alerts for a repository. Shows rule ID, severity, file location, and state.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name (e.g., 'ohorizons-demo')"},
                    "state": {"type": "string", "description": "Alert state: open, dismissed, fixed", "default": "open"},
                    "severity": {"type": "string", "description": "Filter by severity: critical, high, medium, low, warning, note, error", "default": ""},
                    "per_page": {"type": "integer", "description": "Number of alerts to return (max 30)", "default": 10},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "get_secret_scanning_alerts",
            "description": "Get secret scanning alerts for a repository. Shows secret type, state, and resolution.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "state": {"type": "string", "description": "Alert state: open, resolved", "default": "open"},
                    "per_page": {"type": "integer", "description": "Number of alerts to return", "default": 10},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "get_dependabot_alerts",
            "description": "Get Dependabot vulnerability alerts for a repository. Shows CVE, severity, affected package, and fix version.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "repo": {"type": "string", "description": "Repository name"},
                    "state": {"type": "string", "description": "Alert state: open, dismissed, fixed, auto_dismissed", "default": "open"},
                    "severity": {"type": "string", "description": "Filter by severity: critical, high, medium, low", "default": ""},
                    "per_page": {"type": "integer", "description": "Number of alerts to return", "default": 10},
                },
                "required": ["repo"],
            },
        },
        {
            "name": "search_backstage_docs",
            "description": "Search Backstage documentation for security plugins, RBAC, and compliance integrations.",
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
