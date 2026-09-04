# Copilot instructions

`${{ values.name }}` was generated from the Open Horizons `ado-to-github-migration` Golden
Path. This file is injected into every Copilot request in this repository, so
it stays short; `AGENTS.md` holds the long-form inventory.

## What this repository is

Azure DevOps to GitHub migration, covering repositories, pipelines, work items, and permissions.

**Primary stack:** Azure DevOps, GitHub Actions
**Owner:** `${{ values.owner }}`

## How to work here

- Prefer the installed skills over improvising: `azure-cloud-migrate`, `azure-devops-cli`, `conventional-branch`, `documentation-writer`, `issue-fields-migration`, `pipeline-diagnostics`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage`.
- The path instructions under `.github/instructions/` are authoritative for the
  files they match: `azure-devops-pipelines`, `devops-core-principles`, `github-actions-ci-cd-best-practices`, `security-and-owasp`, `self-explanatory-code-commenting`.
- Make surgical changes that fully address the request; do not refactor
  unrelated code in the same change.
- Only run linters, builds, and tests that already exist in this repository.

## Durable rules

- Never commit a secret, token, or connection string.
- Never use `:latest` in a deployment manifest; pin an explicit version tag.
- Use workload identity or managed identity rather than static credentials.
- Keep `catalog-info.yaml` accurate whenever ownership or metadata changes.
- Set resource requests and limits, non-root security contexts, and probes on
  every Kubernetes workload.

## Validation

```bash
python3 .github/scripts/validate-primitives.py
```
