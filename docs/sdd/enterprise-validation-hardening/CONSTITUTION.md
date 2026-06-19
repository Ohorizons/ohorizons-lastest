---
title: "Enterprise Validation Hardening Constitution"
description: "Non-negotiable principles for implementing and validating enterprise Open Horizons readiness."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["constitution", "validation", "security", "sdd"]
---

# Enterprise Validation Hardening Constitution

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial constitution |

## 1. Non-Negotiable Principles

### Principle 1: Evidence Must Be Safe By Default

Agents and reviewers consume sanitized artifacts by default. Raw Terraform plans, Terraform outputs, kubeconfig, CLI logs, and cloud inventories may exist only in ignored run directories and must not be pasted into documentation, issues, or chat.

### Principle 2: Tests Precede Fixes

Every implementation change must start with a failing test or a documented manual acceptance check. The implementation is complete only when the test passes and evidence is recorded.

### Principle 3: Identity Authority Is Explicit

Backstage sign-in authority and GitHub technical integration are separate. In GitHub EMU mode, Entra ID is the sign-in authority and GitHub App or token credentials remain technical integration credentials.

### Principle 4: Live Cloud Mutation Requires Human Gate

Terraform apply, Terraform destroy, resource group deletion, and any mutating Azure or Kubernetes action outside dry-run require explicit operator confirmation. Hardening work must prefer local/stubbed tests before live validation.

### Principle 5: Resume Must Be Context-Safe

No deployment resume may continue if the environment, horizon, tfvars checksum, or run identifier differs from the saved checkpoint. Ambiguous resume must fail closed.

### Principle 6: Fork-Ready Means No Hidden Open Horizons Assumptions

Customer-facing templates must render from customer fork variables. Repository names, GitHub organizations, branches, and GitOps repository assumptions must be explicit, documented, and testable.

## 2. Trade-Off Order

When requirements conflict, use this order:

1. Secret safety and tenant data protection.
2. Human approval gates for cloud mutation.
3. Repeatable test evidence.
4. Enterprise fork portability.
5. Operator convenience.

## 3. Prohibited Work

- Do not commit `.env`, `.tfvars`, Terraform state, raw run artifacts, or secrets.
- Do not weaken Entra plus EMU validation to make no-GitHub smoke tests pass.
- Do not run apply or destroy as part of local hardening.
- Do not treat warnings as success for enabled H1-H3 components.

## 4. Required Completion Evidence

A slice is complete only when these are true:

1. Its Red test fails before implementation or its manual evidence gap is documented.
2. Its Green implementation passes focused tests.
3. Shell syntax checks pass for touched scripts.
4. The test matrix is updated with command and result.
5. Any live validation evidence is sanitized before review.
