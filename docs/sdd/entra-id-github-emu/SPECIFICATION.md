---
title: "Entra ID and GitHub Enterprise Managed Users Specification"
description: "Machine-parseable EARS requirements for Open Horizons Entra ID plus GitHub EMU support."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["specification", "EARS", "identity", "entra-id", "github-emu"]
---

# Entra ID and GitHub Enterprise Managed Users Specification

> Machine-parseable requirements using EARS notation.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial specification |

## Overview

**System:** Open Horizons identity configuration process

**Objective:** Add Entra ID sign-in with GitHub Enterprise Managed Users as a first-class enterprise identity option across wizard, scripts, Backstage runtime, agents, and documentation.

**Constitution:** Follow the Open Horizons platform guidance in the repository instructions and keep secrets out of generated SDD and wizard manifest artifacts.

## Functional Requirements

### Ubiquitous

- REQ-U01: The system shall separate Backstage sign-in provider from GitHub identity governance mode.
- REQ-U02: The system shall support `AUTH_PROVIDER=entra` with `GITHUB_IDENTITY_MODE=enterprise-managed-users`.
- REQ-U03: The system shall keep GitHub technical integration credentials separate from user sign-in credentials.
- REQ-U04: The system shall never write Entra client secrets, GitHub tokens, GitHub private keys, or password values to `.openhorizons-selection.yaml`.
- REQ-U05: The system shall retain compatibility with existing `github`, `entra`, and `guest` auth providers.

### Event-Driven

- REQ-E01: When the installer selects `AUTH_PROVIDER=entra`, the wizard shall ask for the GitHub identity mode.
- REQ-E02: When the installer selects `GITHUB_IDENTITY_MODE=enterprise-managed-users`, the wizard shall write `GITHUB_IDENTITY_MODE=enterprise-managed-users` to `.env`.
- REQ-E03: When the wizard writes `.openhorizons-selection.yaml`, it shall include an `identity` block with non-secret identity strategy values.
- REQ-E04: When Kubernetes manifests are rendered for Entra mode, the render script shall include Entra client ID, client secret, and tenant ID in the secrets checklist.
- REQ-E05: When Kubernetes manifests are rendered for EMU mode, the render script shall remind operators that GitHub technical credentials remain required for GitHub integrations.
- REQ-E06: When Backstage starts with Microsoft auth configured, the backend shall register the Microsoft auth provider module.

### State-Driven

- REQ-S01: While `GITHUB_IDENTITY_MODE=enterprise-managed-users`, the system shall require `AUTH_PROVIDER=entra`.
- REQ-S02: While `AUTH_PROVIDER=entra`, the sign-in UI shall present Microsoft Entra ID as the primary sign-in option.
- REQ-S03: While GitHub integrations are enabled, the system shall use GitHub App or token credentials for repository, catalog, Actions, PR, Codespaces, package, and metrics integration.

### Conditional

- REQ-C01: If `GITHUB_IDENTITY_MODE=enterprise-managed-users` and `AUTH_PROVIDER` is not `entra`, then validation shall fail before manifest generation or deployment.
- REQ-C02: If `AUTH_PROVIDER=guest`, then `GITHUB_IDENTITY_MODE` shall default to `standard`.
- REQ-C03: If a GitHub Enterprise slug is provided, then agents and runbooks shall use it as metadata only and shall not treat it as a secret.

### Optional Features

- REQ-O01: Where Microsoft Graph catalog ingestion is configured in a later implementation phase, the system shall prefer Entra users and groups as the Backstage identity source for EMU deployments.

## Non-Functional Requirements

| ID | Category | Requirement | Target |
|----|----------|-------------|--------|
| NFR-01 | Security | Secrets excluded from selection manifest and docs | 100 percent exclusion by schema and review |
| NFR-02 | Operability | Config summaries show auth and identity mode | Visible in wizard/render output |
| NFR-03 | Compatibility | Existing auth modes continue to validate | No regression in wizard tests |
| NFR-04 | Auditability | Agent guidance records identity strategy | Included in Deploy, Backstage, and GitHub agent instructions |
| NFR-05 | Testability | Scripts and manifests validate locally | Shell syntax, schema, render, and Backstage build checks |

## Failure Modes

| Failure | Expected Behavior | Recovery |
|---------|-------------------|----------|
| EMU selected without Entra auth | Validation fails with a clear message | Set `AUTH_PROVIDER=entra` or change identity mode |
| Missing Entra app credentials | Render checklist identifies missing secret inputs | Create App Registration and Kubernetes/Key Vault secrets |
| GitHub App credentials missing in EMU mode | GitHub-backed portal features fail pre-deployment validation or show integration errors | Create or install GitHub App and provide token/private key secrets |
| User not present in catalog | Backstage sign-in resolver cannot map the identity | Add catalog ingestion or user entity with matching email/UPN |

## Acceptance Criteria

- [ ] AC-01: Given `AUTH_PROVIDER=entra`, when the wizard runs interactively, then it asks for GitHub identity mode.
- [ ] AC-02: Given `AUTH_PROVIDER=entra` and `GITHUB_IDENTITY_MODE=enterprise-managed-users`, when the wizard writes `.env`, then both keys are present with the selected values.
- [ ] AC-03: Given a selection manifest with `identity.github_identity_mode=enterprise-managed-users` and `identity.auth_provider=github`, when validation runs, then validation fails.
- [ ] AC-04: Given an Entra/EMU `.env`, when `scripts/render-k8s.sh --dry-run` runs, then the output shows auth `entra`, identity `enterprise-managed-users`, and Entra secret commands.
- [ ] AC-05: Given Backstage dependencies are installed, when backend build runs, then Microsoft auth provider registration compiles.
- [ ] AC-06: Given the rendered Backstage config has Microsoft provider credentials, when the sign-in page loads, then the primary button says `Sign in with Microsoft Entra ID`.

## Out of Scope

- GitHub Enterprise EMU tenant creation.
- Entra Conditional Access policy authoring.
- Microsoft Graph catalog provider rollout beyond documented preference.
- Removing GitHub integration support.

## Dependencies

| Dependency | Type | Owner | SLA |
|------------|------|-------|-----|
| Microsoft Entra ID | Identity provider | Customer Entra admin | Customer-owned |
| GitHub Enterprise Cloud EMU | GitHub identity governance | Customer GitHub enterprise admin | Customer-owned |
| Backstage Microsoft auth provider | Runtime package | Open Horizons platform | Repository-managed |
| GitHub App or token | Technical GitHub integration | Customer GitHub org admin | Customer-owned |

## Glossary

| Term | Definition |
|------|------------|
| Entra ID | Microsoft cloud identity platform used for Backstage sign-in in this option. |
| GitHub EMU | GitHub Enterprise Managed Users, where enterprise accounts are provisioned and governed by an external IdP. |
| Auth provider | Backstage sign-in provider selected by `AUTH_PROVIDER`. |
| GitHub identity mode | GitHub governance mode selected by `GITHUB_IDENTITY_MODE`. |
| Technical integration | Non-user GitHub credential path used by Backstage plugins and automation. |

## References

- [Backstage Microsoft auth provider](https://backstage.io/docs/auth/microsoft/provider/)
- [Backstage GitHub integration](https://backstage.io/docs/integrations/github/)
- [GitHub Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users)
- [Microsoft Entra provisioning for GitHub Enterprise Managed User](https://learn.microsoft.com/en-us/entra/identity/saas-apps/github-enterprise-managed-user-provisioning-tutorial)
- [Microsoft Entra app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
