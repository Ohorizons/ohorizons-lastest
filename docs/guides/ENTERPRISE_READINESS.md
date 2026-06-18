---
title: "Open Horizons Enterprise Readiness"
description: "Enterprise fork readiness controls and validation checklist for Open Horizons."
author: "Open Horizons"
date: "2026-06-18"
version: "1.0.0"
status: "approved"
tags: ["enterprise-readiness", "fork", "azure", "github", "backstage"]
---
<!-- markdownlint-disable MD025 -->

# Open Horizons Enterprise Readiness

> This guide records the controls that make Open Horizons ready for enterprise forks and the validation commands operators should run before rollout.

## Change Log

| Version | Date | Author | Changes |
| ------- | ---- | ------ | ------- |
| 1.0.0 | 2026-06-18 | Open Horizons | Initial enterprise readiness checklist |

## Table of Contents

- [1. Readiness Baseline](#1-readiness-baseline)
- [2. Fork Branding](#2-fork-branding)
- [3. Deployment Path](#3-deployment-path)
- [4. Identity](#4-identity)
- [5. TechDocs](#5-techdocs)
- [6. Validation](#6-validation)
- [References](#references)

## 1. Readiness Baseline

The enterprise path is the install wizard, OIDC-enabled GitHub Actions, Terraform modules, rendered Kubernetes manifests, and Backstage production configuration. Non-production examples are kept under `docs/examples/` and are not part of deployment automation.

## 2. Fork Branding

Use `open-horizons-platform` as the public product repository name and `Ohorizons/open-horizons-platform` for upstream references. Customer forks should override `GITHUB_ORG`, `GITHUB_REPO`, `DOMAIN`, and `ORG_DISPLAY_NAME` through `.env`, the install wizard, repository variables, or Terraform variables.

## 3. Deployment Path

The enterprise CI/CD workflow uses `TF_VAR_*` inputs and GitHub OIDC secrets. It does not require committed `terraform/environments/*.tfvars` files, because those files are intentionally ignored to avoid leaking customer configuration.

Critical gates must fail closed:

- Terraform validation and plan must fail on errors.
- `tfsec`, Trivy, and Conftest must block high-risk findings.
- Release images must be signed, attested, scanned, and version-tagged.

## 4. Identity

Use `scripts/setup-identity-federation.sh` for the platform repository. This configures GitHub Actions OIDC with Azure and writes the required `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` secrets.

Do not use `AZURE_CREDENTIALS`, `ARM_CLIENT_SECRET`, or checked-in service principal JSON for enterprise deployments.

## 5. TechDocs

Production Backstage config uses external TechDocs publishing with Azure Blob Storage. Operators must provide these values through Key Vault, External Secrets, or repository secrets depending on the deployment mode:

| Variable | Purpose |
| -------- | ------- |
| `TECHDOCS_AZURE_STORAGE_ACCOUNT` | Azure Storage account that hosts generated docs |
| `TECHDOCS_AZURE_STORAGE_ACCOUNT_KEY` | Storage access key or secret sourced from Key Vault |
| `TECHDOCS_AZURE_BLOB_CONTAINER` | Blob container, default `techdocs` |

## 6. Validation

Run these commands before presenting a fork as enterprise-ready:

```bash
bash -n scripts/deploy-full.sh scripts/render-manifests.sh scripts/validate-deployment.sh
git diff --check
actionlint .github/workflows/ci-cd.yml .github/workflows/terraform-test.yml .github/workflows/release-images.yml
bash tests/wizard/run.sh
scripts/render-manifests.sh --dry-run
```

When Azure credentials and a cluster are available, also run:

```bash
./scripts/validate-prerequisites.sh
./scripts/validate-config.sh --environment dev
./scripts/deploy-full.sh --environment dev --dry-run
./scripts/validate-deployment.sh --environment dev
```

## References

- [GitHub Actions OIDC with Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)
- [Backstage deployment documentation](https://backstage.io/docs/deployment/)
- [Backstage TechDocs configuration](https://backstage.io/docs/features/techdocs/configuration/)
- [Terraform input variables](https://developer.hashicorp.com/terraform/language/values/variables)

---

<div align="center">

<img src="https://img.shields.io/badge/%20-F25022?style=flat-square" height="4" width="120" alt=""/><img src="https://img.shields.io/badge/%20-7FBA00?style=flat-square" height="4" width="120" alt=""/><img src="https://img.shields.io/badge/%20-00A4EF?style=flat-square" height="4" width="120" alt=""/><img src="https://img.shields.io/badge/%20-FFB900?style=flat-square" height="4" width="120" alt=""/>

<table>
<tr>
<td align="left">

[![Previous](https://img.shields.io/badge/←%20Previous-Troubleshooting-555555?style=for-the-badge)](TROUBLESHOOTING_GUIDE.md)

</td>
<td align="right">

[![Documentation Home](https://img.shields.io/badge/⌂%20Documentation%20Home-1B1B1F?style=for-the-badge)](../../README.md)

</td>
</tr>
</table>

</div>
