---
title: "Azure Validation Example"
description: "Sanitized example structure for evidence collected by an agent-supervised Open Horizons Azure validation run."
author: "Open Horizons"
date: "2026-06-18"
version: "1.0.0"
status: "template"
tags: ["azure", "validation", "evidence", "example"]
---

# Azure Validation Example

> This folder is the versioned home for sanitized evidence from real Azure validation runs. Raw run artifacts stay under `runs/azure-validation/<run-id>/` and are ignored by Git.

## What to Copy Here

After a successful run, copy only sanitized artifacts:

| Artifact | Source | Notes |
|----------|--------|-------|
| Resource inventory | `runs/azure-validation/<run-id>/08-docs/resource-inventory.md` | Remove or mask subscription IDs if needed |
| Validation results | `runs/azure-validation/<run-id>/summary.md` | Keep phase status and timing |
| Fix log | `runs/azure-validation/<run-id>/fixes.md` | Keep root cause and remediation, remove secrets |
| Screenshots | `runs/azure-validation/<run-id>/06-screenshots/` | Remove tenant/subscription details if sensitive |

## Suggested Published Layout

```text
docs/examples/azure-validation/
  README.md
  resource-inventory.md
  validation-results.md
  fixes.md
  screenshots/
```

## Sanitization Rules

- Never commit access tokens, passwords, private keys, kubeconfigs, or Key Vault secret values.
- Prefer secret names and resource names over secret values.
- Mask subscription IDs and tenant IDs when publishing externally.
- Keep enough evidence to prove the deployment was integrated: AKS, ArgoCD, Backstage, observability, PostgreSQL, Azure Managed Redis, AI Foundry, Agent API, MCP, and cleanup.

## Related

- [Azure Validation Runbook](../../guides/AZURE_VALIDATION_RUNBOOK.md)
- [Environment Sizing & Regions](../../guides/ENVIRONMENT_SIZING.md)
- [Deployment Guide](../../guides/DEPLOYMENT_GUIDE.md)
