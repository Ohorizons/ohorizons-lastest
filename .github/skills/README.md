# GitHub Copilot Agent Skills

This directory contains skills that extend GitHub Copilot agent capabilities. Skills use **progressive loading** - Copilot reads metadata first and loads scripts only when relevant.

## Available Skills (31)

| Skill | Description | Used By |
| ----- | ----------- | ------- |
| [Agentic Architecture Patterns](./agentic-architecture-patterns/) | Agentic system architecture patterns | `@deploy`, `@security` |
| [AI Foundry Operations](./ai-foundry-operations/) | Azure AI Foundry operations | `@deploy`, `@azure-portal-deploy` |
| [Architecture Doc](./architecture-doc/) | Architecture document validation | `@deploy` |
| [ArgoCD CLI](./argocd-cli/) | ArgoCD operations | `@deploy`, `@sre` |
| [Azure Architecture Diagrams](./azure-architecture-diagrams/) | Azure architecture diagrams | `@deploy` |
| [Azure CLI](./azure-cli/) | Azure CLI operations | `@terraform`, `@security`, `@sre`, `@azure-portal-deploy` |
| [Azure Infrastructure](./azure-infrastructure/) | Azure infrastructure patterns | `@terraform`, `@security`, `@azure-portal-deploy` |
| [Azure Managed Redis Cache](./azure-managed-redis-cache/) | Azure Managed Redis patterns | `@deploy`, `@terraform` |
| [Backstage Deployment](./backstage-deployment/) | Backstage portal operations | `@backstage-expert`, `@deploy` |
| [Codespaces Golden Paths](./codespaces-golden-paths/) | Codespaces dev environments | `@backstage-expert`, `@deploy` |
| [Database Management](./database-management/) | Database operations | `@terraform`, `@sre`, `@deploy` |
| [Deploy Orchestration](./deploy-orchestration/) | End-to-end deployment orchestration | `@deploy` |
| [Foundry Agent Blueprint](./foundry-agent-blueprint/) | Azure AI Foundry agent blueprint | `@deploy`, `@azure-portal-deploy` |
| [GitHub CLI](./github-cli/) | GitHub API operations | `@deploy`, `@github-integration` |
| [Helm CLI](./helm-cli/) | Helm chart operations | `@deploy`, `@backstage-expert`, `@sre` |
| [Issue Ops](./issue-ops/) | IssueOps dispatcher patterns | `@deploy` |
| [Kubectl CLI](./kubectl-cli/) | Kubernetes CLI operations | `@deploy`, `@backstage-expert`, `@sre` |
| [Markdown Writer](./markdown-writer/) | Markdown document writing | `@deploy` |
| [MCP Ecosystem](./mcp-ecosystem/) | MCP ecosystem reference lookup | `@backstage-expert`, `@deploy` |
| [Observability Stack](./observability-stack/) | Monitoring operations | `@sre`, `@deploy` |
| [Pipeline Diagnostics](./pipeline-diagnostics/) | CI/CD diagnostics reference | `@deploy` |
| [Playbook PDF Builder](./playbook-pdf-builder/) | Consolidated PDF generation | `@deploy` |
| [Prerequisites](./prerequisites/) | CLI tool validation | `@deploy` |
| [Prompt Architect](./prompt-architect/) | Prompt and customization design | `@deploy` |
| [Requirements Engineer](./requirements-engineer/) | Requirements engineering | `@deploy` |
| [SDD Spec Engineer](./sdd-spec-engineer/) | Spec-driven development artifacts | `@deploy` |
| [Story Planning](./story-planning/) | User story planning | `@deploy` |
| [Terraform CLI](./terraform-cli/) | Terraform CLI operations | `@terraform`, `@security`, `@deploy` |
| [Test Coverage](./test-coverage/) | Test coverage and quality gates | `@deploy` |
| [Validation Scripts](./validation-scripts/) | Deployment validation | `@deploy`, `@sre`, `@security` |
| [XLSX Creator](./xlsx-creator/) | Excel workbook creation | `@deploy` |

## Skill Structure

Each skill follows this directory structure:

```
skill-name/
├── SKILL.md          # Main skill definition (required)
├── scripts/          # Executable scripts
│   └── *.sh
└── references/       # Reference documentation
    └── *.md
```

## SKILL.md Format

```markdown
---
name: skill-name
description: What this skill provides
version: "1.0.0"
license: MIT
tools_required: ["tool1", "tool2"]
min_versions:
  tool1: "1.0.0"
---

## When to Use
[Trigger conditions]

## Prerequisites
[Required tools and access]

## Commands
[Executable commands]

## Best Practices
[Guidelines]

## Output Format
[Expected output structure]
```

## Adding a New Skill

1. Create directory: `mkdir -p skill-name/{scripts,references}`
2. Create `SKILL.md` with required sections
3. Add scripts to `scripts/` directory
4. Reference skill in agent's `skills` frontmatter array
5. Test skill invocation with relevant agent

## Integration with Agents

Skills are referenced in agent frontmatter:

```yaml
---
name: my-agent
skills:
  - terraform-cli
  - azure-cli
---
```

When an agent is invoked, Copilot progressively loads relevant skills based on the task context.

## Best Practices

1. Keep skills focused on a single domain
2. Include all prerequisite checks
3. Document commands with full flags
4. Provide clear output format expectations
5. Test scripts independently before integration
