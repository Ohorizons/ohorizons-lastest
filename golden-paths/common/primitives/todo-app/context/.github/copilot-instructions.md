# Copilot instructions

`${{ values.name }}` was generated from the Open Horizons `todo-app` Golden
Path. This file is injected into every Copilot request in this repository, so
it stays short; `AGENTS.md` holds the long-form inventory.

## What this repository is

Full-stack reference application with end-to-end tests and Azure infrastructure.

**Primary stack:** React, TypeScript, Node.js, Prisma, PostgreSQL, Redis, Terraform, Playwright
**Owner:** `${{ values.owner }}`

## How to work here

- Prefer the installed skills over improvising: `azure-postgre-database-management`, `azure-terraform-cli`, `conventional-branch`, `documentation-writer`, `frontend-visual-e2e-testing`, `pipeline-diagnostics`, `playwright-explore-website`, `playwright-generate-test`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage`.
- The path instructions under `.github/instructions/` are authoritative for the
  files they match: `containerization-docker-best-practices`, `devops-core-principles`, `playwright-typescript`, `security-and-owasp`, `self-explanatory-code-commenting`, `terraform-azure`.
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
