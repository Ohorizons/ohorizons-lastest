---
title: "Enterprise Validation Hardening"
description: "SDD package for hardening Open Horizons enterprise fork validation across Entra ID, GitHub EMU, Azure, AKS, and evidence handling."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["sdd", "validation", "enterprise", "entra-id", "github-emu", "aks"]
---

# Enterprise Validation Hardening

> This SDD package turns the current Open Horizons Azure checkpoint into a repeatable, evidence-driven enterprise validation path for customer forks.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial enterprise validation hardening package |

## Table of Contents

- [Enterprise Validation Hardening](#enterprise-validation-hardening)
  - [Change Log](#change-log)
  - [Table of Contents](#table-of-contents)
  - [1. Purpose](#1-purpose)
  - [2. Context](#2-context)
  - [3. Documents](#3-documents)
  - [4. Execution Model](#4-execution-model)
  - [5. Validation Gates](#5-validation-gates)
  - [6. Evidence Policy](#6-evidence-policy)
  - [References](#references)

## 1. Purpose

This package defines the implementation contract for hardening Open Horizons before the next real tenant validation. The scope includes SDD traceability, TDD-first script fixes, safe evidence handling, Entra ID plus GitHub Enterprise Managed Users validation, fork-ready GitOps templates, and H1-H3 AKS checks.

The goal is not to redeploy the environment first. The next operational step is to validate the already-applied Azure checkpoint after the hardening tests and fixes are in place.

## 2. Context

The current applied validation checkpoint is `contoso-prod-nogithub-finalcheck`. Terraform plan and apply completed for a `nogithub` scope against `rg-contoso-prod`. No post-apply H1, H2, H3, inventory, or documentation evidence was found in the run directory.

The follow-up run `contoso-prod-nogithub-finalcheck-2` failed during Terraform refresh because the local resolver could not resolve `management.azure.com`. That failure is treated as environmental, not as proof of a Terraform module defect.

## 3. Documents

| Document | Purpose |
|----------|---------|
| [FRD.md](FRD.md) | Functional requirements for the hardening work |
| [NFRD.md](NFRD.md) | Quality, security, testability, and operability constraints |
| [CONSTITUTION.md](CONSTITUTION.md) | Non-negotiable rules for implementation and validation |
| [SPECIFICATION.md](SPECIFICATION.md) | Machine-checkable requirements and acceptance criteria |
| [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Phased implementation plan with TDD order |
| [TASKS.md](TASKS.md) | Atomic task list and execution status |
| [TEST_MATRIX.md](TEST_MATRIX.md) | Mapping from acceptance criteria to tests and evidence |
| [EVIDENCE.md](EVIDENCE.md) | Evidence collection and sanitization rules |

## 4. Execution Model

Implementation follows Red-Green-Refactor:

1. Write or update a failing test for each gap.
2. Implement the smallest change that makes the test pass.
3. Run focused tests and shell syntax checks.
4. Record evidence in the test matrix or validation run artifacts.
5. Continue to the next slice only when the current slice is green.

## 5. Validation Gates

| Gate | Required Evidence | Status |
|------|-------------------|--------|
| SDD complete | All documents in this package exist and cross-link | Planned |
| Identity tests | Entra plus EMU valid path and invalid combinations tested | Planned |
| Evidence redaction | Terraform plan/output sanitization tests pass | Planned |
| H1-H3 checks | JSON-based AKS health checks pass with stubs and live cluster | Planned |
| Fork readiness | ArgoCD URLs render from customer fork variables | Planned |
| Real validation | `validate-all`, `inventory`, and evidence run against AKS checkpoint | Planned |

## 6. Evidence Policy

Agents and reviewers must read sanitized evidence by default. Raw Terraform plan JSON, Terraform output JSON, kubeconfig, CLI logs, and run-specific resource inventories stay under ignored runtime paths and must not be pasted into issues, documentation, or chat.

Sanitized artifacts mask subscription IDs, resource IDs, kubeconfigs, passwords, tokens, client secrets, private keys, certificates, and long opaque credential-like values.

## References

- [Azure Validation Runbook](../../guides/AZURE_VALIDATION_RUNBOOK.md)
- [Entra ID and GitHub EMU SDD](../entra-id-github-emu/README.md)
- [Deployment Orchestration Skill](../../../.github/skills/deploy-orchestration/SKILL.md)
