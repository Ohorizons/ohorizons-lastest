---
title: "Entra ID and GitHub Enterprise Managed Users Implementation Plan"
description: "Atomic implementation plan for Open Horizons Entra ID plus GitHub EMU support."
author: "Open Horizons"
date: "2026-06-19"
version: "1.0.0"
status: "approved"
tags: ["implementation-plan", "identity", "entra-id", "github-emu"]
---

# Entra ID and GitHub Enterprise Managed Users Implementation Plan

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-06-19 | Open Horizons | Initial implementation plan |

## Approved Scope

**Specification:** [SPECIFICATION.md](SPECIFICATION.md)

**Approved by:** Open Horizons on 2026-06-19

### Files in Scope

```text
.env.example                                                [MODIFY]
scripts/install-wizard.sh                                  [MODIFY]
scripts/openhorizons-selection.schema.json                 [MODIFY]
scripts/render-k8s.sh                                      [MODIFY]
scripts/render-manifests.sh                                [MODIFY]
scripts/deploy-runtime-nogithub.sh                         [MODIFY]
scripts/setup-github-app.sh                                [MODIFY]
scripts/setup-portal.sh                                    [MODIFY]
backstage/packages/backend/package.json                    [MODIFY]
backstage/yarn.lock                                        [MODIFY]
backstage/packages/backend/src/index.ts                    [MODIFY]
backstage/packages/app/src/apis.ts                         [MODIFY]
backstage/packages/app/src/components/SignInPage/*         [MODIFY]
backstage/packages/app/src/components/Root/TopBar.tsx      [MODIFY]
backstage/k8s/templates/auth-*.yaml.fragment               [MODIFY]
.github/agents/*.agent.md                                  [MODIFY]
.github/prompts/*.prompt.md                                [MODIFY]
.github/skills/backstage-deployment/SKILL.md              [MODIFY]
.github/skills/github-cli/SKILL.md                         [MODIFY]
.github/skills/deploy-orchestration/SKILL.md               [MODIFY]
docs/guides/*.md                                           [MODIFY]
README.md                                                  [MODIFY]
docs/sdd/entra-id-github-emu/                              [CREATE]
```

### Files Explicitly Out Of Scope

```text
.env                                                       [NEVER - secrets]
terraform state files                                      [NEVER]
customer Key Vault secrets                                 [NEVER]
GitHub Enterprise EMU tenant settings                      [EXTERNAL]
Entra Conditional Access policies                          [EXTERNAL]
```

## Phase 1: Configuration Model

- [S] Task 1.1: Add `GITHUB_IDENTITY_MODE` and optional `GITHUB_ENTERPRISE_SLUG` to root configuration examples.
  - Files: `.env.example` [MODIFY]
  - Acceptance: Example documents `standard`, `saml-sso`, and `enterprise-managed-users`.

- [S] Task 1.2: Add non-secret identity block to wizard manifest schema.
  - Files: `scripts/openhorizons-selection.schema.json` [MODIFY]
  - Acceptance: Schema accepts `identity.auth_provider=entra` and `identity.github_identity_mode=enterprise-managed-users`.

- [S] Task 1.3: Add dependency validation for EMU mode.
  - Files: `scripts/install-wizard.sh`, `scripts/render-k8s.sh` [MODIFY]
  - Acceptance: EMU mode with GitHub or guest auth fails before deployment.

## Phase 2: Wizard And Scripts

- [S] Task 2.1: Add interactive wizard prompt for GitHub identity mode when Entra ID is selected.
  - Files: `scripts/install-wizard.sh` [MODIFY]
  - Acceptance: Wizard writes `GITHUB_IDENTITY_MODE=enterprise-managed-users` to `.env`.

- [P] Task 2.2: Add render script summary and secrets guidance.
  - Files: `scripts/render-k8s.sh` [MODIFY]
  - Acceptance: Render output displays `Identity: enterprise-managed-users` and Entra secrets.

- [P] Task 2.3: Keep no-GitHub runtime validation on `standard` identity mode.
  - Files: `scripts/deploy-runtime-nogithub.sh`, `scripts/render-manifests.sh` [MODIFY]
  - Acceptance: no-GitHub validation remains guest-only and does not select EMU.

