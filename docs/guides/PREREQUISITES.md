---
title: "Open Horizons — Prerequisites & Sizing Guide"
description: "Single source of truth for Azure tenant/subscription requirements, GitHub Enterprise / Azure DevOps setup, t-shirt sizing, regional availability, and integration prerequisites for deploying Open Horizons."
author: "Platform Engineering"
date: "2026-05-07"
version: "1.0.0"
status: "approved"
tags: ["prerequisites", "sizing", "azure", "github", "ado", "installation"]
---

# Open Horizons — Prerequisites & Sizing Guide

This guide consolidates **everything required before starting an Open Horizons deployment**. Read this first; then follow the [Master Installation Guide](MASTER_INSTALLATION.md).

---

## Table of Contents

- [1. Account & Identity Prerequisites](#1-account--identity-prerequisites)
- [2. Azure Resources — T-Shirt Sizing](#2-azure-resources--t-shirt-sizing)
- [3. Azure Region Selection](#3-azure-region-selection)
- [4. GitHub / GitHub Enterprise Prerequisites](#4-github--github-enterprise-prerequisites)
- [5. Azure DevOps Prerequisites (optional)](#5-azure-devops-prerequisites-optional)
- [6. Hybrid GitHub + ADO Scenarios](#6-hybrid-github--ado-scenarios)
- [7. Local CLI Tools](#7-local-cli-tools)
- [8. Network & DNS](#8-network--dns)
- [9. Cost Estimates](#9-cost-estimates)
- [10. Pre-Deployment Checklist](#10-pre-deployment-checklist)

---

## 1. Account & Identity Prerequisites

### Microsoft Entra (Azure AD) tenant

| Requirement | Detail |
|---|---|
| Tenant | One Entra ID tenant where you can register apps and create federated credentials |
| Role on tenant | **Application Administrator** or **Cloud Application Administrator** to create app registrations for OIDC federation |
| Tenant ID | You will need this for `terraform.tfvars` (`tenant_id`) |

### Azure subscription(s)

| Sizing | Subscriptions | Why split? |
|---|---|---|
| Small (POC) | 1 subscription | Single env (dev), low blast radius |
| Medium | 2 subscriptions (`dev`, `prod`) | Separate billing & RBAC |
| Large | 3 subscriptions (`dev`, `staging`, `prod`) | SDLC isolation |
| XLarge | 3+ subscriptions + management group | Enterprise scale, multi-region DR |

**Required role on each subscription:** `Owner` **or** (`Contributor` + `User Access Administrator`). Needed because Terraform creates RGs **and** assigns RBAC and federated credentials.

### Resource provider registration

Run once per subscription (the deploy script does this automatically, listed here for awareness):
`Microsoft.ContainerService`, `Microsoft.ContainerRegistry`, `Microsoft.DBforPostgreSQL`, `Microsoft.Cache`, `Microsoft.KeyVault`, `Microsoft.OperationalInsights`, `Microsoft.Insights`, `Microsoft.Monitor`, `Microsoft.Dashboard`, `Microsoft.AlertsManagement`, `Microsoft.Security`, `Microsoft.Purview`, `Microsoft.CognitiveServices`, `Microsoft.MachineLearningServices`, `Microsoft.Network`, `Microsoft.ManagedIdentity`.

---

## 2. Azure Resources — T-Shirt Sizing

The platform ships **4 sizing profiles** in [`config/sizing-profiles.yaml`](../../config/sizing-profiles.yaml). Pick one based on team size and workload.

| Profile | Team Size | Use Case | Monthly Cost (est.) |
|---|---|---|---|
| **Small** | < 10 devs | Dev / POC | ~$800–$1,500 |
| **Medium** | 10–50 devs | Standard Production | ~$3,000–$6,000 |
| **Large** | 50–200 devs | Enterprise Production | ~$8,000–$15,000 |
| **XLarge** | 200+ devs | Mission Critical, multi-region | $20,000+ |

### Compute — AKS

| Profile | Node count | VM size | Auto-scale | GPU pool |
|---|---|---|---|---|
| Small | 3 | `Standard_D2s_v5` (2 vCPU, 8 GiB) | off | — |
| Medium | 5 | `Standard_D4s_v5` (4 vCPU, 16 GiB) | 3–10 | — |
| Large | 3+5 (system+user) | `D4s_v5` + `D8s_v5` | 3–15 | `NC6s_v3` x2 |
| XLarge | 5+10 (system+user) | `D8s_v5` + `D16s_v5` | 5–30 | `NC12s_v3` x4 |

### Data — PostgreSQL Flexible Server

| Profile | SKU | Storage | HA | Backup |
|---|---|---|---|---|
| Small | `Standard_B1ms` (1 vCPU) | 32 GB | off | 7 days |
| Medium | `Standard_D2ds_v5` (2 vCPU) | 128 GB | off | 14 days |
| Large | `Standard_D4ds_v5` (4 vCPU) | 256 GB | zone-redundant | 30 days |
| XLarge | `Standard_D8ds_v5` (8 vCPU) | 512 GB | zone-redundant + read replicas | 35 days |

### Container Registry (ACR)

| Profile | SKU | Geo-replication | Private endpoint |
|---|---|---|---|
| Small | `Basic` | off | off |
| Medium | `Standard` | off | optional |
| Large | `Premium` | off | on |
| XLarge | `Premium` | on (multi-region) | on |

### Cache (Redis)

| Profile | SKU |
|---|---|
| Small | `Basic` (250 MB) |
| Medium | `Basic` (1 GB) |
| Large | `Standard` (6 GB) |
| XLarge | `Premium` (26 GB) |

### Key Vault

| Profile | SKU | Soft-delete |
|---|---|---|
| Small / Medium | `standard` | 90 days |
| Large / XLarge | `premium` (HSM-backed) | 90 days |

### Networking (CIDR planning)

| Profile | VNet | AKS subnet | Free IPs |
|---|---|---|---|
| Small | `10.0.0.0/16` | `/23` | 512 |
| Medium | `10.0.0.0/16` | `/22` | 1,024 |
| Large | `10.0.0.0/16` | `/20` | 4,096 |
| XLarge | `10.0.0.0/14` | `/18` | 16,384 |

> **Important:** allocate non-overlapping CIDRs if you intend to peer with corporate networks (hub-spoke).

---

## 3. Azure Region Selection

Full matrix in [`config/region-availability.yaml`](../../config/region-availability.yaml).

### Tier-1 regions (full platform support, all 4 sizes)

| Region | Best for | Notes |
|---|---|---|
| **East US 2** | AI-intensive workloads, default for all GPT-4o/o3 models | Recommended primary for global tenants |
| **Brazil South** | LGPD compliance, LATAM low latency | AI models limited — spillover to East US 2 for GPT-4o |
| **West Europe** | GDPR, EU data residency | Full AI Foundry |
| **Sweden Central** | EU sovereign | Some AI models limited |

### Multi-region (DR)

XLarge profile assumes **2 regions** (e.g. East US 2 primary + West US 3 secondary, or Brazil South primary + East US 2 secondary).

---

## 4. GitHub / GitHub Enterprise Prerequisites

### GitHub.com (Free, Team, Enterprise Cloud)

| Item | Required for | How to get |
|---|---|---|
| **Organization** with Admin role | Holds the platform fork + golden-path repos | Create in GitHub UI |
| **GitHub App** (or OAuth App) | Backstage authentication, scaffolder writes, catalog sync | [Setup script](../../scripts/setup-github-app.sh) |
| **App permissions** | `repo`, `workflow`, `admin:org` (read), `contents:write`, `metadata:read`, `pull_requests:write` | Set during App creation |
| **OIDC federation** to Azure | Keyless deploy from GitHub Actions | [Setup script](../../scripts/setup-identity-federation.sh) |
| **Branch protection** rules | Required for Golden Path repos | [Setup script](../../scripts/setup-branch-protection.sh) |

### GitHub Enterprise Cloud (recommended)

Adds:

- **GitHub Advanced Security (GHAS)** — secret scanning, code scanning (CodeQL), Dependabot in private repos
- **Single Sign-On (SSO)** with Entra ID
- **SCIM** provisioning
- **IP allow lists** & audit log streaming
- **Larger Actions runners** (recommended for the platform's CI/CD load)

> Open Horizons workflows assume GHAS is **available** in private repos. They still run on Free/Team for **public** repos (which the platform fork can be).

### GitHub Enterprise Server (self-hosted)

Supported with these caveats:

- Must be reachable from AKS (network connectivity for catalog sync)
- Needs same App permissions as GitHub.com
- Self-hosted runners required (no GitHub-hosted runners)
- AI features (Copilot, code-scanning autofix) require GHES 3.13+

---

## 5. Azure DevOps Prerequisites (optional)

If you use Azure DevOps for repos / pipelines / boards instead of (or alongside) GitHub:

| Item | Detail |
|---|---|
| **ADO Organization** with PCA or Project Collection Administrator role | Create projects, set policies |
| **Personal Access Token (PAT)** with scopes: `Code (read & write)`, `Build (read & execute)`, `Release (read, write, execute)`, `Project & team (read)`, `Work items (read & write)` | Store in Backstage secret |
| **Project** with Git repos enabled | Hosts Golden-Path generated projects |
| **Service connection** to Azure subscription (Managed Identity / Workload Identity) | For pipelines that deploy to AKS |
| **Copilot Standalone licensing** (optional) | If using Copilot in ADO pipelines |

Detailed setup: [@ado-integration agent](../../.github/agents/ado-integration.agent.md) and [`docs/guides/ARCHITECTURE_GUIDE.md`](ARCHITECTURE_GUIDE.md).

---

## 6. Hybrid GitHub + ADO Scenarios

The `@hybrid-scenarios` agent supports **3 coexistence patterns**:

| Scenario | Description | When to use |
|---|---|---|
| **A — GitHub primary, ADO read-only mirror** | Code lives in GitHub, ADO mirrors for boards / compliance reporting | Migration from ADO; team uses ADO Boards |
| **B — Per-team split** | Some teams on GitHub, some on ADO; shared Backstage catalog | Large enterprise mid-migration |
| **C — Dual-platform CI/CD** | Code in GitHub, builds in ADO Pipelines (or vice-versa) | Existing ADO Pipelines investment, gradual migration |

For all hybrid scenarios you need **both** sets of prerequisites from §4 and §5, plus dual auth in Backstage (`auth.providers.github` + `auth.providers.microsoft`).

---

## 7. Local CLI Tools

Run [`scripts/validate-prerequisites.sh`](../../scripts/validate-prerequisites.sh) to verify all of the below:

| Tool | Min version | Why |
|---|---|---|
| `az` | 2.55 | Azure provisioning, OIDC setup |
| `gh` | 2.40 | GitHub repo / app / branch protection automation |
| `terraform` | 1.5 | IaC for all 16 modules |
| `kubectl` | 1.28 | AKS day-2 operations |
| `helm` | 3.13 | Backstage, ArgoCD, observability charts |
| `node` | 20 | Backstage build (locally for testing only) |
| `yarn` | 4 | Backstage workspace |
| `jq` | 1.7 | Scripting / parsing API responses |
| `yq` | 4 | YAML manipulation in install wizard |
| `argocd` | 2.10 | (optional) ArgoCD CLI for sync diagnostics |
| `cosign` | 2.4 | (optional) Verify signed container images |
| `git` | 2.40 | Standard |

---

## 8. Network & DNS

| Item | Detail |
|---|---|
| **Custom domain** | E.g. `platform.contoso.com`. Required for production ingress with TLS. |
| **DNS zone** | Either Azure DNS or your existing provider; CNAME pointing to NGINX ingress IP. |
| **TLS certificates** | Auto-provisioned via cert-manager + Let's Encrypt **or** bring your own ACM/Key Vault cert. |
| **Outbound egress** | AKS needs to reach `mcr.microsoft.com`, `ghcr.io`, `docker.io`, `pypi.org`, `npmjs.com`, `github.com`, Azure management endpoints. |
| **Private cluster** (Large/XLarge) | API server private; requires Bastion or self-hosted runners inside the VNet. |

---

## 9. Cost Estimates

> Estimates are **list price**, single-region, exclude Azure OpenAI token consumption. Use [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for your region and discounts (EA/CSP).

| Profile | AKS | DB+Cache | ACR+KV | Observability | **Total/mo** |
|---|---|---|---|---|---|
| Small | $250 | $80 | $30 | $100 | **~$800–$1,500** |
| Medium | $900 | $400 | $150 | $400 | **~$3,000–$6,000** |
| Large | $2,500 | $1,500 | $400 | $1,200 | **~$8,000–$15,000** |
| XLarge | $6,000+ | $4,000+ | $800+ | $3,000+ | **$20,000+** |

Azure OpenAI token usage is highly variable (~$200–$5,000/mo depending on agents + traffic). The platform tracks per-agent cost via `cost_tracker.py` middleware.

---

## 10. Pre-Deployment Checklist

Print this and check off before running `scripts/install-wizard.sh`:

### Azure
- [ ] Entra tenant ID captured
- [ ] Subscription ID(s) captured (one per environment)
- [ ] Owner or Contributor + UAA role confirmed
- [ ] Required resource providers registered (or run `scripts/validate-prerequisites.sh`)
- [ ] Region selected (consult §3)
- [ ] T-shirt size selected (Small / Medium / Large / XLarge)
- [ ] Custom domain reserved & DNS zone reachable

### GitHub
- [ ] Organization created with Admin access
- [ ] GitHub App or OAuth App created — Client ID + Secret captured
- [ ] OIDC federated credential created for `Ohorizons/<your-fork>`
- [ ] Branch protection rules ready (or will be set by `setup-branch-protection.sh`)

### Azure DevOps (only if hybrid)
- [ ] Organization + Project created
- [ ] PAT generated with required scopes
- [ ] Service connection to Azure created
- [ ] Hybrid scenario (A/B/C) selected

### Local
- [ ] All CLI tools at min version (`scripts/validate-prerequisites.sh`)
- [ ] `gh auth login` completed
- [ ] `az login` + correct subscription selected (`az account set --subscription <id>`)
- [ ] Repo forked: `https://github.com/<your-org>/open-horizons-platform`
- [ ] `.env` populated from `.env.example`

When all boxes are checked, follow the [Master Installation Guide](MASTER_INSTALLATION.md) Stage 1 onwards.

---

## Related Documentation

- [Master Installation Guide](MASTER_INSTALLATION.md) — end-to-end installation flow
- [Deployment Guide](DEPLOYMENT_GUIDE.md) — 3 deploy options + 10 manual steps
- [Wizard Guide](WIZARD_GUIDE.md) — what the install wizard collects
- [Architecture Guide](ARCHITECTURE_GUIDE.md) — what gets created and why
- [Module Reference](MODULE_REFERENCE.md) — every Terraform module documented
- [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md) — common issues
- [`config/sizing-profiles.yaml`](../../config/sizing-profiles.yaml) — full machine-readable sizing data
- [`config/region-availability.yaml`](../../config/region-availability.yaml) — region/service matrix
