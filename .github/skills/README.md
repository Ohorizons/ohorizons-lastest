# GitHub Copilot Agent Skills

This directory contains skills that extend GitHub Copilot agent capabilities. Skills use **progressive loading** - Copilot reads metadata first and loads scripts only when relevant.

## Available Skills (17)

| Skill | Description | Used By |
|-------|-------------|---------|
| [terraform-cli](./terraform-cli/) | Terraform CLI operations | @terraform, @infrastructure |
| [kubectl-cli](./kubectl-cli/) | Kubernetes CLI operations | @platform, @devops, @sre |
| [azure-cli](./azure-cli/) | Azure CLI operations | @infrastructure, @security |
| [argocd-cli](./argocd-cli/) | ArgoCD operations | @gitops, @devops |
| [helm-cli](./helm-cli/) | Helm chart operations | @gitops, @platform |
| [github-cli](./github-cli/) | GitHub API operations | @devops, @migration |
| [validation-scripts](./validation-scripts/) | Deployment validation | @validation, @devops |
| [azure-infrastructure](./azure-infrastructure/) | Azure IaC patterns | @infrastructure |
| [database-management](./database-management/) | Database operations | @database, @sre |
| [observability-stack](./observability-stack/) | Monitoring operations | @observability, @sre |
| [ai-foundry-operations](./ai-foundry-operations/) | Azure AI operations | @ai-foundry |
| [backstage-deployment](./backstage-deployment/) | Backstage portal operations | @backstage-expert |
| [mcp-cli](./mcp-cli/) | MCP server reference | All agents |
| [prerequisites](./prerequisites/) | CLI tool validation | All agents |

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
