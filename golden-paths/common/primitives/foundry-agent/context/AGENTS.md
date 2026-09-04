# Agent guidance

This repository was generated from the Open Horizons `foundry-agent` Golden Path.

**Purpose:** Autonomous agent deployed to Azure AI Agent Service backed by Azure AI Foundry.
**Primary stack:** Azure AI Foundry, Microsoft Agent Framework

## Project identity

| Field | Value |
| --- | --- |
| Component | `${{ values.name }}` |
| Owner | `${{ values.owner }}` |
| Catalog entry | `catalog-info.yaml` |

## Installed primitives

These were selected for this template's context, not copied from a generic
bundle. Prefer them over improvising an approach.

| Kind | Installed |
| --- | --- |
| Agents | `agent-governance-reviewer`, `compass`, `custom-agent-foundry`, `pipeline`, `se-responsible-ai-code`, `sentinel` |
| Skills | `agent-governance`, `azure-ai`, `conventional-branch`, `documentation-writer`, `foundry-agent-sync`, `microsoft-agent-framework`, `pipeline-diagnostics`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage` |
| Instructions | `agent-safety`, `ai-prompt-engineering-safety-best-practices`, `devops-core-principles`, `microsoft-foundry`, `security-and-owasp`, `self-explanatory-code-commenting` |
| Prompts | `create-architectural-decision-record`, `design-agentic-system` |
| Hooks | `secrets-scanner` |

`.github/harness/HARNESS.md` records how each kind is discovered and where the
primitives came from.

## Platform agents

| Agent | Use it for |
| --- | --- |
| `compass` | Business and product context for a change. |
| `pipeline` | CI/CD, build, and deployment diagnostics. |
| `sentinel` | Security posture and dependency risk. |

## Durable rules

- Never use `:latest` in a deployment manifest; pin an explicit version tag.
- Keep secrets in the platform secret store, never in source or in a manifest.
- Every change keeps `catalog-info.yaml` accurate; the portal is the inventory.
- Run `python3 .github/scripts/validate-primitives.py` after changing anything
  under `.github/`.

## Validation

```bash
python3 .github/scripts/validate-primitives.py
```
