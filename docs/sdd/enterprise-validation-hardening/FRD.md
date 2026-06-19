---
title: "Enterprise Validation Hardening Functional Requirements Document"
description: "What Open Horizons must do to validate enterprise customer forks safely and repeatably."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
project_type: "brownfield"
tags: ["FRD", "enterprise-validation", "open-horizons"]
---

# Enterprise Validation Hardening Functional Requirements Document

> Open Horizons must provide a safe, testable, evidence-driven validation workflow for enterprise customer forks using Entra ID, GitHub EMU, Azure, AKS, and Backstage.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial FRD |

## Table of Contents

- [1. System Overview](#1-system-overview)
- [2. Stakeholder Roles](#2-stakeholder-roles)
- [3. SDD Traceability](#3-sdd-traceability)
- [4. Identity Validation](#4-identity-validation)
- [5. Evidence Handling](#5-evidence-handling)
- [6. Deployment Validation](#6-deployment-validation)
- [7. Fork Readiness](#7-fork-readiness)
- [8. Functional Requirements Summary](#8-functional-requirements-summary)
- [9. Implementation Phases](#9-implementation-phases)

## 1. System Overview

### 1.1 What This System Does

The system validates whether a customer can fork Open Horizons, configure enterprise identity, deploy or reuse Azure infrastructure, verify AKS H1-H3 platform health, and collect evidence without exposing secrets. It serves platform engineers, security reviewers, Backstage operators, and agent supervisors.

### 1.2 Current State

A real Azure `nogithub` validation run has completed plan and apply for `contoso-prod-nogithub-finalcheck`. The repository contains SDD documents for Entra ID plus GitHub EMU, wizard tests, deployment scripts, Backstage auth wiring, Terraform modules, and runbook documentation.

The current gaps are post-apply H1-H3 evidence, test coverage for Entra plus EMU, agent-safe evidence redaction, resume safety, callback URL correctness, and fork-ready ArgoCD repository URLs.

### 1.3 Out of Scope

- Customer tenant administration: Entra Conditional Access, SCIM, SAML, and GitHub Enterprise settings are externally controlled.
- Destructive operations: Terraform destroy, resource group deletion, or live apply are not part of this hardening slice.
- Product redesign: UI, plugin catalog, architecture, and cloud topology changes unrelated to validation are excluded.
- Secret provisioning: Real tokens, client secrets, private keys, and API keys remain out of repository scope.

### 1.4 Documented Assumptions

| # | Assumption | Consequence if Wrong |
|---|------------|---------------------|
| A1 | `contoso-prod-nogithub-finalcheck` is the latest applied checkpoint to validate first. | Validation may target the wrong AKS/RG and must be re-baselined. |
| A2 | Entra ID is the Backstage sign-in authority for GitHub EMU. | Identity tests and docs must be revised. |
| A3 | GitHub App or token credentials remain required for technical GitHub features. | Catalog and scaffolder validation would be incomplete. |
| A4 | Agents may read run artifacts, so sanitized evidence is mandatory. | Raw logs could leak sensitive data into chat or issues. |

## 2. Stakeholder Roles

| Role | Who They Are | Key Permissions |
|------|--------------|-----------------|
| Deploy supervisor | Agent or operator running validation phases | Run safe phases, request approval for apply/destroy |
| Platform engineer | Customer or partner engineer implementing Open Horizons | Configure `.env`, `.tfvars`, AKS, Backstage, ArgoCD |
| Security reviewer | Enterprise reviewer validating controls | Inspect redacted evidence, identity model, secret handling |
| Backstage operator | Portal owner | Validate sign-in, catalog, scaffolder, TechDocs, AI plugins |
| GitHub enterprise admin | Owner of GitHub org/enterprise integration | Install GitHub App, verify EMU technical integration |
| Entra admin | Owner of tenant application and provisioning | Create app registration, redirect URI, SCIM/SAML setup |

## 3. SDD Traceability

### FR-SDD-01: Package Completeness, Priority P0

The system must provide a complete SDD package for enterprise validation hardening.

1. The package must include FRD, NFRD, Constitution, Specification, Implementation Plan, Tasks, Test Matrix, and Evidence documents.
2. Each document must state scope and link to related validation artifacts.

**Acceptance signal:** All package documents exist and cross-reference each other.

### FR-SDD-02: Acceptance Mapping, Priority P0

The system must map every acceptance criterion to a test, manual verification, or evidence artifact.

1. Automated tests must include file paths and commands.
2. Manual checks must include owner, inputs, and evidence format.

**Acceptance signal:** `TEST_MATRIX.md` contains no acceptance criterion without a validation method.

## 4. Identity Validation

### FR-ID-01: Entra Plus EMU Valid Configuration, Priority P0

The system must accept `AUTH_PROVIDER=entra` with `GITHUB_IDENTITY_MODE=enterprise-managed-users`.

1. The wizard manifest may store the non-secret identity mode.
2. Kubernetes render output must select the Microsoft auth provider fragment.
3. Documentation must explain that GitHub technical integration remains required.

**Acceptance signal:** Focused tests pass for a valid Entra plus EMU selection and rendered auth fragment.

### FR-ID-02: Invalid EMU Combinations, Priority P0

The system must reject `GITHUB_IDENTITY_MODE=enterprise-managed-users` unless `AUTH_PROVIDER=entra` is selected.

1. GitHub sign-in plus EMU must fail validation.
2. Guest sign-in plus EMU must fail validation.
3. Failure messages must not echo secrets.

**Acceptance signal:** Wizard and render tests fail invalid combinations with exit code 2 or a documented validation error.

### FR-ID-03: Entra Callback URL Correctness, Priority P0

The system must configure and document the Backstage Entra callback URL from the actual portal domain.

1. The Terraform Entra app registration must use the configured portal domain.
2. Documentation must show `https://<portal-url>/api/auth/microsoft/handler/frame`.

**Acceptance signal:** Terraform validation and static checks confirm no hardcoded `backstage.<customer>.com` callback remains.

## 5. Evidence Handling

### FR-EVID-01: Agent-Safe Artifact Generation, Priority P0

The system must generate sanitized evidence files for agents and reviewers.

1. Terraform plan JSON and output JSON must have sensitive values removed or masked.
2. Subscription IDs, resource IDs, kubeconfig, tokens, passwords, certificates, and private keys must not appear in agent-safe artifacts.
3. Raw artifacts may remain only in ignored runtime directories.

**Acceptance signal:** Redaction tests prove known sensitive sample values are absent from sanitized output.

### FR-EVID-02: Evidence Bundle, Priority P1

The system must produce a consolidated evidence bundle after validation phases.

1. The bundle must include sanitized status, errors, resource summary, pod summary, validation matrix, and run timeline.
2. The bundle must include hashes of included files.

**Acceptance signal:** Evidence phase creates a deterministic bundle with no secret-pattern matches.

## 6. Deployment Validation

### FR-VAL-01: JSON-Based H1 Health Checks, Priority P0

The system must validate AKS node readiness using structured data.

1. Node readiness must be computed from Kubernetes JSON conditions.
2. The script must fail if no nodes are Ready.
3. The script must capture pod and event snapshots as evidence.

**Acceptance signal:** Stubbed tests pass for ready, not-ready, and empty cluster JSON fixtures.

### FR-VAL-02: Scope-Aware H2 And H3 Checks, Priority P0

The system must validate H2 and H3 components based on selected validation scope and enabled capabilities.

1. Expected namespaces and services must be checked when enabled.
2. Missing enabled components must fail, not only warn.
3. Optional components must be recorded as skipped with rationale.

**Acceptance signal:** Validation tests demonstrate failures for missing required H2/H3 components and passes for skipped optional components.

### FR-VAL-03: Safe Resume, Priority P1

The system must prevent deployment resume across mismatched environment or horizon values.

1. Checkpoints must store environment, horizon, phase, and timestamp.
2. Resume must stop if current arguments differ from checkpoint metadata.

**Acceptance signal:** Resume tests reject mismatched environment or horizon.

## 7. Fork Readiness

### FR-FORK-01: GitOps Repository Templating, Priority P0

The system must render ArgoCD repository URLs from customer fork variables.

1. Application manifests must not hardcode Open Horizons repository names for customer deployments.
2. `GITHUB_ORG`, `GITHUB_REPO`, and optional GitOps repository variables must drive rendered URLs.

**Acceptance signal:** Static tests confirm no customer-facing ArgoCD manifest contains unrendered fixed repository names.

### FR-FORK-02: Customer Documentation Path, Priority P1

The system must document the enterprise fork flow from prerequisites through validation evidence.

1. README and installation docs must link to validation hardening guidance.
2. Scripts README must show correct commands.

**Acceptance signal:** Documentation checks find correct commands and links.

## 8. Functional Requirements Summary

| ID | Requirement | Domain | Priority | Phase |
|----|-------------|--------|----------|-------|
| FR-SDD-01 | Package completeness | SDD | P0 | Phase 1 |
| FR-SDD-02 | Acceptance mapping | SDD | P0 | Phase 1 |
| FR-ID-01 | Entra plus EMU valid configuration | Identity | P0 | Phase 2 |
| FR-ID-02 | Invalid EMU combinations | Identity | P0 | Phase 2 |
| FR-ID-03 | Entra callback URL correctness | Identity | P0 | Phase 5 |
| FR-EVID-01 | Agent-safe artifact generation | Evidence | P0 | Phase 3 |
| FR-EVID-02 | Evidence bundle | Evidence | P1 | Phase 7 |
| FR-VAL-01 | JSON-based H1 health checks | Validation | P0 | Phase 4 |
| FR-VAL-02 | Scope-aware H2 and H3 checks | Validation | P0 | Phase 4 |
| FR-VAL-03 | Safe resume | Validation | P1 | Phase 6 |
| FR-FORK-01 | GitOps repository templating | Fork readiness | P0 | Phase 8 |
| FR-FORK-02 | Customer documentation path | Fork readiness | P1 | Phase 9 |

**P0=9, P1=3, P2=0, P3=0. Total=12.**

## 9. Implementation Phases

| Phase | Requirements | Objective | State After |
|-------|--------------|-----------|-------------|
| Phase 1, SDD | FR-SDD-01, FR-SDD-02 | Establish implementation contract | All docs and matrix created |
| Phase 2, Identity Tests | FR-ID-01, FR-ID-02 | Add Red tests for Entra plus EMU | Invalid/valid identity paths tested |
| Phase 3, Evidence Redaction | FR-EVID-01 | Prevent sensitive artifact exposure | Sanitized outputs are default for agents |
| Phase 4, H1-H3 Validation | FR-VAL-01, FR-VAL-02 | Harden AKS checks | Stubbed and live validation are reliable |
| Phase 5, Entra Terraform | FR-ID-03 | Fix callback URL | Portal domain drives app registration |
| Phase 6, Resume Safety | FR-VAL-03 | Prevent wrong-context resumes | JSON checkpoint guards in place |
| Phase 7, Evidence Bundle | FR-EVID-02 | Produce audit-ready artifacts | Evidence package generated |
| Phase 8, Fork-Ready GitOps | FR-FORK-01 | Remove hardcoded repo assumptions | Customer fork renders cleanly |
| Phase 9, Docs | FR-FORK-02 | Update enterprise installation path | Docs match tested flow |
