---
title: "Enterprise Validation Hardening Tasks"
description: "Atomic task list for TDD implementation of enterprise validation hardening."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["tasks", "TDD", "validation"]
---

# Enterprise Validation Hardening Tasks

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial task breakdown |

## Status Legend

| Marker | Meaning |
|--------|---------|
| `[ ]` | Not started |
| `[~]` | In progress |
| `[x]` | Done |
| `[B]` | Blocked |

## Phase 1: SDD Contract

- [x] T-001 Create `docs/sdd/enterprise-validation-hardening/README.md`.
- [x] T-002 Create enterprise validation FRD.
- [x] T-003 Create enterprise validation NFRD.
- [x] T-004 Create enterprise validation Constitution.
- [x] T-005 Create enterprise validation Specification.
- [x] T-006 Create implementation plan.
- [x] T-007 Create task list.
- [x] T-008 Create test matrix.
- [x] T-009 Create evidence guide.
- [x] T-010 Add Entra/EMU local Constitution.
- [ ] T-011 Update Entra/EMU implementation plan with acceptance mapping.

## Phase 2: Identity Red Tests

- [x] T-020 Add valid Entra plus EMU wizard smoke test.
- [x] T-021 Add invalid GitHub plus EMU smoke test.
- [x] T-022 Add invalid guest plus EMU smoke test.
- [x] T-023 Add Entra render dry-run test.
- [x] T-024 Run wizard tests and confirm Red/Green state.

## Phase 3: Evidence Redaction

- [x] T-030 Add redaction fixtures.
- [x] T-031 Add `tests/validation/redaction.sh`.
- [x] T-032 Implement redaction helper in `scripts/azure-validation-run.sh`.
- [x] T-033 Write sanitized Terraform plan artifact.
- [x] T-034 Write sanitized Terraform output artifact.
- [x] T-035 Add validation-scope tfvars test and local generation phase.
- [x] T-036 Update runbook with safe artifact names.

## Phase 4: H1-H3 Validation

- [x] T-040 Add Kubernetes node JSON fixtures.
- [x] T-041 Add `tests/validation/validate-h1-node-check.sh`.
- [x] T-042 Replace node readiness text parsing with JSON parsing.
- [x] T-043 Add scope-aware H2 checks.
- [x] T-044 Add scope-aware H3 checks.
- [x] T-045 Verify live validation phase remains non-mutating.

## Phase 5: Entra Terraform Callback

- [x] T-050 Add callback URL static test.
- [x] T-051 Add portal URL variable to security module.
- [x] T-052 Pass portal URL from root module.
- [x] T-053 Update outputs/docs if needed.
- [x] T-054 Run Terraform validation.

## Phase 6: Safe Resume

- [x] T-060 Add deploy resume tests.
- [x] T-061 Replace numeric checkpoint with JSON metadata.
- [x] T-062 Validate resume environment and horizon.
- [x] T-063 Document resume behavior.

## Phase 7: Evidence Bundle

- [x] T-070 Add evidence bundle test.
- [x] T-071 Implement evidence phase or docs extension.
- [x] T-072 Add file hashes.
- [x] T-073 Check sanitized bundle for secret patterns.

## Phase 8: Fork-Ready ArgoCD

- [x] T-080 Add static fork-readiness test.
- [x] T-081 Parameterize customer-facing ArgoCD repo URLs.
- [x] T-082 Add render variables for GitOps repo strategy.
- [x] T-083 Update installation docs.

## Phase 9: Live Verification

- [x] T-090 Run local shell syntax checks.
- [x] T-091 Run wizard tests.
- [x] T-092 Run validation tests.
- [x] T-093 Run Terraform validation.
- [ ] T-094 Run Backstage validation if identity app code changed.
- [x] T-095 Run live `validate-all` against `contoso-prod-nogithub-finalcheck`.
- [x] T-096 Run live `inventory` and `docs` evidence capture.
