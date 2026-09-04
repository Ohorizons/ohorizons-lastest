# Copilot instructions

`${{ values.name }}` was generated from the Open Horizons `aeg-application` Golden
Path. This file is injected into every Copilot request in this repository, so
it stays short; `AGENTS.md` holds the long-form inventory.

## What this repository is

Governed Agentic Engineering Graph run that produces requirements, architecture, and an implemented application behind human gates.

**Primary stack:** Agentic Engineering Graph, specification-driven delivery
**Owner:** `${{ values.owner }}`

## How to work here

- Prefer the installed skills over improvising: `agent-governance`, `conventional-branch`, `create-agentsmd`, `documentation-writer`, `eval-driven-dev`, `pipeline-diagnostics`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage`.
- The path instructions under `.github/instructions/` are authoritative for the
  files they match: `agents`, `context-engineering`, `devops-core-principles`, `security-and-owasp`, `self-explanatory-code-commenting`, `spec-driven-workflow-v1`.
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
