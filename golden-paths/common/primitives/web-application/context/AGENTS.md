# Agent guidance

This repository was generated from the Open Horizons `web-application` Golden Path.

**Purpose:** Full-stack web application with a chosen frontend and backend framework.
**Primary stack:** React, Next.js, Node.js, Python

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
| Agents | `accessibility`, `compass`, `expert-react-frontend-engineer`, `pipeline`, `sentinel` |
| Skills | `conventional-branch`, `documentation-writer`, `frontend-component-testing`, `frontend-test-strategy`, `pipeline-diagnostics`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage`, `web-design-reviewer`, `webapp-testing` |
| Instructions | `a11y`, `containerization-docker-best-practices`, `devops-core-principles`, `nextjs-tailwind`, `security-and-owasp`, `self-explanatory-code-commenting` |
| Prompts | `create-architectural-decision-record`, `technology-stack-blueprint-generator` |
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
