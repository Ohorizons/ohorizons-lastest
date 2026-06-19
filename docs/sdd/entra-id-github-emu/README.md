---
title: "Entra ID and GitHub Enterprise Managed Users SDD"
description: "Spec-driven development package for Open Horizons enterprise identity with Entra ID sign-in and GitHub EMU governance."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["sdd", "identity", "entra-id", "github-emu", "backstage"]
---

# Entra ID and GitHub Enterprise Managed Users SDD

> This package defines how Open Horizons supports Microsoft Entra ID as the Backstage sign-in authority while GitHub Enterprise Managed Users governs access to GitHub from the same enterprise identity boundary.

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial SDD package |

## Table of Contents

- [1. Purpose](#1-purpose)
- [2. Decision](#2-decision)
- [3. Artifacts](#3-artifacts)
- [4. Process Entry Points](#4-process-entry-points)
- [5. References](#5-references)

## 1. Purpose

Open Horizons needs a first-class enterprise identity option for customers that use Microsoft Entra ID and GitHub Enterprise Managed Users. This is not only a Backstage login switch. It affects the install wizard, generated manifests, GitHub integration, validation, agent guidance, and customer onboarding documentation.

## 2. Decision

The platform separates the user sign-in provider from GitHub identity governance:

```env
AUTH_PROVIDER=entra
GITHUB_IDENTITY_MODE=enterprise-managed-users
```

`AUTH_PROVIDER=entra` means Backstage users sign in with Microsoft Entra ID. `GITHUB_IDENTITY_MODE=enterprise-managed-users` means GitHub access is governed by GitHub Enterprise Managed Users provisioned from Entra ID. GitHub App or token credentials are still required for technical integration such as catalog sync, scaffolder writes, GitHub Actions visibility, PR data, Codespaces, packages, and AI Impact metrics.

## 3. Artifacts

| Artifact | Purpose |
|----------|---------|
| [FRD.md](FRD.md) | Functional requirements for the identity option |
| [NFRD.md](NFRD.md) | Security, operability, compatibility, and auditability constraints |
| [SPECIFICATION.md](SPECIFICATION.md) | Machine-parseable EARS requirements and acceptance criteria |
| [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Atomic tasks, scope, validation, and human review gate |

## 4. Process Entry Points

The implementation must update these process surfaces:

- Root configuration: `.env.example` and generated `.env`.
- Wizard manifest: `.openhorizons-selection.yaml` and `scripts/openhorizons-selection.schema.json`.
- Wizard flow: `scripts/install-wizard.sh`.
- Manifest rendering: `scripts/render-k8s.sh` and `scripts/render-manifests.sh`.
- Backstage auth runtime: `backstage/packages/backend`, `backstage/packages/app`, and `backstage/k8s/templates/auth-*.yaml.fragment`.
- Agent guidance: deploy, Backstage, GitHub integration, Azure portal deploy, security, and hybrid scenario agents.
- Customer docs and guides: README, deployment, prerequisites, and installation guides.

## 5. References

- [Backstage Microsoft auth provider](https://backstage.io/docs/auth/microsoft/provider/)
- [Backstage GitHub integration](https://backstage.io/docs/integrations/github/)
- [GitHub Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users)
- [Microsoft Entra provisioning for GitHub Enterprise Managed User](https://learn.microsoft.com/en-us/entra/identity/saas-apps/github-enterprise-managed-user-provisioning-tutorial)
- [Microsoft Entra app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
