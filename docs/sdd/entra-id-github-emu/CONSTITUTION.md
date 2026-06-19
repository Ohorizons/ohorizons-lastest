---
title: "Entra ID and GitHub EMU Constitution"
description: "Non-negotiable identity rules for Open Horizons Entra ID plus GitHub Enterprise Managed Users support."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["constitution", "identity", "entra-id", "github-emu"]
---

# Entra ID and GitHub EMU Constitution

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial identity constitution |

## 1. Non-Negotiable Rules

### Rule 1: Sign-In Authority Is Not GitHub Governance

`AUTH_PROVIDER` controls Backstage sign-in. `GITHUB_IDENTITY_MODE` records GitHub identity governance. These values must not be collapsed into one setting.

### Rule 2: GitHub EMU Requires Entra ID Sign-In

`GITHUB_IDENTITY_MODE=enterprise-managed-users` is valid only when `AUTH_PROVIDER=entra`. Wizard, render, and config validation must fail before deployment for any other combination.

### Rule 3: GitHub Technical Integration Remains Required

Even in EMU mode, GitHub App or token credentials remain required for catalog sync, scaffolder writes, GitHub Actions visibility, PR data, Codespaces, packages, and AI Impact metrics.

### Rule 4: Secrets Stay Out Of Intent Artifacts

Selection manifests, SDD documents, prompts, agents, and instructions may contain only non-secret identity strategy. Tokens, client secrets, and private keys must live in `.env`, Kubernetes Secrets, Key Vault, or CI secret stores.

### Rule 5: Callback URLs Must Match The Portal Domain

The Entra app registration must use the actual portal URL: `https://<portal-url>/api/auth/microsoft/handler/frame`. Hardcoded placeholder domains are not acceptable for enterprise validation.

## 2. Completion Evidence

Identity support is complete only when these are true:

1. Valid Entra plus EMU configuration passes tests.
2. Invalid EMU combinations fail tests.
3. Backstage backend registers Microsoft auth provider.
4. Backstage frontend registers Microsoft auth API.
5. Sign-in UI presents Microsoft Entra ID when Microsoft provider config is present.
6. Docs explain GitHub technical integration in EMU mode.
