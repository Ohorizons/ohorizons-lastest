---
title: "Entra ID and GitHub Enterprise Managed Users, Functional Requirements Document"
description: "Functional requirements for adding Entra ID plus GitHub Enterprise Managed Users as a first-class Open Horizons login and identity governance option."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
project_type: "brownfield"
tags: ["FRD", "identity", "entra-id", "github-emu", "backstage"]
---

# Entra ID and GitHub Enterprise Managed Users, Functional Requirements Document

> Open Horizons must support enterprise customers that use Microsoft Entra ID for Backstage sign-in and GitHub Enterprise Managed Users for GitHub account governance.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial FRD |

## Table of Contents

- [1. System Overview](#1-system-overview)
- [2. Stakeholder Roles](#2-stakeholder-roles)
- [3. Identity Strategy Requirements](#3-identity-strategy-requirements)
- [4. Wizard and Script Requirements](#4-wizard-and-script-requirements)
- [5. Backstage Runtime Requirements](#5-backstage-runtime-requirements)
- [6. Agent Process Requirements](#6-agent-process-requirements)
- [7. Functional Requirements Summary](#7-functional-requirements-summary)
- [8. Implementation Phases](#8-implementation-phases)
- [9. References](#9-references)

## 1. System Overview

### 1.1 What This System Does

This capability adds an enterprise identity path where Open Horizons authenticates Backstage users through Microsoft Entra ID while GitHub Enterprise Managed Users governs GitHub access. The platform keeps GitHub technical integrations separate from user login so repository, Actions, catalog, and scaffolder operations continue to work.

### 1.2 Current State

Open Horizons already exposes `AUTH_PROVIDER=github|entra|guest` in configuration and has Kubernetes auth fragments for GitHub, Entra ID, and guest mode. The wizard, agent guidance, and Backstage frontend/backend behavior are still GitHub-centric in several places.

### 1.3 Delta Scope

- Add a non-secret GitHub identity governance mode to configuration and wizard output.
- Add `enterprise-managed-users` as a supported GitHub identity mode when Backstage auth is Entra ID.
- Update Backstage runtime and UI to support Entra ID sign-in.
- Update agents, scripts, and docs to validate and explain the process.

### 1.4 Out of Scope

- Creating or migrating a GitHub Enterprise Managed Users enterprise: this is performed in GitHub Enterprise and Entra admin portals.
- Storing Entra or GitHub secrets in the wizard selection manifest: secrets remain in `.env`, Key Vault, or Kubernetes Secrets.
- Removing GitHub App or token integration: EMU changes user identity governance, not technical SCM integration.
- Replacing Azure DevOps identity or permissions: this SDD focuses on Backstage and GitHub Enterprise Cloud identity.

### 1.5 Documented Assumptions

| # | Assumption | Consequence if Wrong |
|---|------------|----------------------|
| A1 | Customers using GitHub EMU also use Microsoft Entra ID as the IdP. | The wizard option must support another IdP or stay disabled. |
| A2 | Backstage users can be resolved by email or UPN from Entra ID. | Catalog ingestion or sign-in resolver design must change. |
| A3 | GitHub App or token credentials remain available for platform integrations. | GitHub-dependent portal features must be disabled or degraded. |

## 2. Stakeholder Roles

| Role | Who They Are | Key Permissions |
|------|--------------|-----------------|
| Platform Engineer | Owns Open Horizons installation and runtime configuration | Runs wizard, renders manifests, deploys Backstage |
| Entra Administrator | Owns tenant applications and provisioning | Creates app registration, configures SAML/SCIM for GitHub EMU |
| GitHub Enterprise Administrator | Owns enterprise managed users and GitHub App installation | Enables EMU, installs GitHub App, grants org permissions |
| Security Reviewer | Validates identity, secrets, and least privilege | Reviews SSO, SCIM, secrets, and app permissions |
| Developer | Uses Backstage and GitHub | Signs in through Entra and accesses GitHub through managed account |

## 3. Identity Strategy Requirements

### FR-ID-01: Separate Sign-In Provider From GitHub Identity Mode, Priority P0

The system must represent Backstage sign-in provider and GitHub identity governance as separate configuration choices.

1. `AUTH_PROVIDER` must continue to represent Backstage sign-in provider.
2. `GITHUB_IDENTITY_MODE` must represent GitHub identity governance.

**Acceptance signal:** A generated `.env` can contain `AUTH_PROVIDER=entra` and `GITHUB_IDENTITY_MODE=enterprise-managed-users` simultaneously.

### FR-ID-02: Support Entra ID Plus GitHub EMU, Priority P0

The system must support `AUTH_PROVIDER=entra` with `GITHUB_IDENTITY_MODE=enterprise-managed-users`.

1. The wizard must allow the combination.
2. Render scripts must validate the combination.
3. Agents must describe it as the preferred enterprise model for GitHub EMU customers.

**Acceptance signal:** The wizard and render script accept the combination without falling back to GitHub OAuth.

### FR-ID-03: Block Invalid EMU Combinations, Priority P0

The system must reject GitHub EMU mode unless the Backstage auth provider is Entra ID.

1. `GITHUB_IDENTITY_MODE=enterprise-managed-users` with `AUTH_PROVIDER=github` must fail validation.
2. `GITHUB_IDENTITY_MODE=enterprise-managed-users` with `AUTH_PROVIDER=guest` must fail validation.

**Acceptance signal:** The wizard or render script exits non-zero with a clear error for invalid combinations.

## 4. Wizard and Script Requirements

### FR-WIZ-01: Ask GitHub Identity Mode When Entra Is Selected, Priority P0

When the installer selects Entra ID authentication, the wizard must ask for the GitHub identity mode.

1. Valid choices must include `standard`, `saml-sso`, and `enterprise-managed-users`.
2. The default for Entra enterprise deployments should be `enterprise-managed-users`.

**Acceptance signal:** Interactive wizard output writes the selected identity mode to `.env`.

### FR-WIZ-02: Persist Non-Secret Identity Strategy, Priority P0

The wizard selection manifest must persist identity strategy without secrets.

1. The manifest may include `identity.auth_provider`.
2. The manifest may include `identity.github_identity_mode`.
3. The manifest must not include secrets, tokens, client secrets, or keys.

**Acceptance signal:** Schema validation accepts the identity block and still rejects secret-like keys.

### FR-SCRIPT-01: Render Correct Secret Checklist, Priority P0

The manifest render script must emit the correct secret checklist for Entra ID and EMU mode.

1. Entra mode must list `ENTRA_CLIENT_ID`, `ENTRA_CLIENT_SECRET`, and `ENTRA_TENANT_ID`.
2. EMU mode must remind operators that GitHub technical credentials are still required for integrations.

**Acceptance signal:** `scripts/render-k8s.sh --dry-run` prints Entra secrets and EMU GitHub integration guidance.

## 5. Backstage Runtime Requirements

### FR-BS-01: Enable Microsoft Auth Provider, Priority P0

Backstage backend must load the Microsoft auth provider module.

**Acceptance signal:** Backend startup can register `auth.providers.microsoft` without missing module errors.

### FR-BS-02: Keep GitHub Integration Separate, Priority P0

Backstage must keep GitHub integration configured independently from the selected sign-in provider.

1. GitHub App or token integration must remain available in Entra/EMU mode.
2. The UI must not imply that GitHub OAuth is required for portal sign-in when Entra is selected.

**Acceptance signal:** Entra sign-in works while GitHub-backed catalog and plugin calls can still use configured GitHub credentials.

### FR-BS-03: Resolve Users By Entra Email Or UPN, Priority P0

Backstage sign-in must resolve identities through Entra email or UPN rather than GitHub username in EMU mode.

**Acceptance signal:** A managed user with matching catalog email can sign in and receive a Backstage identity.

## 6. Agent Process Requirements

### FR-AGENT-01: Deploy Agent Owns Identity Choice, Priority P0

The deploy agent must ask for or validate the identity strategy before deployment.

**Acceptance signal:** Deploy guidance includes `AUTH_PROVIDER` and `GITHUB_IDENTITY_MODE` in setup steps.

### FR-AGENT-02: GitHub Agent Validates EMU Prerequisites, Priority P0

The GitHub integration agent must validate that GitHub EMU, SAML/SCIM, and GitHub App integration requirements are understood.

**Acceptance signal:** GitHub integration guidance distinguishes GitHub EMU identity governance from GitHub App technical integration.

### FR-AGENT-03: Backstage Agent Validates Entra Runtime, Priority P0

The Backstage expert agent must validate Microsoft auth config, callback URL, and Kubernetes secret checklist.

**Acceptance signal:** Backstage troubleshooting guidance includes `https://<domain>/api/auth/microsoft/handler/frame`.

## 7. Functional Requirements Summary

| ID | Requirement | Domain | Priority | Phase |
|----|-------------|--------|----------|-------|
| FR-ID-01 | Separate sign-in provider from GitHub identity mode | Identity | P0 | Phase 1 |
| FR-ID-02 | Support Entra ID plus GitHub EMU | Identity | P0 | Phase 1 |
| FR-ID-03 | Block invalid EMU combinations | Identity | P0 | Phase 1 |
| FR-WIZ-01 | Ask GitHub identity mode when Entra is selected | Wizard | P0 | Phase 2 |
| FR-WIZ-02 | Persist non-secret identity strategy | Wizard | P0 | Phase 2 |
| FR-SCRIPT-01 | Render correct secret checklist | Scripts | P0 | Phase 2 |
| FR-BS-01 | Enable Microsoft auth provider | Backstage | P0 | Phase 3 |
| FR-BS-02 | Keep GitHub integration separate | Backstage | P0 | Phase 3 |
| FR-BS-03 | Resolve users by Entra email or UPN | Backstage | P0 | Phase 3 |
| FR-AGENT-01 | Deploy agent owns identity choice | Agents | P0 | Phase 4 |
| FR-AGENT-02 | GitHub agent validates EMU prerequisites | Agents | P0 | Phase 4 |
| FR-AGENT-03 | Backstage agent validates Entra runtime | Agents | P0 | Phase 4 |

**P0=12, P1=0, P2=0, P3=0. Total=12.**

## 8. Implementation Phases

| Phase | Requirements | Objective | State After |
|-------|--------------|-----------|-------------|
| Phase 1, Configuration Model | FR-ID-01, FR-ID-02, FR-ID-03 | Add the non-secret identity strategy model | `.env`, manifest, schema, and validation agree |
| Phase 2, Wizard And Scripts | FR-WIZ-01, FR-WIZ-02, FR-SCRIPT-01 | Make the process executable | Wizard and render scripts emit correct outputs |
| Phase 3, Backstage Runtime | FR-BS-01, FR-BS-02, FR-BS-03 | Make Entra sign-in work | Backstage supports Microsoft auth and GitHub integration |
| Phase 4, Agent And Docs | FR-AGENT-01, FR-AGENT-02, FR-AGENT-03 | Make agents follow the process | Agent guidance and docs are aligned |

## 9. References

- [Backstage Microsoft auth provider](https://backstage.io/docs/auth/microsoft/provider/)
- [Backstage GitHub integration](https://backstage.io/docs/integrations/github/)
- [GitHub Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users)
- [Microsoft Entra provisioning for GitHub Enterprise Managed User](https://learn.microsoft.com/en-us/entra/identity/saas-apps/github-enterprise-managed-user-provisioning-tutorial)
- [Microsoft Entra app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
