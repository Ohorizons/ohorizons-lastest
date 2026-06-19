---
title: "Enterprise Validation Hardening Evidence Guide"
description: "Evidence collection, sanitization, and handoff rules for Open Horizons enterprise validation."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["evidence", "redaction", "validation", "enterprise"]
---

# Enterprise Validation Hardening Evidence Guide

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial evidence guide |

## 1. Evidence Classes

| Class | Examples | Default Consumer | Handling |
|-------|----------|------------------|----------|
| Raw runtime | Terraform plan JSON, Terraform output JSON, kubeconfig, CLI logs | Local operator only | Ignored path, do not paste |
| Agent-safe | Sanitized summaries, status, errors, redacted inventory | Agents and reviewers | Preferred evidence |
| Customer handoff | Resource summary, validation report, screenshots without secrets | Customer/partner | Sanitized and reviewed |

## 2. Required Redactions

Sanitized evidence must mask or remove:

- Azure subscription IDs and full resource IDs.
- Kubeconfig, certificates, certificate authority data, client keys, and bearer tokens.
- GitHub tokens including `ghp_`, `github_pat_`, installation tokens, and app private keys.
- Passwords, connection strings, access keys, primary/secondary keys, and API keys.
- Entra client secrets and private keys.
- PEM blocks and long opaque credential-like strings.

## 3. Sanitized Artifact Names

| Raw Artifact | Sanitized Artifact |
|--------------|--------------------|
| `tfplan.json` | `tfplan.sanitized.json` |
| `terraform-output.json` | `terraform-output.sanitized.json` |
| `resources.json` | `resources-summary.sanitized.json` |
| `kubectl-pods-all.txt` | `kubectl-pods-summary.txt` |
| `kubectl-events.txt` | `kubectl-events-summary.txt` |

## 4. Handoff Checklist

Before evidence is shared outside the local run directory:

1. Run the redaction tests.
2. Inspect sanitized files for known secret patterns.
3. Confirm no raw Terraform state or kubeconfig is included.
4. Record the command used to generate the evidence.
5. Link the evidence in `TEST_MATRIX.md` or `fixes.md`.

## 5. Live Checkpoint Evidence

The first live validation target after hardening is `contoso-prod-nogithub-finalcheck`. The required evidence sequence is:

```bash
scripts/azure-validation-run.sh --phase validate-all --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
scripts/azure-validation-run.sh --phase inventory --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
scripts/azure-validation-run.sh --phase docs --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
```

No apply or destroy is part of this evidence sequence.
