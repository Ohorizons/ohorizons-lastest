# GitHub Copilot Agent Skills

This directory contains Open Horizons skills for GitHub Copilot, Copilot CLI, and cloud agent workflows. Skills use progressive loading: frontmatter metadata is always available for routing, while the body loads only when the skill is selected.

## Available Skills (29)

| Skill | Description | Used By |
| --- | --- | --- |
| [Agentic Architecture Patterns](./agentic-architecture-patterns/) | Agentic system architecture patterns | `@deploy`, `@security` |
| [AI Foundry Operations](./ai-foundry-operations/) | Azure AI Foundry operations | `@deploy`, `@azure-portal-deploy` |
| [Architecture Doc](./architecture-doc/) | Architecture document validation | `@deploy` |
| [ArgoCD CLI](./argocd-cli/) | ArgoCD operations | `@deploy`, `@sre` |
| [Azure Architecture Diagrams](./azure-architecture-diagrams/) | Azure architecture diagrams | `@deploy` |
| [Azure CLI](./azure-cli/) | Azure CLI operations | `@terraform`, `@security`, `@sre`, `@azure-portal-deploy` |
| [Azure Infrastructure](./azure-infrastructure/) | Azure infrastructure patterns | `@terraform`, `@security`, `@azure-portal-deploy` |
| [Azure Managed Redis Cache](./azure-managed-redis-cache/) | Azure Managed Redis patterns | `@deploy`, `@terraform` |
| [Backstage Deployment](./backstage-deployment/) | Backstage portal operations | `@backstage-expert`, `@deploy` |
| [Backstage Plugin Builder](./backstage-plugin-builder/) | Backstage plugin and module planning, scaffolding, validation, and publication preparation | `@backstage-expert`, `@deploy` |
| [Codespaces Golden Paths](./codespaces-golden-paths/) | Codespaces dev environments | `@backstage-expert`, `@deploy` |
| [Database Management](./database-management/) | Database operations | `@terraform`, `@sre`, `@deploy` |
| [Deploy Orchestration](./deploy-orchestration/) | End-to-end deployment orchestration | `@deploy` |
| [Foundry Agent Blueprint](./foundry-agent-blueprint/) | Azure AI Foundry agent blueprint | `@deploy`, `@azure-portal-deploy` |
| [GitHub CLI](./github-cli/) | GitHub API operations | `@deploy`, `@github-integration` |
| [Helm CLI](./helm-cli/) | Helm chart operations | `@deploy`, `@backstage-expert`, `@sre` |
| [Issue Ops](./issue-ops/) | IssueOps dispatcher patterns | `@deploy` |
| [Kubectl CLI](./kubectl-cli/) | Kubernetes CLI operations | `@deploy`, `@backstage-expert`, `@sre` |
| [Markdown Writer](./markdown-writer/) | Markdown document writing | `@deploy` |
| [MCP Ecosystem](./mcp-ecosystem/) | Local MCP reference server lookup | `@backstage-expert`, `@deploy` |
| [Observability Stack](./observability-stack/) | Monitoring operations | `@sre`, `@deploy` |
| [Pipeline Diagnostics](./pipeline-diagnostics/) | GitHub Actions CI/CD diagnostics | `@deploy` |
| [Prerequisites](./prerequisites/) | CLI prerequisite validation | `@deploy` |
| [Requirements Engineer](./requirements-engineer/) | FRD and NFRD requirements engineering | `@deploy` |
| [SDD Spec Engineer](./sdd-spec-engineer/) | Spec-driven development artifacts | `@deploy` |
| [Story Planning](./story-planning/) | INVEST story planning and optional GitHub Issues | `@deploy` |
| [Terraform CLI](./terraform-cli/) | Terraform CLI operations | `@terraform`, `@security`, `@deploy` |
| [Test Coverage](./test-coverage/) | Test coverage and quality gates | `@deploy` |
| [Validation Scripts](./validation-scripts/) | Repository validation scripts | `@deploy`, `@sre`, `@security` |

## SKILL.md Template Contract

Every `SKILL.md` must follow the Open Horizons gold-standard structure:

1. Frontmatter with valid skill metadata.
2. H1 title matching the skill purpose.
3. One paragraph explaining what the workflow does and what it produces.
4. A `> [!NOTE]` callout declaring external dependencies, including CLIs, MCP servers, and authentication.
5. `## When to invoke` with quoted natural user phrasings.
6. `## Prerequisites` with concrete, checkable requirements.
7. `## Workflow steps` with numbered `### Step N: Title` sections and real repository commands or procedures.
8. A risk, severity, readiness, confidence, or finding classification table when the skill produces findings or can mutate state.
9. A user-confirmation gate with `> [!IMPORTANT]` before destructive, costly, cluster-mutating, infrastructure-mutating, or GitHub artifact-creating actions.
10. `## Error handling` as a `Situation | Action` table.
11. `## Output template` as a fenced Markdown skeleton.
12. `## Quality gate` with objective checkboxes.

## Frontmatter Rules

`SKILL.md` frontmatter supports only these keys:

| Key | Required | Rule |
| --- | --- | --- |
| `name` | Yes | Lowercase letters, numbers, and hyphens only; 1-64 characters; must equal the directory name. |
| `description` | Yes | 10-1024 characters; starts with `Use when`; includes produced artifacts; preserves `DO NOT USE FOR:` routing; ends with quoted trigger phrasings. |
| `license` | No | Use only when a skill explicitly needs license metadata. |
| `allowed-tools` | No | Omit unless truly required; currently used by `prerequisites` for shell access. |

Do not add unsupported keys such as `argument-hint`, `version`, `tools_required`, or `min_versions` to skill frontmatter.

## Directory Structure

```text
skill-name/
|-- SKILL.md
|-- scripts/
|   `-- *.sh
`-- references/
    `-- *.md
```

Only `SKILL.md` is required. Add `scripts/` or `references/` only when the skill needs executable helpers or reusable reference material.

## Adding or Updating a Skill

1. Keep the skill focused on one domain and avoid routing overlap.
2. Preserve `DO NOT USE FOR:` disambiguation in the description.
3. Reference only repository paths that exist.
4. Use real commands from this repository when examples are needed.
5. Add explicit confirmation gates before mutation or artifact creation.
6. Remove emojis, pictographs, and dingbats from skill files.
7. Run strict validation:

```bash
python3 .github/skills/validation-scripts/scripts/validate-agents.py --strict
```

## Integration with Agents

Agents reference skills in their instructions and load them lazily based on task routing. Because descriptions are always in context, each description must be a precise routing signal and must stay under the validator's 1024-character limit.
