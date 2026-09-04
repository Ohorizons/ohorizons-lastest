# Copilot instructions

`${{ values.name }}` was generated from the Open Horizons `documentation-site` Golden
Path. This file is injected into every Copilot request in this repository, so
it stays short; `AGENTS.md` holds the long-form inventory.

## What this repository is

Documentation website with TechDocs integration, search, and versioning.

**Primary stack:** MkDocs, Markdown, TechDocs
**Owner:** `${{ values.owner }}`

## How to work here

- Prefer the installed skills over improvising: `conventional-branch`, `convert-plaintext-to-md`, `documentation-writer`, `mkdocs-translations`, `pipeline-diagnostics`, `review-and-refactor`, `security-review`, `story-planning`, `test-coverage`.
- The path instructions under `.github/instructions/` are authoritative for the
  files they match: `devops-core-principles`, `markdown`, `markdown-accessibility`, `markdown-content-creation`, `security-and-owasp`, `self-explanatory-code-commenting`.
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
