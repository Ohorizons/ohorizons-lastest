---
title: "Enterprise Validation Hardening Implementation Plan"
description: "TDD-first implementation plan for hardening Open Horizons enterprise validation."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["implementation-plan", "TDD", "validation", "enterprise"]
---

# Enterprise Validation Hardening Implementation Plan

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial plan |

## Table of Contents

- [1. Implementation Rules](#1-implementation-rules)
- [2. Phase Plan](#2-phase-plan)
- [3. Validation Commands](#3-validation-commands)
- [4. Human Gates](#4-human-gates)

## 1. Implementation Rules

- Use Red-Green-Refactor for every script, Terraform, and template correction.
- Keep cloud-mutating commands out of local tests.
- Do not read or paste raw Terraform state, raw plan JSON, kubeconfig, or secrets into documentation.
- Update `TEST_MATRIX.md` when each task is implemented.
- Preserve existing user changes and ignored run artifacts.

## 2. Phase Plan

### Phase 1: SDD Contract

| Task | Files | Output |
|------|-------|--------|
| Create enterprise hardening package | `docs/sdd/enterprise-validation-hardening/*` | Complete SDD package |
| Add Entra/EMU local constitution | `docs/sdd/entra-id-github-emu/CONSTITUTION.md` | Identity-specific non-negotiables |
| Map acceptance to tests | `TEST_MATRIX.md`, Entra/EMU plan | Traceable acceptance matrix |

### Phase 2: Identity Red Tests

| Task | Files | Output |
|------|-------|--------|
| Add valid Entra plus EMU wizard test | `tests/wizard/run.sh` | Fails before any missing behavior is fixed |
| Add invalid EMU combinations | `tests/wizard/run.sh` | GitHub/guest plus EMU fail |
| Add Entra render dry-run test | `tests/wizard/run.sh` or `tests/validation/render-entra-emu.sh` | Microsoft auth fragment verified |

### Phase 3: Evidence Redaction

| Task | Files | Output |
|------|-------|--------|
| Add redaction fixtures and test | `tests/validation/redaction.sh` | Red test for sensitive sample values |
| Implement sanitizer helpers | `scripts/azure-validation-run.sh` | Sanitized plan/output artifacts |
| Route agent evidence to sanitized files | `scripts/azure-validation-run.sh` | Agent-safe paths documented |

### Phase 4: H1-H3 Validation Hardening

| Task | Files | Output |
|------|-------|--------|
| Add node readiness fixture tests | `tests/validation/validate-h1-node-check.sh` | JSON readiness tested |
| Replace text parsing with JSON | `scripts/azure-validation-run.sh`, `scripts/validate-deployment.sh` | Robust H1 validation |
| Add scope-aware component checks | same scripts | Enabled components fail closed |

### Phase 5: Entra Terraform Callback

| Task | Files | Output |
|------|-------|--------|
| Add callback URL static test | `tests/terraform/security-callback.sh` | Hardcoded callback detected |
| Pass portal domain into security module | `terraform/main.tf`, `terraform/modules/security/*` | Correct redirect URI |
| Validate Terraform | `terraform/` | `terraform validate` passes |

### Phase 6: Safe Resume

| Task | Files | Output |
|------|-------|--------|
| Add resume mismatch test | `tests/deploy/resume.sh` | Old numeric checkpoint rejected/migrated safely |
| Store checkpoint metadata | `scripts/deploy-full.sh` | JSON checkpoint |
| Validate resume context | `scripts/deploy-full.sh` | Wrong environment/horizon fails |

### Phase 7: Evidence Bundle

| Task | Files | Output |
|------|-------|--------|
| Add evidence bundle test | `tests/validation/evidence.sh` | Sanitized bundle validated |
| Implement evidence phase | `scripts/azure-validation-run.sh` | Bundle generated after inventory/docs |
| Update runbook | `docs/guides/AZURE_VALIDATION_RUNBOOK.md` | Evidence format documented |

### Phase 8: Fork-Ready ArgoCD

| Task | Files | Output |
|------|-------|--------|
| Add static fork URL test | `tests/validation/fork-ready-argocd.sh` | Fixed repo names detected |
| Template repo inputs | `argocd/**`, render scripts | Customer fork variables drive URLs |
| Update docs | `README.md`, guides | Customer path documented |

### Phase 9: Live Verification

| Task | Files | Output |
|------|-------|--------|
| Run local verification | tests and shell checks | Local green gate |
| Resume AKS validation | `runs/azure-validation/contoso-prod-nogithub-finalcheck` | H1-H3 evidence |
| Capture inventory/evidence | run artifacts | Sanitized handoff package |

## 3. Validation Commands

```bash
bash -n scripts/*.sh
/opt/homebrew/bin/bash tests/wizard/run.sh
bash tests/validation/redaction.sh
bash tests/validation/write-validation-tfvars-scope.sh
bash tests/validation/validate-h1-node-check.sh
bash tests/deploy/resume.sh
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```

Backstage validation after identity-related code changes:

```bash
cd backstage
yarn tsc
yarn workspace app build
```

Live validation after local green gate:

```bash
scripts/azure-validation-run.sh --phase validate-all --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
scripts/azure-validation-run.sh --phase inventory --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
scripts/azure-validation-run.sh --phase docs --run-id contoso-prod-nogithub-finalcheck --customer-name contoso --environment prod
```

## 4. Human Gates

| Gate | Required Before |
|------|-----------------|
| Review redaction output | Any evidence handoff |
| Confirm tenant inputs | `platform` or `full` validation scope |
| Confirm apply | Any Terraform apply |
| Confirm destroy | Any Terraform destroy or resource group delete |
