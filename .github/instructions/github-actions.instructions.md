---
applyTo: ".github/workflows/**/*.yml,.github/workflows/**/*.yaml,**/.github/workflows/**/*.yml,**/.github/workflows/**/*.yaml"
description: "GitHub Actions workflow standards for security, OIDC, permissions, and validation gates."
---

# GitHub Actions Standards

## Security

- Use least-privilege `permissions`; keep top-level permissions read-only and raise permissions per job when needed.
- Add `id-token: write` only for jobs that use OIDC, such as `azure/login`.
- Pass untrusted GitHub event values through `env` before using them in shell scripts.
- Pin third-party actions to major versions at minimum; avoid mutable refs such as `@master` or `@main`.
- Use GitHub environments with required reviewers for staging and production deployments.

## Reliability

- Use `concurrency` for deployments so environments are not updated in parallel.
- Prefer dry-run or plan jobs before apply jobs.
- Make validation jobs fail fast for critical errors and soft-fail only informational checks.
- Use explicit shell behavior for scripts that rely on Bash semantics.

## Open Horizons Workflow Rules

- Full platform deployment is deploy-led; route workflow issues through `agent:deploy`.
- Validate Copilot primitives when `.github/**` customization files change.
- Do not reference paths that are not present in the repository.
