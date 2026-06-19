---
title: "Enterprise Validation Hardening Specification"
description: "EARS-style requirements for Open Horizons enterprise validation hardening."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["specification", "EARS", "validation", "enterprise"]
---

# Enterprise Validation Hardening Specification

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial EARS specification |

## Table of Contents

- [1. Requirements](#1-requirements)
- [2. Acceptance Criteria](#2-acceptance-criteria)
- [3. Failure Modes](#3-failure-modes)

## 1. Requirements

### Ubiquitous Requirements

- REQ-SDD-001: The system shall provide a complete enterprise validation hardening SDD package.
- REQ-SDD-002: The system shall map every acceptance criterion to automated or manual evidence.
- REQ-SEC-001: The system shall write agent-safe evidence artifacts that redact secrets and sensitive resource identifiers.
- REQ-SEC-002: The system shall preserve raw runtime artifacts only in ignored run directories.
- REQ-ID-001: The system shall accept `AUTH_PROVIDER=entra` with `GITHUB_IDENTITY_MODE=enterprise-managed-users`.
- REQ-ID-002: The system shall reject `GITHUB_IDENTITY_MODE=enterprise-managed-users` unless `AUTH_PROVIDER=entra`.
- REQ-ID-003: The system shall render Microsoft Entra ID authentication configuration when `AUTH_PROVIDER=entra`.
- REQ-ID-004: The system shall derive Entra callback URLs from the configured portal domain.
- REQ-VAL-001: The system shall evaluate AKS node readiness from Kubernetes JSON conditions.
- REQ-VAL-002: The system shall fail validation when an enabled H1, H2, or H3 component is missing or unhealthy.
- REQ-VAL-003: The system shall mark optional components as skipped only when the selected scope excludes them.
- REQ-RESUME-001: The system shall store deployment checkpoints with environment and horizon metadata.
- REQ-RESUME-002: The system shall refuse resume when checkpoint metadata differs from current arguments.
- REQ-FORK-001: The system shall render customer-facing ArgoCD repository URLs from customer fork variables.
- REQ-DOC-001: The system shall document tested enterprise fork commands and evidence expectations.

### Event-Driven Requirements

- REQ-EVID-001: When Terraform plan JSON is produced, the system shall create an agent-safe sanitized plan summary before agent review.
- REQ-EVID-002: When Terraform output JSON is produced, the system shall create an agent-safe sanitized output file before agent review.
- REQ-EVID-003: When validation phases complete, the system shall produce a sanitized evidence summary.
- REQ-LIVE-001: When local TDD checks pass, the system shall resume real validation from the existing applied checkpoint without running apply.

### Unwanted Behavior Requirements

- REQ-UB-001: If a sanitized artifact contains a known secret-like value, then the redaction test shall fail.
- REQ-UB-002: If a customer-facing manifest contains an unrendered Open Horizons repository assumption, then fork-readiness validation shall fail.
- REQ-UB-003: If a script tries to resume a deployment with mismatched environment or horizon, then resume shall fail before any deployment phase runs.

## 2. Acceptance Criteria

- AC-01: Given the SDD package path, when a reviewer opens it, then FRD, NFRD, Constitution, Specification, Implementation Plan, Tasks, Test Matrix, and Evidence documents exist.
- AC-02: Given `AUTH_PROVIDER=entra` and `GITHUB_IDENTITY_MODE=enterprise-managed-users`, when wizard validation runs, then it succeeds and records the identity block.
- AC-03: Given `GITHUB_IDENTITY_MODE=enterprise-managed-users` and `AUTH_PROVIDER=github`, when wizard validation runs, then it fails before deployment.
- AC-04: Given `GITHUB_IDENTITY_MODE=enterprise-managed-users` and `AUTH_PROVIDER=guest`, when wizard validation runs, then it fails before deployment.
- AC-05: Given an Entra render input, when `render-k8s.sh` runs in dry-run mode, then the rendered auth block contains the Microsoft provider and not the GitHub provider.
- AC-06: Given Terraform output containing sensitive fields, when redaction runs, then sanitized output masks or removes those fields.
- AC-07: Given Terraform plan JSON containing password, token, kubeconfig, or resource IDs, when redaction runs, then sanitized output contains no unmasked sensitive patterns.
- AC-08: Given Kubernetes nodes JSON with Ready=True, when H1 validation runs, then node validation passes.
- AC-09: Given Kubernetes nodes JSON with no Ready=True nodes, when H1 validation runs, then node validation fails.
- AC-10: Given H2 or H3 component flags enabled, when a required namespace or pod is missing, then validation fails.
- AC-11: Given a checkpoint for `prod/all`, when resume is requested for `dev/all`, then resume fails before deployment.
- AC-12: Given customer GitHub org and repo inputs, when ArgoCD manifests render, then repository URLs reference those inputs and no fixed Open Horizons repository name remains.
- AC-13: Given local tests pass, when live validation resumes, then the system runs `validate-all`, `inventory`, and evidence phases without `apply`.

## 3. Failure Modes

| Failure | Expected Behavior | Owner |
|---------|-------------------|-------|
| Missing client inputs | Fail with structured `errors.json` | deploy |
| Invalid EMU combination | Fail before render/deploy | Backstage Expert |
| Secret-like artifact value | Fail test and block evidence handoff | security |
| No Ready AKS nodes | Fail H1 validation | sre |
| Missing enabled H2/H3 component | Fail H2/H3 validation | sre |
| Callback URL mismatch | Fail Terraform/static validation | Azure Portal Deploy |
| Resume mismatch | Fail before phase execution | deploy |
| DNS/network outage | Mark environmental and retry-safe | Azure Portal Deploy |
