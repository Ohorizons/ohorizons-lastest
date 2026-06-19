---
title: "Enterprise Validation Hardening Non-Functional Requirements Document"
description: "Quality constraints for secure, repeatable Open Horizons enterprise validation."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
companion_document: "FRD.md"
tags: ["NFRD", "enterprise-validation", "security", "testability"]
---

# Enterprise Validation Hardening Non-Functional Requirements Document

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial NFRD |

## Table of Contents

- [1. Deployment Contexts](#1-deployment-contexts)
- [2. NFR-01: Security](#2-nfr-01-security-p0)
- [3. NFR-02: Testability](#3-nfr-02-testability-p0)
- [4. NFR-03: Operability](#4-nfr-03-operability-p0)
- [5. NFR-04: Reliability](#5-nfr-04-reliability-p0)
- [6. NFR-05: Compatibility](#6-nfr-05-compatibility-p1)
- [7. NFR-06: Documentation Quality](#7-nfr-06-documentation-quality-p1)

## 1. Deployment Contexts

| Context | Description | SLA Applies |
|---------|-------------|-------------|
| Local repository | Script, Terraform, Backstage, and manifest validation before tenant use | No |
| Azure validation tenant | Existing Azure subscription and AKS checkpoint | Yes |
| Customer enterprise fork | Customer-owned GitHub org, Entra tenant, and Azure subscription | Yes |
| CI validation | Non-secret checks run on PRs | Yes |

## 2. NFR-01: Security, P0

| Control | Requirement |
|---------|-------------|
| Secrets | No secret may be committed, emitted in docs, or copied into agent-safe artifacts. |
| Artifact redaction | Terraform outputs, plans, kubeconfig, and CLI evidence must be sanitized before agent review. |
| Identity | Entra ID must be the sign-in authority for GitHub EMU deployments. |
| GitHub integration | GitHub App or token credentials remain technical integration credentials, not sign-in authority in EMU mode. |
| Human gates | Apply and destroy require explicit confirmation flags. |

Sensitive patterns include `password`, `secret`, `token`, `private_key`, `client_secret`, `kube_config`, certificates, access keys, `ghp_`, `github_pat_`, PEM blocks, and Azure resource IDs containing subscription GUIDs.

## 3. NFR-02: Testability, P0

Each implementation slice must have a Red test before Green changes. Tests must run without a live tenant unless explicitly labeled as live validation.

| Test Type | Target |
|-----------|--------|
| Shell smoke tests | Wizard, validation, deployment scripts |
| Stubbed CLI tests | `kubectl`, `az`, `terraform` branches without cloud access |
| Static checks | Terraform callback URLs, ArgoCD fork URLs, docs commands |
| Live checks | AKS H1-H3 validation after local tests pass |

Minimum local gate before live validation:

```bash
bash -n scripts/*.sh
/opt/homebrew/bin/bash tests/wizard/run.sh
bash tests/validation/redaction.sh
bash tests/validation/write-validation-tfvars-scope.sh
bash tests/validation/validate-h1-node-check.sh
bash tests/deploy/resume.sh
```

## 4. NFR-03: Operability, P0

Validation scripts must produce structured status and error artifacts for agent supervisors.

| Artifact | Requirement |
|----------|-------------|
| `status.json` | Current phase, status, owner, retry safety, timestamp |
| `errors.json` | Sanitized error list with owner and log pointer |
| `summary.md` | Timeline suitable for human review |
| `fixes.md` | Append-only remediation log |
| Evidence bundle | Sanitized summary for customer/partner handoff |

## 5. NFR-04: Reliability, P0

Validation must fail closed for enabled components. Optional components may be skipped only when the selected scope or feature flags declare them out of scope.

Resume behavior must be context-safe. The system must not resume a deploy with mismatched environment, horizon, tfvars checksum, or run identifier.

## 6. NFR-05: Compatibility, P1

The scripts must remain compatible with the repository's current macOS development path and CI runners. Wizard tests require Bash 4+; shell scripts should avoid Bash 5-only features unless tests explicitly run with Bash 5.

The validation path must support these scopes:

| Scope | Cloud dependency | GitHub dependency |
|-------|------------------|-------------------|
| `infra` | Azure only | None |
| `nogithub` | Azure plus AKS runtime | None for sign-in/catalog |
| `platform` | Azure plus AKS plus GitHub technical inputs | GitHub org/app/token metadata |
| `full` | Complete H1-H3 plus enterprise identity | GitHub org/app/token and Entra inputs |

## 7. NFR-06: Documentation Quality, P1

Markdown documents must include YAML frontmatter, change logs, links to related documents, and concrete commands. Commands must match script interfaces and must not include real secrets or tenant-specific values.
