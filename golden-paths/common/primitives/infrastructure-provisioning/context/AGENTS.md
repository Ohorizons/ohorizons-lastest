# Agent guidance

This repository was generated from the Open Horizons `infrastructure-provisioning` Golden Path.

**Purpose:** Azure infrastructure-as-code project with policy compliance, cost controls, and drift detection.
**Primary stack:** Terraform and Bicep on Azure

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
| Agents | `azure-verified-modules-bicep`, `azure-verified-modules-terraform`, `bicep-implement`, `bicep-plan`, `compass`, `pipeline`, `sentinel`, `terraform-azure-implement`, `terraform-azure-planning`, `terraform-iac-reviewer` |
| Skills | `azure-cli`, `azure-infrastructure`, `azure-terraform-cli`, `azure-validate`, `conventional-branch`, `documentation-writer`, `pipeline-diagnostics`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage` |
| Instructions | `azure-naming`, `azure-verified-modules-terraform`, `bicep-code-best-practices`, `devops-core-principles`, `security-and-owasp`, `self-explanatory-code-commenting`, `terraform-azure` |
| Prompts | `architecture-blueprint-generator`, `create-architectural-decision-record` |
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
