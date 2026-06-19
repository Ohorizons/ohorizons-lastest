---
title: "Entra ID and GitHub Enterprise Managed Users, Non-Functional Requirements Document"
description: "Quality constraints for Open Horizons enterprise identity with Entra ID sign-in and GitHub EMU governance."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
companion_document: "FRD.md"
tags: ["NFRD", "identity", "entra-id", "github-emu", "security"]
---

# Entra ID and GitHub Enterprise Managed Users, Non-Functional Requirements Document

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial NFRD |

## Table of Contents

- [1. Deployment Contexts](#1-deployment-contexts)
- [2. NFR-01: Security, P0](#2-nfr-01-security-p0)
- [3. NFR-02: Operability, P0](#3-nfr-02-operability-p0)
- [4. NFR-03: Compatibility, P0](#4-nfr-03-compatibility-p0)
- [5. NFR-04: Auditability, P0](#5-nfr-04-auditability-p0)
- [6. NFR-05: Testability, P0](#6-nfr-05-testability-p0)
- [7. References](#7-references)

## 1. Deployment Contexts

| Context | Description | SLA Applies |
|---------|-------------|-------------|
| Production AKS | Customer-facing Open Horizons portal on AKS | Yes |
| Validation AKS | Customer validation environment for H1/H2/H3 rollout | No |
| Local Development | Backstage development through local config | No |

## 2. NFR-01: Security, P0

Auth must use Microsoft Entra ID for Backstage sign-in when `AUTH_PROVIDER=entra`. GitHub EMU mode must rely on the customer's GitHub Enterprise and Entra provisioning controls for GitHub account lifecycle. Client secrets, GitHub tokens, and private keys must never be stored in `.openhorizons-selection.yaml` or committed documents.

| Control | Requirement |
|---------|-------------|
| Secret handling | Secrets live in `.env`, Key Vault, External Secrets, or Kubernetes Secrets only. |
| Invalid combinations | `GITHUB_IDENTITY_MODE=enterprise-managed-users` requires `AUTH_PROVIDER=entra`. |
| Technical integration | GitHub App/token credentials must be scoped for platform operations and reviewed separately from user sign-in. |
| Conditional Access | MFA and Conditional Access are controlled by the customer Entra tenant. |

## 3. NFR-02: Operability, P0

The wizard, generated `.env`, selection manifest, render scripts, Kubernetes manifests, docs, and agents must describe the same identity model. Operators must be able to determine the selected mode from non-secret config summaries.

| Metric | Target |
|--------|--------|
| Config discoverability | `AUTH_PROVIDER` and `GITHUB_IDENTITY_MODE` appear in generated `.env` and wizard manifest. |
| Render feedback | Render script prints auth and identity mode before generating manifests. |
| Failure clarity | Invalid EMU combinations fail with a direct remediation message. |

## 4. NFR-03: Compatibility, P0

Existing modes must continue to work:

- `AUTH_PROVIDER=github` with `GITHUB_IDENTITY_MODE=standard`.
- `AUTH_PROVIDER=entra` with `GITHUB_IDENTITY_MODE=standard` or `saml-sso`.
- `AUTH_PROVIDER=guest` for development or no-GitHub validation only.

GitHub technical integrations must continue to use the existing GitHub integration path unless a later SDD changes provider behavior.

## 5. NFR-04: Auditability, P0

The selected identity strategy must be visible in generated manifests or logs without exposing secrets. Agent runbooks must record whether a deployment used GitHub OAuth, Entra ID, Entra with SAML SSO, or Entra with GitHub EMU.

## 6. NFR-05: Testability, P0

The implementation must include static and smoke validation:

- Shell syntax checks for changed scripts.
- Wizard tests using bash 4+ on macOS.
- Schema validation for a manifest using `identity.github_identity_mode=enterprise-managed-users`.
- Backstage TypeScript/backend build validation where dependencies are available.
- Render validation for `AUTH_PROVIDER=entra` and EMU mode.

## 7. References

- [Backstage Microsoft auth provider](https://backstage.io/docs/auth/microsoft/provider/)
- [Backstage GitHub integration](https://backstage.io/docs/integrations/github/)
- [GitHub Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users)
- [Microsoft Entra provisioning for GitHub Enterprise Managed User](https://learn.microsoft.com/en-us/entra/identity/saas-apps/github-enterprise-managed-user-provisioning-tutorial)
- [Microsoft Entra app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
