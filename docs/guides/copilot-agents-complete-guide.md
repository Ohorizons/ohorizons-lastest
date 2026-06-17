# Copilot Agents Complete Guide

Open Horizons uses project-specific Copilot Chat agents to support platform architecture, delivery, validation, and operations.

## Agent Families

| Area | Agents |
|------|--------|
| Architecture and planning | `@architect`, `@compass` |
| Platform and portal | `@platform`, `@backstage-expert` |
| Infrastructure and deployment | `@terraform`, `@deploy`, `@devops` |
| Quality and operations | `@reviewer`, `@test`, `@sentinel`, `@sre`, `@security` |
| Integrations | `@github-integration`, `@ado-integration`, `@hybrid-scenarios` |
| Documentation | `@docs` |

## Common Workflows

| Workflow | Starting Agent | Handoffs |
|----------|----------------|----------|
| Create a Golden Path | `@platform` | `@security`, `@devops` |
| Design infrastructure | `@architect` | `@terraform`, `@security` |
| Deploy platform changes | `@deploy` | `@devops`, `@sre` |
| Diagnose failed checks | `@pipeline` or `@sentinel` | `@test`, `@reviewer` |
| Update docs | `@docs` | `@architect`, `@platform` |

## Validation Checklist

1. Confirm the agent file exists in `.github/agents/`.
2. Confirm referenced skills exist in `.github/skills/`.
3. Run `./scripts/validate-agents.sh` after editing agent files.
4. Run relevant Golden Path and documentation validation scripts after template changes.

## References

- [GitHub Copilot documentation](https://docs.github.com/copilot)
- [Backstage Software Templates documentation](https://backstage.io/docs/features/software-templates/)
- [Backstage Software Catalog documentation](https://backstage.io/docs/features/software-catalog/)