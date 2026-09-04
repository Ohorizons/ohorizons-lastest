# Agent guidance

This repository was generated from the Open Horizons `aeg-application` Golden Path.

**Purpose:** Governed Agentic Engineering Graph run that produces requirements, architecture, and an implemented application behind human gates.
**Primary stack:** Agentic Engineering Graph, specification-driven delivery

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
| Agents | `agent-governance-reviewer`, `compass`, `pipeline`, `sentinel`, `software-engineer-agent-v1` |
| Skills | `agent-governance`, `conventional-branch`, `create-agentsmd`, `documentation-writer`, `eval-driven-dev`, `pipeline-diagnostics`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage` |
| Instructions | `agents`, `context-engineering`, `devops-core-principles`, `security-and-owasp`, `self-explanatory-code-commenting`, `spec-driven-workflow-v1` |
| Prompts | `create-architectural-decision-record`, `create-specification` |
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
