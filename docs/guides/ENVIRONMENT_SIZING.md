---
title: "Open Horizons — Environment Sizing & Region Guide"
description: "Per-scenario sizing matrix (POC, dev, staging, production), recommended Azure regions, and the quota pre-check to run before deploying the platform."
author: "Open Horizons"
date: "2026-06-18"
version: "1.0.0"
status: "approved"
tags: ["sizing", "regions", "quota", "terraform", "azure", "deployment"]
---

# Open Horizons — Environment Sizing & Region Guide

> Pick a scenario, confirm the region supports what you need, run the quota pre-check, then deploy. This guide keeps you from discovering a missing quota or an unavailable SKU **after** `terraform apply` has already started.

## Change Log

| Version | Date       | Author      | Changes         |
|---------|------------|-------------|-----------------|
| 1.0.0   | 2026-06-18 | Open Horizons | Initial version |

## Table of Contents

- [1. Scenarios at a Glance](#1-scenarios-at-a-glance)
- [2. Sizing Matrix](#2-sizing-matrix)
  - [2.1 AKS (Compute)](#21-aks-compute)
  - [2.2 PostgreSQL Flexible Server](#22-postgresql-flexible-server)
  - [2.3 Azure Managed Redis](#23-azure-managed-redis)
  - [2.4 Container Registry & Cross-Cutting](#24-container-registry--cross-cutting)
- [3. Recommended Regions](#3-recommended-regions)
  - [3.1 Availability Zone Support](#31-availability-zone-support)
  - [3.2 Azure-Paired Regions for DR](#32-azure-paired-regions-for-dr)
- [4. Quota Pre-Check (Run Before Deploying)](#4-quota-pre-check-run-before-deploying)
  - [4.1 Compute (vCPU) Quotas](#41-compute-vcpu-quotas)
  - [4.2 Networking & Platform Quotas](#42-networking--platform-quotas)
  - [4.3 Azure OpenAI / AI Foundry Quotas](#43-azure-openai--ai-foundry-quotas)
- [5. Pre-Deployment Checklist](#5-pre-deployment-checklist)
- [References](#references)

## 1. Scenarios at a Glance

The platform ships four ready-to-fork scenarios. Each maps to a Terraform var-file in the
[environments folder](../../terraform/environments) and a `deployment_mode`. Copy the
var-file, fill in the required identifiers, and deploy.

| Scenario       | var-file                                                              | `environment` | `deployment_mode` | Intended use                                  |
|----------------|-----------------------------------------------------------------------|---------------|-------------------|-----------------------------------------------|
| **POC**        | [poc.tfvars](../../terraform/environments/poc.tfvars)                 | `poc`         | `express`         | Evaluation, demos, throwaway. No prod data.   |
| **Dev**        | [dev.tfvars](../../terraform/environments/dev.tfvars)                 | `dev`         | `express`         | Shared developer environment.                 |
| **Staging**    | [staging.tfvars](../../terraform/environments/staging.tfvars)         | `staging`     | `standard`        | Pre-production validation with HA.            |
| **Production** | [production.tfvars](../../terraform/environments/production.tfvars)   | `prod`        | `enterprise`      | Production: multi-zone, DR, Defender, Purview.|

> The `deployment_mode` and the team-size profiles in
> [config/sizing-profiles.yaml](../../config/sizing-profiles.yaml) drive the concrete SKUs and
> node counts. The tables below are the **reference targets** each scenario aims for; tune them
> for your workload and budget.

For a real Azure proof run with preflight, plan, integration validation, evidence, and cleanup, use the [Azure Validation Runbook](AZURE_VALIDATION_RUNBOOK.md).

## 2. Sizing Matrix

### 2.1 AKS (Compute)

| Dimension          | POC               | Dev               | Staging                 | Production                       |
|--------------------|-------------------|-------------------|-------------------------|----------------------------------|
| Pricing tier (SLA) | Free (no SLA)     | Free (no SLA)     | Standard (99.95% w/ AZ) | Standard (99.95% w/ AZ)          |
| Kubernetes version | 1.34              | 1.34              | 1.34                    | 1.34                             |
| System node size   | `Standard_D2s_v5` | `Standard_D2s_v5` | `Standard_D4s_v5`       | `Standard_D8s_v5`                |
| System node count  | 1–2               | 2–3               | 3                       | 3–5                              |
| Availability zones  | None              | None              | 1, 2, 3                 | 1, 2, 3                          |
| LTS / Premium tier | No                | No                | Optional                | Optional (Premium for AKS LTS)   |

> **Kubernetes version**: AKS supports the latest minor and the two before it (N, N-1, N-2). Versions
> 1.29 and 1.30 are end-of-life — always pin a currently supported minor and enable an auto-upgrade
> channel for patches. Confirm the version is offered in your region with
> `az aks get-versions --location <region> -o table` before deploying.

### 2.2 PostgreSQL Flexible Server

| Dimension          | POC                 | Dev                 | Staging                  | Production                       |
|--------------------|---------------------|---------------------|--------------------------|----------------------------------|
| Compute tier       | Burstable           | Burstable           | General Purpose          | General Purpose                  |
| SKU                | `B_Standard_B1ms`   | `B_Standard_B2ms`   | `GP_Standard_D2ds_v5`    | `GP_Standard_D4ds_v5` (or larger)|
| High availability   | Disabled            | Disabled            | Zone-redundant           | Zone-redundant                   |
| Backup retention   | 7 days              | 7 days              | 14 days                  | 35 days                          |
| Geo-redundant backup | No                | No                  | Optional                 | Yes                              |

> **Burstable is non-production by design.** Microsoft positions the Burstable tier for workloads
> that do not need full CPU continuously and does **not** support high availability on it. Use
> General Purpose (Ddsv5) or Memory Optimized (Edsv5) for staging and production, where
> zone-redundant HA is available.

### 2.3 Azure Managed Redis

The platform provisions **Azure Managed Redis** (`Microsoft.Cache/redisEnterprise`) via the
`azapi` provider, because classic Azure Cache for Redis is retiring for new creations.

| Dimension            | POC            | Dev            | Staging        | Production                  |
|----------------------|----------------|----------------|----------------|-----------------------------|
| SKU                  | `Balanced_B0`  | `Balanced_B0`  | `Balanced_B1`  | `Balanced_B3` (or larger)   |
| High availability     | Disabled       | Disabled       | Enabled        | Enabled                     |
| Public network access | Disabled       | Disabled       | Disabled       | Disabled (private endpoint) |
| Minimum TLS          | 1.2            | 1.2            | 1.2            | 1.2                         |
| Clustering policy    | `OSSCluster`   | `OSSCluster`   | `EnterpriseCluster` | `EnterpriseCluster`    |
| Eviction policy      | `VolatileLRU`  | `VolatileLRU`  | `NoEviction`   | `NoEviction`                |
| Modules (optional)   | —              | —              | RediSearch     | RediSearch + RedisJSON      |

> **Notes.** High availability can be disabled **only** for dev/test SKUs; `Balanced_B0`/`Balanced_B1`
> have no geo-replication. Enable the `RediSearch` and `RedisJSON` modules when you use Redis as a
> semantic cache or vector memory store for agents. `RediSearch` requires `EnterpriseCluster` and
> `NoEviction`; do not use it with `OSSCluster`, `VolatileLRU`, or `FlashOptimized_*` SKUs. Valid SKU families are `Balanced_*`,
> `MemoryOptimized_*`, `ComputeOptimized_*`, and `FlashOptimized_*` — there is **no** `Enterprise_*`
> family in Azure Managed Redis. The private endpoint subresource group is `redisEnterprise` and its
> private DNS zone is `privatelink.redis.azure.net`.

### 2.4 Container Registry & Cross-Cutting

| Dimension                  | POC      | Dev      | Staging   | Production |
|----------------------------|----------|----------|-----------|------------|
| Container Registry SKU     | Basic    | Basic    | Standard  | Premium    |
| Private endpoints          | Optional | Partial  | Yes       | Yes (all)  |
| Microsoft Defender for Cloud | Off    | Off      | Optional  | On         |
| Microsoft Purview          | Off      | Off      | Optional  | On         |
| Cost management + budgets  | Off      | Off      | Optional  | On         |
| Disaster recovery (DR)     | No       | No       | No        | Yes        |

> ACR **Premium** is required for private endpoints, geo-replication, and content trust — that is why
> production pins Premium while lower tiers use Basic/Standard.

## 3. Recommended Regions

Choose a region that (1) has **Availability Zones** if you need HA, (2) offers the **Azure OpenAI**
models you plan to deploy, and (3) has a sensible **Azure-paired region** for DR. Confirm current
availability with `az account list-locations -o table` and the per-service availability pages.

| Priority | Region          | Azure name       | Availability Zones | Notes                                              |
|----------|-----------------|------------------|--------------------|----------------------------------------------------|
| Primary  | East US 2       | `eastus2`        | Yes                | Broad service + Azure OpenAI availability.         |
| Primary  | Brazil South    | `brazilsouth`    | Yes                | Best in-country latency for Brazil; data residency.|
| Alt      | Sweden Central  | `swedencentral`  | Yes                | Strong AI/OpenAI availability in EU.               |
| Alt      | West Europe     | `westeurope`     | Yes                | EU data residency.                                 |
| Avoid (prod) | West US     | `westus`         | No                 | No Availability Zones — not for zone-redundant HA. |
| Avoid (prod) | North Central US | `northcentralus` | No             | No Availability Zones — not for zone-redundant HA. |

### 3.1 Availability Zone Support

Zone-redundant AKS, PostgreSQL HA, and the Standard AKS SLA (99.95%) all require a region with
Availability Zones. The following commonly used regions have AZ support: `eastus2`, `eastus`,
`brazilsouth`, `centralus`, `southcentralus`, `westus2`, `westus3`, `canadacentral`, `westeurope`,
`northeurope`, `uksouth`, `swedencentral`. Always confirm against the official region-support list
(see References), because coverage changes over time.

### 3.2 Azure-Paired Regions for DR

When `enable_disaster_recovery = true`, set `dr_location` to the source region's Azure-paired region
so platform replication follows Microsoft's recommended pairing:

| Primary (`location`) | DR (`dr_location`)     |
|----------------------|------------------------|
| `eastus2`            | `centralus`            |
| `brazilsouth`        | `southcentralus`       |
| `westeurope`         | `northeurope`          |

## 4. Quota Pre-Check (Run Before Deploying)

Run these checks in the **target subscription and region** before `terraform apply`. A failed quota
is the most common cause of a half-applied deployment. Sign in first:

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
REGION="eastus2"   # match your tfvars `location`
```

### 4.1 Compute (vCPU) Quotas

AKS nodes use the Dsv5 / Ddsv5 families. Check both the **Total Regional vCPUs** limit and the
**per-family** limit. A 3-node `Standard_D8s_v5` production pool needs 24 vCPUs from the
`standardDSv5Family` alone, plus headroom for upgrades (surge) and user pools.

```bash
# Per-family and regional vCPU usage vs. limit
az vm list-usage --location "$REGION" -o table \
  | grep -Ei 'Total Regional vCPUs|standardDSv5Family|standardDDSv5Family'
```

| Scenario   | Rough vCPU need (system pool) | Watch these limits                               |
|------------|-------------------------------|--------------------------------------------------|
| POC / Dev  | 4–12                          | Total Regional vCPUs, `standardDSv5Family`        |
| Staging    | 12                            | Total Regional vCPUs, `standardDSv5Family`        |
| Production | 24–40 (+ surge & user pools)  | Total Regional vCPUs, `standardDSv5Family`, `standardDDSv5Family` |

### 4.2 Networking & Platform Quotas

```bash
# Public IP addresses (Load Balancer, NAT Gateway, App Gateway)
az network list-usages --location "$REGION" -o table \
  | grep -Ei 'PublicIPAddresses|StandardSku'

# Resource providers must be registered (one-time per subscription)
az provider show -n Microsoft.ContainerService --query registrationState -o tsv
az provider show -n Microsoft.DBforPostgreSQL  --query registrationState -o tsv
az provider show -n Microsoft.Cache            --query registrationState -o tsv  # Azure Managed Redis
az provider show -n Microsoft.ContainerRegistry --query registrationState -o tsv
az provider show -n Microsoft.CognitiveServices --query registrationState -o tsv # AI Foundry / OpenAI

# Register any that report "NotRegistered"
az provider register -n Microsoft.Cache
```

> **New subscriptions** frequently need `Microsoft.ContainerRegistry` and `Microsoft.Cache`
> registered before the first deploy. Registration is async — re-check `registrationState` until it
> reads `Registered`.

### 4.3 Azure OpenAI / AI Foundry Quotas

When `enable_ai_foundry = true`, model deployments consume a **Tokens-Per-Minute (TPM)** quota that
is **per region, per model, per subscription**. This quota is not visible through `az vm list-usage`
and often must be raised through a support/quota request.

```bash
# List AI Foundry / Cognitive Services accounts and their model deployments
az cognitiveservices account list -o table
az cognitiveservices account deployment list \
  --name "<FOUNDRY_ACCOUNT>" --resource-group "<RG>" -o table
```

Confirm in the **Azure AI Foundry portal → Quotas** (or **Azure Portal → Quotas → Cognitive
Services**) that the region has enough TPM for the models you plan to deploy **before** enabling AI
Foundry. If `az quota list` returns `BadRequest` for Cognitive Services, raise the increase through a
support request (Service and subscription limits → Cognitive Services) instead.

## 5. Pre-Deployment Checklist

- [ ] Chosen scenario var-file copied and required identifiers filled in (`customer_name`, `azure_subscription_id`, `azure_tenant_id`, `admin_group_id`, `github_org`).
- [ ] `location` (and `dr_location` for production) selected from [Section 3](#3-recommended-regions).
- [ ] Region has Availability Zones if the scenario uses HA (staging/production).
- [ ] `az aks get-versions --location "$REGION"` confirms the pinned Kubernetes version is offered.
- [ ] vCPU quota verified for the Dsv5/Ddsv5 families ([Section 4.1](#41-compute-vcpu-quotas)).
- [ ] Public IP quota verified ([Section 4.2](#42-networking--platform-quotas)).
- [ ] Required resource providers show `Registered` (`Microsoft.Cache`, `Microsoft.ContainerRegistry`, …).
- [ ] Azure OpenAI TPM quota confirmed for the target region (if `enable_ai_foundry = true`).
- [ ] Secrets exported as `TF_VAR_*` (never committed): `github_token`, `argocd_admin_password`, etc.
- [ ] `terraform plan -var-file=environments/<scenario>.tfvars` reviewed with no surprises.

## References

- [Supported Kubernetes versions in AKS](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions) — Microsoft Learn
- [AKS Free, Standard, and Premium pricing tiers (SLA)](https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers) — Microsoft Learn
- [Azure Database for PostgreSQL flexible server — compute and storage](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compute) — Microsoft Learn
- [Azure Database for PostgreSQL flexible server — high availability](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-high-availability) — Microsoft Learn
- [Azure Managed Redis overview](https://learn.microsoft.com/en-us/azure/redis/managed-redis/managed-redis-overview) — Microsoft Learn
- [Azure Managed Redis — choosing the right tier](https://learn.microsoft.com/en-us/azure/redis/managed-redis/managed-redis-overview#choosing-the-right-tier) — Microsoft Learn
- [Azure Container Registry SKUs](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-skus) — Microsoft Learn
- [Azure regions with Availability Zone support](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-region-support) — Microsoft Learn
- [Azure cross-region replication (paired regions)](https://learn.microsoft.com/en-us/azure/reliability/cross-region-replication-azure) — Microsoft Learn
- [View and manage Azure quotas](https://learn.microsoft.com/en-us/azure/quotas/view-quotas) — Microsoft Learn
- [Azure VM vCPU quotas](https://learn.microsoft.com/en-us/azure/virtual-machines/quotas) — Microsoft Learn
- [Azure OpenAI / AI Foundry quotas and limits](https://learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits) — Microsoft Learn
- [Register an Azure resource provider](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types) — Microsoft Learn