## Phase 3: Backstage Runtime

- [S] Task 3.1: Add Microsoft auth backend module.
  - Files: `backstage/packages/backend/package.json`, `backstage/yarn.lock`, `backstage/packages/backend/src/index.ts` [MODIFY]
  - Acceptance: Backend registers Microsoft auth provider.

- [S] Task 3.2: Register Microsoft auth API in frontend.
  - Files: `backstage/packages/app/src/apis.ts` [MODIFY]
  - Acceptance: Frontend has both GitHub and Microsoft auth APIs available.

- [S] Task 3.3: Make sign-in UI provider-aware.
  - Files: `backstage/packages/app/src/components/SignInPage/CustomSignInPage.tsx` [MODIFY]
  - Acceptance: Microsoft provider config shows `Sign in with Microsoft Entra ID`.

- [P] Task 3.4: Remove GitHub-only identity wording from top bar.
  - Files: `backstage/packages/app/src/components/Root/TopBar.tsx` [MODIFY]
  - Acceptance: Top bar identity is provider-neutral.

## Phase 4: Agents And Documentation

- [S] Task 4.1: Update deploy, Backstage, GitHub integration, Azure, security, and hybrid agents.
  - Files: `.github/agents/*.agent.md` [MODIFY]
  - Acceptance: Agents distinguish Backstage sign-in from GitHub technical integration.

- [P] Task 4.2: Update prompts and skills.
  - Files: `.github/prompts/*.prompt.md`, `.github/skills/*/SKILL.md` [MODIFY]
  - Acceptance: Prompt/skill descriptions mention Entra ID and EMU where relevant.

- [P] Task 4.3: Update customer installation docs.
  - Files: `README.md`, `docs/guides/*.md` [MODIFY]
  - Acceptance: Docs list `GITHUB_IDENTITY_MODE` and GitHub EMU prerequisites.

## [GATE] Human Review

> This gate verifies that identity behavior is correct before release.

- [ ] The wizard and render scripts reject invalid EMU combinations.
- [ ] Backstage Entra ID callback URL is documented.
- [ ] GitHub App integration remains required for GitHub-backed features.
- [ ] No secrets are stored in SDD docs or selection manifest.
- [ ] Agent instructions preserve lean-agent/rich-skill boundaries.

**Approved by:** _________________ **Date:** _________________

## Phase 5: Validation

- [S] Task 5.1: Run shell syntax checks.
  - Files: `scripts/*.sh` [VALIDATE]
  - Acceptance: `bash -n` passes for changed scripts.

- [S] Task 5.2: Run wizard tests with bash 4+.
  - Files: `tests/wizard/run.sh` [VALIDATE]
  - Acceptance: Wizard tests pass.

- [S] Task 5.3: Run Backstage TypeScript/backend validation.
  - Files: `backstage/` [VALIDATE]
  - Acceptance: Build or typecheck passes, or any unrelated pre-existing issue is documented.

- [S] Task 5.4: Run customization validation.
  - Files: `.github/agents`, `.github/prompts`, `.github/skills` [VALIDATE]
  - Acceptance: Agent validation passes after customization changes.

## Completion Checklist

- [ ] All implementation tasks completed.
- [ ] Shell syntax checks completed.
- [ ] Wizard schema and tests completed.
- [ ] Backstage auth package/build validation completed.
- [ ] Agent validation completed.
- [ ] SDD acceptance criteria satisfied.
- [ ] No secrets written to repository files.

## References

- [Backstage Microsoft auth provider](https://backstage.io/docs/auth/microsoft/provider/)
- [Backstage GitHub integration](https://backstage.io/docs/integrations/github/)
- [GitHub Enterprise Managed Users](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/about-enterprise-managed-users)
- [Microsoft Entra provisioning for GitHub Enterprise Managed User](https://learn.microsoft.com/en-us/entra/identity/saas-apps/github-enterprise-managed-user-provisioning-tutorial)
- [Microsoft Entra app registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
