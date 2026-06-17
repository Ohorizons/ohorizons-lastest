# Open Horizons Platform - Module Reference

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** Platform Engineers, DevOps Engineers, Infrastructure Architects

---

## Table of Contents

1. [Understanding Terraform Modules](#1-understanding-terraform-modules)
2. [Module Overview](#2-module-overview)
3. [H1 Foundation Modules](#3-h1-foundation-modules)
4. [H2 Enhancement Modules](#4-h2-enhancement-modules)
5. [H3 Innovation Modules](#5-h3-innovation-modules)
6. [Cross-Cutting Modules](#6-cross-cutting-modules)
7. [Module Dependencies and Execution Order](#7-module-dependencies-and-execution-order)
8. [Common Usage Patterns](#8-common-usage-patterns)
9. [Troubleshooting Module Issues](#9-troubleshooting-module-issues)

---

## 1. Understanding Terraform Modules

Before diving into the specific modules, let's understand what Terraform modules are and why we use them.

### 1.1 What is a Terraform Module?

> 💡 **Concept: Terraform Modules**
>
> Think of a Terraform module like a **LEGO building set**:
> - Each set (module) contains all the pieces needed to build something specific
> - You can combine multiple sets to build something bigger
> - Each set has clear instructions (inputs/outputs) for how to use it
> - You can use the same set multiple times in different builds
>
> In technical terms: A module is a **container for multiple resources** that are used together. It's a way to package and reuse infrastructure code.

**Without modules** (everything in one file):
![Modules vs Monolithic](../assets/mod-with-without-modules.svg)


**With modules** (organized and reusable):


### 1.2 Module Structure

Every module in this accelerator follows a standard structure:

![Module File Structure](../assets/mod-file-structure.svg)


> 💡 **Understanding the Files**
>
> | File | Purpose | Analogy |
> |------|---------|---------|
> | `variables.tf` | Inputs you provide | The order form - what do you want? |
> | `main.tf` | The infrastructure logic | The factory - builds your order |
> | `outputs.tf` | Values returned to you | The receipt - what you got |
> | `versions.tf` | Required versions | Compatibility requirements |

### 1.3 How Modules Connect

Modules communicate through **inputs (variables)** and **outputs**:

![How Modules Connect](../assets/mod-how-modules-connect.svg)

### 1.4 When to Use Which Module

Here's a decision guide for which modules to use:

![Module Selection Guide](../assets/mod-module-selection.svg)

---

## 2. Module Overview

### 2.1 Module Directory Structure

![Module Directory](../assets/mod-directory-structure.svg)


### 2.2 Module Categories Explained

> 💡 **Open Horizons Model**
>
> The modules are organized into "horizons" based on their purpose:
>
> | Horizon | Purpose | When to Deploy | Examples |
> |---------|---------|----------------|----------|
> | **H1** | Foundation | Always first | Network, AKS, Security |
> | **H2** | Enhancement | After H1 is stable | GitOps, Monitoring |
> | **H3** | Innovation | When ready for AI/ML | Azure OpenAI |
>
> Think of it like building a house:
> - H1 = Foundation and walls (must have)
> - H2 = Electrical and plumbing (makes it functional)
> - H3 = Smart home features (nice to have)

---

## 3. H1 Foundation Modules

These modules create the core infrastructure that everything else depends on.

---

### 3.1 Naming Module

**Path:** `terraform/modules/naming`

> 💡 **Why This Module Exists**
>
> Azure has specific naming rules for each resource type:
> - Storage accounts: max 24 characters, lowercase, no hyphens
> - Key Vault: max 24 characters
> - ACR: no hyphens allowed
>
> This module automatically generates **compliant names** for all resources,
> ensuring consistency and preventing deployment failures.

#### The Problem It Solves

```
WITHOUT naming module:
─────────────────────
storage_account_name = "contoso-dev-storage"     ❌ Fails (has hyphens)
key_vault_name = "contoso-development-keyvault"  ❌ Fails (>24 chars)
acr_name = "contoso-dev-acr"                     ❌ Fails (has hyphens)

WITH naming module:
──────────────────
All names are automatically generated correctly!
```

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | **Yes** | - | Customer identifier (max 12 characters, lowercase) |
| `environment` | string | **Yes** | - | Environment: `dev`, `staging`, or `prod` |
| `region` | string | **Yes** | - | Azure region (e.g., `brazilsouth`, `eastus`) |
| `project` | string | No | `"platform"` | Project or workload name |

> ⚠️ **Important Constraints**
>
> - `customer_name` must be **12 characters or less** (Azure imposes limits)
> - Use **lowercase** only
> - Avoid special characters

#### Outputs

| Output | Description | Example Value |
|--------|-------------|---------------|
| `resource_group_name` | Resource group name | `rg-contoso-dev-brs` |
| `aks_cluster_name` | AKS cluster name | `aks-contoso-dev-brs` |
| `storage_account_name` | Storage (24 char, no hyphens) | `stcontosodevbrs` |
| `container_registry_name` | ACR (no hyphens) | `acrcontosodevbrs` |
| `key_vault_name` | Key Vault (24 char max) | `kv-contoso-dev-brs` |
| `region_short` | 3-letter region code | `brs` (for brazilsouth) |

#### Usage Example

```hcl
# Step 1: Create the naming module (ALWAYS FIRST!)
module "naming" {
  source = "./modules/naming"

  customer_name = "contoso"      # Your company/customer name
  environment   = "dev"          # dev, staging, or prod
  region        = "brazilsouth"  # Azure region
  project       = "platform"     # Optional: project name
}

# Step 2: Use the generated names everywhere
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group_name  # "rg-contoso-dev-brs"
  location = var.location
}

module "security" {
  source = "./modules/security"

  key_vault_name = module.naming.key_vault_name  # "kv-contoso-dev-brs"
  # ... other variables
}

module "acr" {
  source = "./modules/container-registry"

  name = module.naming.container_registry_name  # "acrcontosodevbrs"
  # ... other variables
}
```

#### How Names Are Generated

![Naming Logic](../assets/mod-naming-logic.svg)

#### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Name too long" | customer_name > 12 chars | Shorten customer_name |
| "Invalid characters" | Uppercase or special chars | Use lowercase, alphanumeric only |
| "Name already exists" | Storage/ACR names are global | Add unique suffix or change customer_name |

---

### 3.2 Networking Module

**Path:** `terraform/modules/networking`

> 💡 **Why This Module Exists**
>
> Every Azure resource needs a network. This module creates a **secure, production-ready network** with:
> - Virtual Network (VNet) - Your private network in Azure
> - Subnets - Logical divisions of the VNet
> - NSGs - Firewalls that control traffic
> - Private DNS - Internal name resolution
>
> Think of it as creating the **roads, neighborhoods, and addresses** for your infrastructure.

#### Network Architecture Created

![Network Architecture](../assets/arch-network-topology.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | **Yes** | - | Customer identifier |
| `environment` | string | **Yes** | - | Environment (dev/staging/prod) |
| `location` | string | **Yes** | - | Azure region |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `vnet_cidr` | string | **Yes** | - | VNet address space (e.g., "10.0.0.0/16") |
| `subnet_config` | object | No | See below | Custom subnet CIDRs |
| `enable_bastion` | bool | No | `false` | Create Azure Bastion for secure VM access |
| `enable_app_gateway` | bool | No | `false` | Create App Gateway subnet |
| `dns_zone_name` | string | **Yes** | - | DNS zone name for services |
| `create_dns_zone` | bool | No | `false` | Create public DNS zone |
| `tags` | map(string) | No | `{}` | Resource tags |

#### Subnet Configuration Object

> 💡 **Understanding CIDR Notation**
>
> CIDR notation like `10.0.0.0/22` defines a range of IP addresses:
> - `/16` = 65,536 addresses (e.g., 10.0.0.0 - 10.0.255.255)
> - `/20` = 4,096 addresses
> - `/22` = 1,024 addresses
> - `/24` = 256 addresses
> - `/26` = 64 addresses

```hcl
subnet_config = {
  # AKS nodes - one IP per VM node
  aks_nodes_cidr = "10.0.0.0/22"           # 1,024 IPs for nodes

  # AKS pods (with CNI Overlay) - one IP per pod
  aks_pods_cidr = "10.0.16.0/20"           # 4,096 IPs for pods

  # Private endpoints - for secure Azure service connections
  private_endpoints_cidr = "10.0.4.0/24"   # 256 IPs

  # Azure Bastion - secure remote access
  bastion_cidr = "10.0.5.0/26"             # 64 IPs (Azure requirement)

  # Application Gateway - ingress traffic
  app_gateway_cidr = "10.0.6.0/24"         # 256 IPs
}
```

> ⚠️ **CIDR Planning Warning**
>
> Plan your CIDRs carefully! Changing them later requires destroying and recreating resources.
>
> **Recommended sizes by environment:**
>
> | Environment | VNet CIDR | Nodes Subnet | Pods Subnet |
> |-------------|-----------|--------------|-------------|
> | Dev | /16 | /22 (1K IPs) | /20 (4K IPs) |
> | Staging | /16 | /21 (2K IPs) | /19 (8K IPs) |
> | Prod | /15 | /20 (4K IPs) | /18 (16K IPs) |

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `vnet_id` | VNet resource ID | AKS, Private Endpoints |
| `vnet_name` | VNet name | Reference |
| `aks_nodes_subnet_id` | Subnet ID for AKS nodes | AKS module |
| `aks_pods_subnet_id` | Subnet ID for pods | AKS module (CNI Overlay) |
| `private_endpoints_subnet_id` | Subnet for private endpoints | ACR, Key Vault, PostgreSQL |
| `bastion_subnet_id` | Bastion subnet ID | VM access |
| `nsg_aks_nodes_id` | NSG for AKS nodes | Security rules |
| `private_dns_zone_ids` | Map of DNS zone IDs | Private endpoint DNS |

#### Usage Example

```hcl
# Create the networking infrastructure
module "networking" {
  source = "./modules/networking"

  # Basic identification
  customer_name       = "contoso"
  environment         = "dev"
  location            = "brazilsouth"
  resource_group_name = azurerm_resource_group.main.name

  # Network configuration
  vnet_cidr     = "10.0.0.0/16"
  dns_zone_name = "contoso.internal"

  # Optional features
  enable_bastion    = true   # Enable if you need VM access
  enable_app_gateway = false  # Enable if using App Gateway ingress
  create_dns_zone   = false  # Set true if you own the DNS zone

  # Custom subnet sizes (optional - defaults shown)
  subnet_config = {
    aks_nodes_cidr         = "10.0.0.0/22"
    aks_pods_cidr          = "10.0.16.0/20"
    private_endpoints_cidr = "10.0.4.0/24"
    bastion_cidr           = "10.0.5.0/26"
    app_gateway_cidr       = "10.0.6.0/24"
  }

  tags = var.tags
}
```

#### NSG Rules Created

The module creates Network Security Groups with these default rules:

![NSG Rules](../assets/nsg-rules-table.svg)

#### Private DNS Zones Created

The module creates private DNS zones for Azure services:

| DNS Zone | Purpose |
|----------|---------|
| `privatelink.azurecr.io` | Azure Container Registry |
| `privatelink.vaultcore.azure.net` | Azure Key Vault |
| `privatelink.postgres.database.azure.com` | PostgreSQL |
| `privatelink.redis.cache.windows.net` | Redis Cache |
| `privatelink.blob.core.windows.net` | Blob Storage |

> 💡 **What Private DNS Zones Do**
>
> When you access a resource like `mykeyvault.vault.azure.net` from within the VNet,
> the private DNS zone resolves it to the **private IP** instead of the public IP.
>
> ```
> From Internet:    mykeyvault.vault.azure.net → 52.x.x.x (public)
> From VNet:        mykeyvault.vault.azure.net → 10.0.4.5 (private)
> ```

---

### 3.3 AKS Cluster Module

**Path:** `terraform/modules/aks-cluster`

> 💡 **Why This Module Exists**
>
> Azure Kubernetes Service (AKS) is the heart of the platform. This module creates a
> **production-ready Kubernetes cluster** with:
> - Multiple node pools for different workloads
> - Workload identity for secure Azure access
> - Network configuration for security
> - Automatic scaling
>
> Think of AKS as the **operating system** for running your containerized applications.

#### Cluster Architecture

![AKS Cluster Architecture](../assets/arch-aks-cluster.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `location` | string | **Yes** | - | Azure region |
| `customer_name` | string | **Yes** | - | Customer identifier |
| `environment` | string | **Yes** | - | Environment |
| `kubernetes_version` | string | No | `"1.29"` | Kubernetes version |
| `sku_tier` | string | No | `"Standard"` | SKU tier (Free/Standard/Premium) |
| `vnet_subnet_id` | string | **Yes** | - | Subnet for AKS nodes |
| `pod_subnet_id` | string | No | `null` | Subnet for pods (CNI Overlay) |
| `system_node_pool` | object | No | See below | System pool config |
| `user_node_pools` | list(object) | No | `[]` | User pool configs |
| `acr_id` | string | No | `null` | ACR for image pulling |
| `key_vault_id` | string | No | `null` | Key Vault for secrets |
| `log_analytics_id` | string | No | `null` | For container insights |
| `addons` | object | No | See below | AKS addons |
| `workload_identity` | bool | No | `true` | Enable workload identity |
| `tags` | map(string) | No | `{}` | Resource tags |

#### SKU Tier Explanation

> 💡 **Understanding AKS SKU Tiers**
>
> | Tier | SLA | Cost | Features | Use Case |
> |------|-----|------|----------|----------|
> | **Free** | None | Free | Basic features | Development, testing |
> | **Standard** | 99.95% | ~$73/month | + Financial SLA, + Cluster Autoscaler improvements | Production workloads |
> | **Premium** | 99.99% | ~$292/month | + Long-term support, + Azure CNI Overlay advanced | Mission-critical |
>
> **Recommendation:** Use Standard for production, Free for dev/test.

#### System Node Pool Configuration

```hcl
# This pool runs Kubernetes system components
system_node_pool = {
  name       = "system"          # Pool name
  vm_size    = "Standard_D4s_v5" # 4 vCPU, 16 GB RAM
  node_count = 3                 # Fixed count (no autoscaling)
  zones      = ["1", "2", "3"]   # Spread across availability zones
}
```

> 💡 **Why System Node Pool is Special**
>
> - Runs critical components: CoreDNS, kube-proxy, metrics-server
> - Has a **CriticalAddonsOnly** taint - user workloads won't be scheduled here
> - Should have **fixed count** (3 nodes) for stability
> - Spread across **3 zones** for high availability

#### User Node Pool Configuration

```hcl
user_node_pools = [
  {
    # General purpose workloads
    name      = "user"
    vm_size   = "Standard_D8s_v5"  # 8 vCPU, 32 GB RAM
    min_count = 3                   # Minimum nodes
    max_count = 10                  # Maximum nodes (autoscale!)
    zones     = ["1", "2", "3"]     # High availability
    labels    = {
      workload = "general"
    }
    taints    = []                  # No taints - accepts all pods
  },
  {
    # GPU workloads (optional)
    name      = "gpu"
    vm_size   = "Standard_NC6s_v3"  # NVIDIA V100 GPU
    min_count = 0                    # Can scale to zero!
    max_count = 5
    zones     = ["1"]                # GPUs often limited to 1 zone
    labels    = {
      workload    = "gpu"
      accelerator = "nvidia"
    }
    taints    = ["gpu=true:NoSchedule"]  # Only GPU pods scheduled here
  }
]
```

> 💡 **Understanding Taints and Tolerations**
>
> **Taints** on nodes repel pods that don't have matching **tolerations**.
>
> ```
> Node with taint:          Pod without toleration:
> gpu=true:NoSchedule  →    ❌ Won't be scheduled
>
> Node with taint:          Pod with toleration:
> gpu=true:NoSchedule  →    ✅ Will be scheduled
> ```
>
> This ensures only GPU workloads run on expensive GPU nodes!

#### Addons Configuration

```hcl
addons = {
  azure_policy           = true   # Enforce governance policies
  azure_keyvault_secrets = true   # CSI driver for secrets
  oms_agent              = true   # Container Insights monitoring
}
```

| Addon | What It Does | When to Enable |
|-------|--------------|----------------|
| `azure_policy` | Enforces Kubernetes policies via Azure Policy | Always (security) |
| `azure_keyvault_secrets` | Mounts Key Vault secrets as volumes | If using native secret mounting |
| `oms_agent` | Sends container logs to Log Analytics | Always (observability) |

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `cluster_id` | AKS cluster resource ID | Observability, RBAC |
| `cluster_name` | AKS cluster name | kubectl configuration |
| `cluster_fqdn` | API server FQDN | Client configuration |
| `kube_config` | Kubeconfig for cluster access | kubectl, Helm |
| `kubelet_identity_id` | Managed identity for nodes | ACR pull permissions |
| `oidc_issuer_url` | OIDC URL for workload identity | Security module |
| `node_resource_group` | Auto-created MC_* resource group | Reference |

#### Usage Example

```hcl
module "aks" {
  source = "./modules/aks-cluster"

  # Basic configuration
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  customer_name       = var.customer_name
  environment         = var.environment

  # Kubernetes version
  kubernetes_version = "1.29"
  sku_tier           = "Standard"  # Use "Free" for dev

  # Network - connect to networking module
  vnet_subnet_id = module.networking.aks_nodes_subnet_id
  pod_subnet_id  = module.networking.aks_pods_subnet_id

  # Integrations
  acr_id           = module.acr.acr_id             # For pulling images
  key_vault_id     = module.security.key_vault_id  # For secrets
  log_analytics_id = module.observability.log_analytics_workspace_id

  # Enable workload identity (recommended)
  workload_identity = true

  # System node pool (fixed size, critical components)
  system_node_pool = {
    name       = "system"
    vm_size    = "Standard_D4s_v5"
    node_count = 3
    zones      = ["1", "2", "3"]
  }

  # User node pools (autoscaling, your workloads)
  user_node_pools = [
    {
      name      = "user"
      vm_size   = "Standard_D8s_v5"
      min_count = 3
      max_count = 10
      zones     = ["1", "2", "3"]
      labels    = { workload = "general" }
      taints    = []
    }
  ]

  # Addons
  addons = {
    azure_policy           = true
    azure_keyvault_secrets = true
    oms_agent              = true
  }

  tags = var.tags
}
```

#### After Deployment: Connect to the Cluster

```bash
# Get credentials for kubectl
az aks get-credentials \
  --resource-group "rg-contoso-dev-brs" \
  --name "aks-contoso-dev-brs"

# Verify connection
kubectl get nodes

# Expected output:
# NAME                              STATUS   ROLES   AGE   VERSION
# aks-system-12345678-vmss000000    Ready    agent   1d    v1.29.0
# aks-system-12345678-vmss000001    Ready    agent   1d    v1.29.0
# aks-system-12345678-vmss000002    Ready    agent   1d    v1.29.0
# aks-user-12345678-vmss000000      Ready    agent   1d    v1.29.0
# aks-user-12345678-vmss000001      Ready    agent   1d    v1.29.0
# aks-user-12345678-vmss000002      Ready    agent   1d    v1.29.0
```

---

### 3.4 Container Registry Module

**Path:** `terraform/modules/container-registry`

> 💡 **Why This Module Exists**
>
> Applications running on Kubernetes need container images. Azure Container Registry (ACR)
> provides a **private, secure registry** for your images, integrated with Azure AD
> and accessible via private endpoints.
>
> Think of ACR as your **private Docker Hub** - only your authorized users and systems
> can push/pull images.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `name` | string | **Yes** | - | ACR name (alphanumeric only, globally unique) |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `location` | string | **Yes** | - | Azure region |
| `sku` | string | No | `"Premium"` | SKU: Basic, Standard, Premium |
| `admin_enabled` | bool | No | `false` | Enable admin user (not recommended) |
| `public_network_access_enabled` | bool | No | `false` | Allow public access |
| `zone_redundancy_enabled` | bool | No | `true` | Multi-zone storage |
| `georeplications` | list(object) | No | `[]` | Replicate to other regions |
| `private_endpoint_subnet_id` | string | No | `null` | For private access |
| `private_dns_zone_id` | string | No | `null` | Private DNS zone |
| `tags` | map(string) | No | `{}` | Resource tags |

#### SKU Comparison

> 💡 **Choosing ACR SKU**
>
> | Feature | Basic | Standard | Premium |
> |---------|-------|----------|---------|
> | Storage | 10 GB | 100 GB | 500 GB |
> | Webhooks | 2 | 10 | 500 |
> | Geo-replication | ❌ | ❌ | ✅ |
> | Private endpoints | ❌ | ❌ | ✅ |
> | Content trust | ❌ | ❌ | ✅ |
> | Customer-managed keys | ❌ | ❌ | ✅ |
> | Price (approx) | $5/mo | $20/mo | $50/mo |
>
> **Recommendation:** Use **Premium** for production (private endpoints required for security).

> ⚠️ **Important: ACR Naming Rules**
>
> - Must be **globally unique** across all of Azure
> - **Alphanumeric only** (no hyphens, underscores)
> - 5-50 characters
> - Use the naming module to generate compliant names!

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `acr_id` | ACR resource ID | AKS (pull permissions) |
| `acr_name` | ACR name | Image tagging |
| `login_server` | ACR URL (e.g., `contoso.azurecr.io`) | Docker push/pull |
| `admin_username` | Admin username (if enabled) | Emergency access |
| `admin_password` | Admin password (if enabled) | Emergency access |

#### Usage Example

```hcl
module "acr" {
  source = "./modules/container-registry"

  # Use naming module for compliant name
  name                = module.naming.container_registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Production settings
  sku = "Premium"  # Required for private endpoints

  # Security: disable public access
  admin_enabled                 = false  # Don't use admin account
  public_network_access_enabled = false  # Only private access

  # High availability
  zone_redundancy_enabled = true

  # Private endpoint configuration
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  private_dns_zone_id        = module.networking.private_dns_zone_ids["acr"]

  tags = var.tags
}
```

#### How AKS Pulls Images from ACR

![Image Pull Flow](../assets/mod-image-pull-flow.svg)

The AKS module automatically:
1. Creates a managed identity for kubelet
2. Assigns `AcrPull` role to that identity on your ACR
3. Configures AKS to use that identity

---

### 3.5 Security Module

**Path:** `terraform/modules/security`

> 💡 **Why This Module Exists**
>
> Security is foundational. This module creates:
> - **Key Vault**: Secure storage for secrets, keys, and certificates
> - **Managed Identities**: Passwordless authentication for Azure resources
> - **Workload Identity**: Allows Kubernetes pods to authenticate to Azure
>
> Think of this module as the **security backbone** - it enables Zero Trust architecture
> where nothing trusts anything by default.

#### What This Module Creates

![Security Module Resources](../assets/mod-security-resources.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | **Yes** | - | Customer identifier |
| `environment` | string | **Yes** | - | Environment |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `location` | string | **Yes** | - | Azure region |
| `key_vault_name` | string | **Yes** | - | Key Vault name |
| `tenant_id` | string | **Yes** | - | Azure AD tenant ID |
| `enable_rbac_authorization` | bool | No | `true` | Use RBAC for Key Vault |
| `private_endpoint_subnet_id` | string | No | `null` | For private access |
| `private_dns_zone_id` | string | No | `null` | Private DNS zone |
| `create_workload_identity` | bool | No | `true` | Create workload identity |
| `aks_oidc_issuer_url` | string | No | `null` | AKS OIDC URL for federation |
| `tags` | map(string) | No | `{}` | Resource tags |

#### Key Vault Access: RBAC vs Access Policies

> 💡 **Understanding Key Vault Access Models**
>
> **RBAC Authorization** (Recommended):
> - Uses Azure RBAC roles (Key Vault Administrator, Key Vault Secrets User, etc.)
> - Permissions managed at Azure level
> - Easier to audit and manage
> - Works with Managed Identities seamlessly
>
> **Access Policies** (Legacy):
> - Each identity needs a policy configured in Key Vault
> - More complex to manage
> - Being phased out by Microsoft
>
> **Always use RBAC** (`enable_rbac_authorization = true`) for new deployments.

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `key_vault_id` | Key Vault resource ID | AKS, External Secrets |
| `key_vault_name` | Key Vault name | Secret references |
| `key_vault_uri` | Key Vault URL | SDK configuration |
| `aks_identity_id` | AKS managed identity ID | AKS module |
| `aks_identity_principal_id` | Identity principal ID | RBAC assignments |
| `workload_identity_id` | Workload identity ID | Pod authentication |
| `workload_identity_client_id` | Client ID for pods | ServiceAccount annotation |

#### Usage Example

```hcl
module "security" {
  source = "./modules/security"

  customer_name       = var.customer_name
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Key Vault configuration
  key_vault_name            = module.naming.key_vault_name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true  # Always use RBAC

  # Private endpoint for security
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  private_dns_zone_id        = module.networking.private_dns_zone_ids["keyvault"]

  # Workload Identity for Kubernetes pods
  create_workload_identity = true
  aks_oidc_issuer_url      = module.aks.oidc_issuer_url  # From AKS module

  tags = var.tags
}
```

#### How Workload Identity Works

![Workload Identity Flow](../assets/arch-workload-identity.svg)

---

### 3.6 Databases Module

**Path:** `terraform/modules/databases`

> 💡 **Why This Module Exists**
>
> Applications need persistent data storage. This module creates:
> - **PostgreSQL Flexible Server**: Relational database for structured data
> - **Redis Cache**: In-memory cache for high-performance access
>
> Both are configured with **high availability**, **private endpoints**, and
> **credentials stored in Key Vault**.

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | **Yes** | - | Customer identifier |
| `environment` | string | **Yes** | - | Environment |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `location` | string | **Yes** | - | Azure region |
| `enable_postgresql` | bool | No | `true` | Create PostgreSQL |
| `postgresql_config` | object | No | See below | PostgreSQL settings |
| `enable_redis` | bool | No | `false` | Create Redis Cache |
| `redis_config` | object | No | See below | Redis settings |
| `private_endpoint_subnet_id` | string | No | `null` | For private access |
| `private_dns_zone_ids` | map(string) | No | `{}` | DNS zones |
| `key_vault_id` | string | No | `null` | For storing credentials |
| `tags` | map(string) | No | `{}` | Resource tags |

#### PostgreSQL Configuration

```hcl
postgresql_config = {
  # VM size for the database server
  sku_name = "GP_Standard_D2s_v3"  # General Purpose, 2 vCPUs, 8GB RAM

  # Storage configuration
  storage_mb = 32768  # 32 GB (can be increased, never decreased)

  # PostgreSQL version
  version = "15"  # Latest stable

  # Backup configuration
  backup_retention_days = 7   # Days to keep backups (7-35)
  geo_redundant_backup  = false  # Replicate backups to another region

  # High availability mode
  # "Disabled" = Single server
  # "ZoneRedundant" = Replica in another availability zone
  # "SameZone" = Replica in same zone (faster failover)
  high_availability_mode = "ZoneRedundant"

  # Databases to create
  databases = ["app_db", "analytics_db"]
}
```

> 💡 **PostgreSQL SKU Naming**
>
> SKU format: `{Tier}_{VM}_{Version}`
>
> | Tier | Description | Use Case | Example |
> |------|-------------|----------|---------|
> | B | Burstable | Dev/test | B_Standard_B1ms |
> | GP | General Purpose | Production | GP_Standard_D2s_v3 |
> | MO | Memory Optimized | Heavy workloads | MO_Standard_E4s_v3 |

#### Redis Configuration

```hcl
redis_config = {
  # Cache capacity (0-6 for Basic/Standard, 1-5 for Premium)
  capacity = 1

  # SKU family: C (Basic/Standard) or P (Premium)
  family = "P"

  # SKU name: Basic, Standard, Premium
  sku_name = "Premium"

  # Number of shards (Premium only)
  shard_count = 1

  # Cluster mode (Premium only)
  enable_cluster = false
}
```

> 💡 **When to Use Redis**
>
> Redis is an **optional** component. Enable it when you need:
> - **Session storage** across multiple app instances
> - **High-speed caching** for frequently accessed data
> - **Real-time features** like leaderboards or pub/sub
> - **Rate limiting** for APIs

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `postgresql_server_id` | PostgreSQL resource ID | Monitoring |
| `postgresql_server_name` | Server name | Connection strings |
| `postgresql_fqdn` | Full DNS name for connection | Applications |
| `redis_id` | Redis resource ID | Monitoring |
| `redis_hostname` | Redis hostname | Applications |

#### Usage Example

```hcl
module "databases" {
  source = "./modules/databases"

  customer_name       = var.customer_name
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Enable PostgreSQL
  enable_postgresql = true
  postgresql_config = {
    sku_name               = "GP_Standard_D2s_v3"
    storage_mb             = 32768
    version                = "15"
    backup_retention_days  = 7
    geo_redundant_backup   = false
    high_availability_mode = "ZoneRedundant"
    databases              = ["app_db"]
  }

  # Enable Redis (optional)
  enable_redis = true
  redis_config = {
    capacity      = 1
    family        = "P"
    sku_name      = "Premium"
    shard_count   = 1
    enable_cluster = false
  }

  # Private networking
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  private_dns_zone_ids = {
    postgresql = module.networking.private_dns_zone_ids["postgresql"]
    redis      = module.networking.private_dns_zone_ids["redis"]
  }

  # Store credentials in Key Vault
  key_vault_id = module.security.key_vault_id

  tags = var.tags
}
```

#### Database Connection Security

![Database Connection Flow](../assets/mod-database-connection-flow.svg)

---

### 3.7 Defender Module

**Path:** `terraform/modules/defender`

> 💡 **Why This Module Exists**
>
> Microsoft Defender for Cloud provides **threat detection** and **security posture management**.
> This module enables Defender plans for your resources, giving you:
> - Vulnerability scanning for containers
> - Threat detection for databases
> - Security recommendations
> - Compliance reporting

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `subscription_id` | string | **Yes** | - | Azure subscription ID |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `location` | string | **Yes** | - | Azure region |
| `enable_container_plan` | bool | No | `true` | Defender for Containers |
| `enable_keyvault_plan` | bool | No | `true` | Defender for Key Vault |
| `enable_storage_plan` | bool | No | `true` | Defender for Storage |
| `enable_database_plan` | bool | No | `true` | Defender for Databases |
| `security_contact_email` | string | **Yes** | - | Email for alerts |
| `alert_notifications` | bool | No | `true` | Send email alerts |
| `tags` | map(string) | No | `{}` | Resource tags |

#### Defender Plans Explained

| Plan | What It Protects | Key Features | Cost Impact |
|------|------------------|--------------|-------------|
| **Containers** | AKS, ACR | Image vulnerability scanning, runtime threat detection | ~$7/vCPU/month |
| **Key Vault** | Secrets | Unusual access detection, threat alerts | ~$0.02/10K operations |
| **Storage** | Blob/Files | Malware scanning, anomaly detection | ~$0.02/10K transactions |
| **Databases** | SQL, PostgreSQL | SQL injection detection, anomaly detection | ~$15/server/month |

> ⚠️ **Cost Consideration**
>
> Defender plans have ongoing costs. For development environments,
> you might want to disable some plans:
>
> ```hcl
> # Development - minimal Defender
> enable_container_plan = true   # Keep for image scanning
> enable_keyvault_plan  = false
> enable_storage_plan   = false
> enable_database_plan  = false
> ```

#### Usage Example

```hcl
module "defender" {
  source = "./modules/defender"

  subscription_id         = data.azurerm_subscription.current.subscription_id
  resource_group_name     = azurerm_resource_group.main.name
  location                = var.location

  # Enable Defender plans
  enable_container_plan = true   # For AKS and ACR
  enable_keyvault_plan  = true   # For Key Vault
  enable_storage_plan   = true   # For Storage Accounts
  enable_database_plan  = true   # For PostgreSQL

  # Security contact
  security_contact_email = "security@contoso.com"
  alert_notifications    = true

  tags = var.tags
}
```

---

### 3.8 Purview Module

**Path:** `terraform/modules/purview`

> 💡 **Why This Module Exists**
>
> Microsoft Purview provides **data governance** capabilities:
> - Data discovery and cataloging
> - Data classification (PII, financial, etc.)
> - Data lineage tracking
>
> This module also creates **LATAM-specific classifications** for regional compliance
> (CPF, CNPJ, RUT, etc.).

#### LATAM Data Classifications

When `enable_latam_classifications = true`, the module creates these custom classifications:

| Classification | Country | Format | Example |
|----------------|---------|--------|---------|
| CPF | Brazil | XXX.XXX.XXX-XX | 123.456.789-00 |
| CNPJ | Brazil | XX.XXX.XXX/XXXX-XX | 12.345.678/0001-00 |
| RUT | Chile | XX.XXX.XXX-X | 12.345.678-9 |
| RFC | Mexico | XXXX-XXXXXX-XXX | GODE561231GR8 |
| DNI | Argentina | XX.XXX.XXX | 12.345.678 |

#### Usage Example

```hcl
module "purview" {
  source = "./modules/purview"

  name                         = "pv-${var.customer_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location

  # Managed resources
  managed_resource_group_name = "rg-purview-managed"

  # Network security
  public_network_enabled       = false
  private_endpoint_subnet_id   = module.networking.private_endpoints_subnet_id

  # LATAM classifications
  enable_latam_classifications = true

  tags = var.tags
}
```

---

## 4. H2 Enhancement Modules

These modules add operational capabilities on top of the H1 foundation.

---

### 4.1 ArgoCD Module

**Path:** `terraform/modules/argocd`

> 💡 **Why This Module Exists**
>
> ArgoCD enables **GitOps** - a practice where Git is the single source of truth
> for your infrastructure and applications. With ArgoCD:
> - Changes in Git automatically deploy to Kubernetes
> - You can see what's deployed vs what's in Git
> - Rollbacks are just `git revert`
>
> Think of ArgoCD as a **continuous deployment robot** that watches your Git repos
> and keeps your cluster in sync.

#### How GitOps Works

![GitOps with ArgoCD](../assets/arch-gitops-workflow.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `namespace` | string | No | `"argocd"` | Kubernetes namespace |
| `version` | string | No | `"2.9.0"` | ArgoCD version |
| `admin_password` | string | No | `null` | Admin password (auto-generated if null) |
| `github_org` | string | **Yes** | - | GitHub organization |
| `github_client_id` | string | No | `null` | For GitHub SSO |
| `github_client_secret` | string | No | `null` | For GitHub SSO |
| `enable_notifications` | bool | No | `true` | Enable notifications |
| `notification_webhooks` | map(string) | No | `{}` | Slack/Teams webhooks |

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `argocd_server_url` | ArgoCD web UI URL | Developers |
| `admin_password` | Admin password | Initial setup |
| `namespace` | ArgoCD namespace | Resource references |

#### Usage Example

```hcl
module "argocd" {
  source = "./modules/argocd"

  namespace = "argocd"
  version   = "2.9.0"

  # GitHub integration
  github_org           = "my-org"
  github_client_id     = var.github_oauth_client_id      # From GitHub OAuth App
  github_client_secret = var.github_oauth_client_secret

  # Notifications
  enable_notifications = true
  notification_webhooks = {
    slack = "https://hooks.slack.com/services/XXX/YYY/ZZZ"
  }
}
```

#### Accessing ArgoCD UI

After deployment:

```bash
# Get ArgoCD server URL
kubectl get svc argocd-server -n argocd

# Port forward to access locally
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open in browser
# https://localhost:8080

# Login with admin and the generated password
# (Get password from Terraform output or Key Vault)
```

---

### 4.2 External Secrets Module

**Path:** `terraform/modules/external-secrets`

> 💡 **Why This Module Exists**
>
> Kubernetes Secrets store sensitive data, but managing them is hard:
> - Where do the secrets come from?
> - How do you rotate them?
> - How do you sync across environments?
>
> External Secrets Operator (ESO) solves this by **syncing secrets from Azure Key Vault
> to Kubernetes automatically**.

#### How External Secrets Work

![External Secrets Flow](../assets/mod-external-secrets-flow.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `namespace` | string | No | `"external-secrets"` | Operator namespace |
| `version` | string | No | `"0.9.0"` | Helm chart version |
| `key_vault_name` | string | **Yes** | - | Azure Key Vault name |
| `key_vault_url` | string | **Yes** | - | Key Vault URL |
| `tenant_id` | string | **Yes** | - | Azure AD tenant ID |
| `workload_identity_client_id` | string | **Yes** | - | Identity for access |

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `namespace` | ESO namespace | Configuration |
| `cluster_secret_store_name` | ClusterSecretStore name | ExternalSecret resources |

#### Usage Example

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  namespace = "external-secrets"
  version   = "0.9.0"

  # Key Vault connection
  key_vault_name = module.security.key_vault_name
  key_vault_url  = module.security.key_vault_uri
  tenant_id      = data.azurerm_client_config.current.tenant_id

  # Workload identity for Key Vault access
  workload_identity_client_id = module.security.workload_identity_client_id
}
```

#### Creating ExternalSecrets

After the module is deployed, create `ExternalSecret` resources:

```yaml
# external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: production
spec:
  refreshInterval: 1h           # Sync every hour
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-keyvault        # From module output
  target:
    name: db-credentials        # K8s Secret name
    creationPolicy: Owner
  data:
    - secretKey: username       # Key in K8s Secret
      remoteRef:
        key: db-username        # Key in Key Vault
    - secretKey: password
      remoteRef:
        key: db-password
```

---

### 4.3 Observability Module

**Path:** `terraform/modules/observability`

> 💡 **Why This Module Exists**
>
> You can't fix what you can't see. This module creates a complete observability stack:
> - **Azure Monitor**: Cloud-native metrics and logs
> - **Prometheus**: Kubernetes metrics collection
> - **Grafana**: Visualization dashboards
>
> Think of observability as the **nervous system** of your platform - it tells you
> what's healthy and what needs attention.

#### Observability Architecture

![Observability Stack](../assets/arch-observability-stack.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | **Yes** | - | Customer identifier |
| `environment` | string | **Yes** | - | Environment |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `location` | string | **Yes** | - | Azure region |
| `aks_cluster_id` | string | **Yes** | - | AKS cluster ID |
| `enable_azure_monitor` | bool | No | `true` | Enable Azure Monitor |
| `enable_prometheus` | bool | No | `true` | Enable Prometheus |
| `enable_grafana` | bool | No | `true` | Enable Grafana |
| `log_retention_days` | number | No | `30` | Log retention period |
| `tags` | map(string) | No | `{}` | Resource tags |

#### Log Retention Considerations

> 💡 **Log Retention vs Cost**
>
> | Retention | Cost Impact | Use Case |
> |-----------|-------------|----------|
> | 30 days | Low | Development, troubleshooting |
> | 90 days | Medium | Production standard |
> | 180 days | High | Compliance requirements |
> | 365 days | Very High | Regulatory/audit requirements |
>
> **Recommendation:** Start with 30 days, increase if compliance requires it.

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `log_analytics_workspace_id` | Log Analytics ID | AKS Container Insights |
| `prometheus_endpoint` | Prometheus URL | Grafana data source |
| `grafana_endpoint` | Grafana web UI URL | Developers, SRE |

#### Usage Example

```hcl
module "observability" {
  source = "./modules/observability"

  customer_name       = var.customer_name
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # AKS integration
  aks_cluster_id = module.aks.cluster_id

  # Enable all observability components
  enable_azure_monitor = true
  enable_prometheus    = true
  enable_grafana       = true

  # Log retention (30 days default)
  log_retention_days = 30

  tags = var.tags
}
```

#### Pre-configured Grafana Dashboards

The module includes these dashboards:

| Dashboard | What It Shows |
|-----------|---------------|
| Kubernetes Cluster | Overall cluster health, node status, resource usage |
| Kubernetes Pods | Pod CPU/memory, restarts, status |
| Kubernetes Namespaces | Per-namespace resource consumption |
| Node Exporter | Detailed node metrics (disk, network) |
| PostgreSQL | Database connections, query performance |
| ArgoCD | Application sync status, deployment frequency |

---

### 4.4 GitHub Runners Module

**Path:** `terraform/modules/github-runners`

> 💡 **Why This Module Exists**
>
> GitHub Actions workflows run on GitHub-hosted runners by default, but:
> - They can't access your private network (VNet)
> - They have limited resources
> - You pay per-minute for heavy usage
>
> Self-hosted runners on AKS solve these problems by running your CI/CD
> **inside your cluster**.

#### Runner Architecture

![Runner Architecture](../assets/mod-github-runners.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `namespace` | string | No | `"github-runners"` | Kubernetes namespace |
| `github_org` | string | **Yes** | - | GitHub organization |
| `github_app_id` | string | **Yes** | - | GitHub App ID |
| `github_app_installation_id` | string | **Yes** | - | App installation ID |
| `github_app_private_key` | string | **Yes** | - | App private key (PEM) |
| `runner_scale_set_name` | string | No | `"arc-runners"` | Scale set name |
| `min_runners` | number | No | `1` | Minimum runners |
| `max_runners` | number | No | `10` | Maximum runners |
| `runner_image` | string | No | See below | Runner container image |

#### Setting Up GitHub App

> 💡 **Creating a GitHub App for Runners**
>
> 1. Go to GitHub Organization → Settings → Developer settings → GitHub Apps
> 2. Create new GitHub App with these permissions:
>    - Repository: Actions (Read-only)
>    - Organization: Self-hosted runners (Read and write)
> 3. Install the app in your organization
> 4. Note the App ID and Installation ID
> 5. Generate and download the private key

#### Usage Example

```hcl
module "github_runners" {
  source = "./modules/github-runners"

  namespace = "github-runners"

  # GitHub App authentication
  github_org                 = "my-org"
  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_private_key     = var.github_app_private_key  # Store in Key Vault!

  # Scaling configuration
  runner_scale_set_name = "arc-runners"
  min_runners           = 1    # Always have 1 ready
  max_runners           = 10   # Scale up to 10 for busy periods

  # Custom runner image (optional)
  runner_image = "ghcr.io/actions/runner:latest"
}
```

#### Using Self-Hosted Runners in Workflows

```yaml
# .github/workflows/deploy.yaml
name: Deploy Application

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: arc-runners  # Your self-hosted runner scale set name!
    steps:
      - uses: actions/checkout@v4

      # Can access private resources!
      - name: Connect to database
        run: |
          psql "postgres://user@psql-xxx.postgres.database.azure.com/db"

      - name: Push to ACR
        run: |
          az acr login --name myacr
          docker push myacr.azurecr.io/myapp:${{ github.sha }}
```

---

### 4.5 Backstage (Backstage) Module

**Path:** `terraform/modules/backstage`

> 💡 **Why This Module Exists**
>
> Backstage (based on Backstage) is your **Internal Developer Portal**.
> It provides:
> - A single place for developers to discover services, APIs, and documentation
> - Golden Path templates for scaffolding new projects
> - TechDocs for automatic documentation publishing
> - Kubernetes plugin to view workloads
> - ArgoCD integration for deployment status
>
> Think of Backstage as the **developer's front door** to the entire platform.

#### What Gets Created

![Backstage Architecture](../assets/mod-backstage-architecture.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | **Yes** | - | Customer name for resource naming |
| `environment` | string | **Yes** | - | Environment (dev, staging, prod) |
| `location` | string | **Yes** | - | Azure region |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `namespace` | string | No | `"backstage"` | Kubernetes namespace |
| `backstage_version` | string | No | `"1.2.0"` | Backstage Helm chart version |
| `base_url` | string | **Yes** | - | Base URL (e.g., `https://developer.example.com`) |
| `postgresql_host` | string | **Yes** | - | PostgreSQL server hostname |
| `postgresql_database` | string | No | `"backstage"` | Database name |
| `postgresql_username` | string | No | `"backstage"` | Database username |
| `postgresql_password` | string | **Yes** | - | Database password (sensitive) |
| `github_org` | string | **Yes** | - | GitHub organization name |
| `github_app_id` | string | **Yes** | - | GitHub App ID |
| `github_app_client_id` | string | **Yes** | - | GitHub App client ID |
| `github_app_client_secret` | string | **Yes** | - | GitHub App client secret (sensitive) |
| `github_app_private_key` | string | **Yes** | - | GitHub App private key PEM (sensitive) |
| `github_app_webhook_secret` | string | **Yes** | - | GitHub App webhook secret (sensitive) |
| `argocd_url` | string | **Yes** | - | ArgoCD server URL |
| `argocd_auth_token` | string | **Yes** | - | ArgoCD auth token (sensitive) |
| `azure_tenant_id` | string | **Yes** | - | Azure AD tenant ID |
| `azure_client_id` | string | **Yes** | - | Azure AD app client ID |
| `azure_client_secret` | string | **Yes** | - | Azure AD app client secret (sensitive) |
| `key_vault_name` | string | **Yes** | - | Key Vault for secrets |
| `aks_oidc_issuer_url` | string | **Yes** | - | AKS OIDC issuer URL |
| `subnet_id` | string | **Yes** | - | Subnet for private endpoints |
| `replicas` | number | No | `2` | Number of Backstage replicas |
| `enable_techdocs` | bool | No | `true` | Enable TechDocs with Azure Blob Storage |
| `enable_search` | bool | No | `true` | Enable search functionality |
| `enable_kubernetes_plugin` | bool | No | `true` | Enable Kubernetes plugin |
| `tags` | map(string) | No | `{}` | Resource tags |

#### Outputs

| Output | Description |
|--------|-------------|
| `namespace` | Backstage Kubernetes namespace |
| `url` | Backstage URL |
| `service_account` | Backstage service account name |
| `managed_identity_client_id` | Backstage managed identity client ID |
| `storage_account_name` | TechDocs storage account name |
| `storage_container_name` | TechDocs storage container name |

#### Usage Example

```hcl
module "backstage" {
  source = "./modules/backstage"

  customer_name       = var.customer_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.naming.resource_group_name

  base_url           = "https://developer.${var.customer_name}.com"
  namespace          = "backstage"

  # Database
  postgresql_host     = module.databases.postgresql_fqdn
  postgresql_password = var.backstage_db_password

  # GitHub App
  github_org                = var.github_org
  github_app_id             = var.github_app_id
  github_app_client_id      = var.github_app_client_id
  github_app_client_secret  = var.github_app_client_secret
  github_app_private_key    = var.github_app_private_key
  github_app_webhook_secret = var.github_app_webhook_secret

  # ArgoCD
  argocd_url        = "https://argocd.${var.customer_name}.com"
  argocd_auth_token = var.argocd_auth_token

  # Azure AD
  azure_tenant_id     = data.azurerm_client_config.current.tenant_id
  azure_client_id     = var.backstage_azure_client_id
  azure_client_secret = var.backstage_azure_client_secret

  # Infrastructure
  key_vault_name      = module.security.key_vault_name
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  subnet_id           = module.networking.subnet_ids["aks"]

  # Features
  enable_techdocs          = true
  enable_kubernetes_plugin = true

  tags = local.common_tags
}
```

#### Key Features

- **Helm-based deployment** using official Backstage chart
- **Workload Identity** for secure Azure authentication
- **TechDocs** with Azure Blob Storage backend
- **PostgreSQL** external database (from databases module)
- **GitHub App** integration for SCM and scaffolding
- **ArgoCD** integration for deployment status
- **Kubernetes plugin** for workload visibility
- **Pod Disruption Budget** for high availability
- **RBAC ClusterRole** for Kubernetes read access

---

## 5. H3 Innovation Modules

These modules add advanced AI/ML capabilities.

---

### 5.1 AI Foundry Module

**Path:** `terraform/modules/ai-foundry`

> 💡 **Why This Module Exists**
>
> Azure OpenAI provides access to powerful AI models (GPT-4, embeddings, etc.).
> This module creates:
> - Cognitive Services account for Azure OpenAI
> - Model deployments (GPT-4o, embeddings, etc.)
> - Private endpoint for secure access
> - API key stored in Key Vault

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `name` | string | **Yes** | - | Cognitive Services name |
| `resource_group_name` | string | **Yes** | - | Resource group name |
| `location` | string | **Yes** | - | Region (use eastus2 for all models) |
| `sku` | string | No | `"S0"` | Pricing SKU |
| `public_network_access_enabled` | bool | No | `false` | Public access |
| `private_endpoint_subnet_id` | string | No | `null` | Private endpoint subnet |
| `private_dns_zone_id` | string | No | `null` | Private DNS zone |
| `model_deployments` | list(object) | No | `[]` | Model deployments |
| `key_vault_id` | string | No | `null` | For storing API key |
| `tags` | map(string) | No | `{}` | Resource tags |

#### Region Availability

> ⚠️ **Important: Azure OpenAI Regional Availability**
>
> Not all models are available in all regions!
>
> | Model | Brazil South | East US 2 | West Europe |
> |-------|--------------|-----------|-------------|
> | GPT-4o | ❌ | ✅ | ✅ |
> | GPT-4o-mini | ❌ | ✅ | ✅ |
> | GPT-4 Turbo | ❌ | ✅ | ✅ |
> | GPT-3.5 Turbo | ✅ | ✅ | ✅ |
> | text-embedding-3-large | ❌ | ✅ | ✅ |
>
> **Recommendation:** Deploy AI Foundry in **East US 2** for best model availability.

#### Model Deployments Configuration

```hcl
model_deployments = [
  {
    name          = "gpt-4o"               # Deployment name
    model_name    = "gpt-4o"               # Azure model name
    model_version = "2024-05-13"           # Model version
    capacity      = 10                      # TPM (tokens per minute) in thousands
  },
  {
    name          = "gpt-4o-mini"
    model_name    = "gpt-4o-mini"
    model_version = "2024-07-18"
    capacity      = 20
  },
  {
    name          = "text-embedding-3-large"
    model_name    = "text-embedding-3-large"
    model_version = "1"
    capacity      = 50
  }
]
```

> 💡 **Understanding TPM (Tokens Per Minute)**
>
> - `capacity = 10` means 10,000 tokens per minute
> - GPT-4o: ~750 words ≈ 1,000 tokens
> - Start low and increase as needed (you can change this without redeploying)
>
> | Use Case | Recommended TPM |
> |----------|-----------------|
> | Development | 10 (10K TPM) |
> | Small production | 30 (30K TPM) |
> | Large production | 100+ (100K+ TPM) |

#### Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `cognitive_account_id` | Account resource ID | Monitoring |
| `endpoint` | API endpoint URL | Applications |
| `primary_key` | API key (sensitive) | Applications |
| `deployment_ids` | Map of deployment IDs | Reference |

#### Usage Example

```hcl
module "ai_foundry" {
  source = "./modules/ai-foundry"

  name                = "oai-${var.customer_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"  # Use eastus2 for best model availability!
  sku                 = "S0"

  # Security: private access only
  public_network_access_enabled = false
  private_endpoint_subnet_id    = module.networking.private_endpoints_subnet_id
  private_dns_zone_id           = module.networking.private_dns_zone_ids["openai"]

  # Model deployments
  model_deployments = [
    {
      name          = "gpt-4o"
      model_name    = "gpt-4o"
      model_version = "2024-05-13"
      capacity      = 10
    },
    {
      name          = "text-embedding-3-large"
      model_name    = "text-embedding-3-large"
      model_version = "1"
      capacity      = 50
    }
  ]

  # Store API key in Key Vault
  key_vault_id = module.security.key_vault_id

  tags = var.tags
}
```

#### Using Azure OpenAI from Applications

```python
# Python example using Azure OpenAI SDK
from openai import AzureOpenAI

client = AzureOpenAI(
    api_key=os.environ["AZURE_OPENAI_API_KEY"],  # From Key Vault
    api_version="2024-02-01",
    azure_endpoint="https://oai-contoso-dev.openai.azure.com"  # From module output
)

response = client.chat.completions.create(
    model="gpt-4o",  # Deployment name
    messages=[
        {"role": "user", "content": "Hello, how are you?"}
    ]
)
```

---

## 6. Cross-Cutting Modules

These modules provide platform-wide functionality.

---

### 6.1 Cost Management Module

**Path:** `terraform/modules/cost-management`

> 💡 **Why This Module Exists**
>
> Cloud costs can spiral out of control quickly. This module:
> - Creates **budgets** with spending limits
> - Sends **alerts** when spending exceeds thresholds
> - Helps prevent surprise bills

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `resource_group_name` | string | **Yes** | - | Resource group |
| `subscription_id` | string | **Yes** | - | Subscription ID |
| `budget_amount` | number | **Yes** | - | Monthly budget (USD) |
| `alert_thresholds` | list(number) | No | `[50, 75, 90, 100]` | Alert percentages |
| `alert_emails` | list(string) | **Yes** | - | Email recipients |
| `tags` | map(string) | No | `{}` | Resource tags |

#### How Alerts Work

![Budget Alert Timeline](../assets/mod-budget-alerts.svg)

#### Usage Example

```hcl
module "cost_management" {
  source = "./modules/cost-management"

  resource_group_name = azurerm_resource_group.main.name
  subscription_id     = data.azurerm_subscription.current.subscription_id

  # Monthly budget
  budget_amount = 10000  # $10,000 USD

  # Alert at these percentages
  alert_thresholds = [50, 75, 90, 100]

  # Who receives alerts
  alert_emails = [
    "finance@contoso.com",
    "platform-team@contoso.com"
  ]

  tags = var.tags
}
```

#### Budget Guidelines by Environment

> 💡 **Recommended Budgets**
>
> | Environment | Typical Budget | Alert Action |
> |-------------|----------------|--------------|
> | Dev | $500-2,000 | Informational |
> | Staging | $2,000-5,000 | Review usage |
> | Production | $10,000+ | Investigate |

---

### 6.2 Disaster Recovery Module

**Path:** `terraform/modules/disaster-recovery`

> 💡 **Why This Module Exists**
>
> Disasters happen: region outages, data corruption, accidental deletions.
> This module configures:
> - **AKS DR cluster** in a secondary region
> - **Database replication** for data redundancy
> - **Storage geo-replication** for object data

#### DR Architecture

![Disaster Recovery Setup](../assets/mod-disaster-recovery.svg)

#### Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `customer_name` | string | **Yes** | - | Customer identifier |
| `environment` | string | **Yes** | - | Environment |
| `primary_location` | string | **Yes** | - | Primary region |
| `secondary_location` | string | **Yes** | - | DR region |
| `resource_group_name` | string | **Yes** | - | Resource group |
| `enable_aks_dr` | bool | No | `false` | Create DR AKS cluster |
| `enable_database_replication` | bool | No | `true` | Enable DB replication |
| `enable_storage_replication` | bool | No | `true` | Enable storage GRS |
| `tags` | map(string) | No | `{}` | Resource tags |

#### Usage Example

```hcl
module "disaster_recovery" {
  source = "./modules/disaster-recovery"

  customer_name       = var.customer_name
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name

  # Region pairing
  primary_location   = "brazilsouth"
  secondary_location = "eastus2"

  # DR components
  enable_aks_dr              = true   # Create standby AKS cluster
  enable_database_replication = true   # PostgreSQL read replica
  enable_storage_replication = true   # GRS storage

  tags = var.tags
}
```

#### DR Testing

> 💡 **DR Testing Recommendations**
>
> | Test Type | Frequency | What to Test |
> |-----------|-----------|--------------|
> | Backup verification | Weekly | Verify backups are created |
> | Restore test | Monthly | Restore to test namespace |
> | Failover drill | Quarterly | Full failover to DR region |
> | Documentation review | Quarterly | Update runbooks |

---

## 7. Module Dependencies and Execution Order

### 7.1 Dependency Graph

Understanding module dependencies is crucial for correct deployment:

![Module Dependency Graph](../assets/mod-dependency-graph.svg)

### 7.2 Recommended Deployment Order

```hcl
# PHASE 1: Foundation (no dependencies)
module "naming" { ... }

# PHASE 2: Infrastructure (depends on naming)
module "networking" {
  depends_on = [module.naming]
}

module "security" {
  depends_on = [module.networking]  # For private endpoints
}

module "acr" {
  depends_on = [module.networking]  # For private endpoint
}

# PHASE 3: Compute (depends on infrastructure)
module "aks" {
  depends_on = [module.networking, module.security, module.acr]
}

module "databases" {
  depends_on = [module.networking, module.security]  # For private endpoints and secrets
}

# PHASE 4: Platform Services (depends on compute)
module "argocd" {
  depends_on = [module.aks]
}

module "external_secrets" {
  depends_on = [module.aks, module.security]
}

module "observability" {
  depends_on = [module.aks]
}

module "github_runners" {
  depends_on = [module.aks]
}

# PHASE 5: Optional/Innovation
module "ai_foundry" {
  depends_on = [module.networking]  # Only needs network for private endpoint
}

module "cost_management" { ... }  # No dependencies
module "defender" { ... }         # No dependencies
```

### 7.3 Why Order Matters

> ⚠️ **Deployment Order Violations**
>
> | Wrong Order | Error You'll See |
> |-------------|------------------|
> | AKS before networking | "Subnet not found" |
> | External Secrets before security | "Key Vault not found" |
> | Private endpoint before VNet | "Private endpoint subnet not found" |
> | ArgoCD before AKS | "No Kubernetes cluster available" |

---

## 8. Common Usage Patterns

### 8.1 Minimal Development Environment

For quick development setups:

```hcl
# Just the essentials for development
module "naming" {
  source        = "./modules/naming"
  customer_name = "dev"
  environment   = "dev"
  region        = "brazilsouth"
}

module "networking" {
  source              = "./modules/networking"
  customer_name       = "dev"
  environment         = "dev"
  location            = "brazilsouth"
  resource_group_name = azurerm_resource_group.main.name
  vnet_cidr           = "10.0.0.0/16"
  dns_zone_name       = "dev.internal"
  enable_bastion      = false  # Not needed for dev
}

module "aks" {
  source              = "./modules/aks-cluster"
  resource_group_name = azurerm_resource_group.main.name
  location            = "brazilsouth"
  customer_name       = "dev"
  environment         = "dev"
  kubernetes_version  = "1.29"
  sku_tier            = "Free"  # Free tier for dev!
  vnet_subnet_id      = module.networking.aks_nodes_subnet_id

  system_node_pool = {
    name       = "system"
    vm_size    = "Standard_D2s_v5"  # Smaller VMs
    node_count = 1                   # Single node
    zones      = ["1"]               # Single zone
  }
}

# Total estimated cost: ~$50-100/month
```

### 8.2 Production Environment

Full production setup with all security and resilience features:

```hcl
# See terraform/main.tf for the complete implementation

module "naming"           { ... }
module "networking"       { enable_bastion = true, enable_app_gateway = true }
module "security"         { enable_rbac_authorization = true }
module "aks"              { sku_tier = "Standard", zones = ["1","2","3"] }
module "acr"              { sku = "Premium", zone_redundancy_enabled = true }
module "databases"        { high_availability_mode = "ZoneRedundant" }
module "defender"         { enable_container_plan = true, ... }
module "observability"    { log_retention_days = 90 }
module "argocd"           { enable_notifications = true }
module "external_secrets" { ... }
module "github_runners"   { min_runners = 2 }
module "cost_management"  { budget_amount = 15000 }
module "disaster_recovery" { enable_aks_dr = true }

# Total estimated cost: $3,000-10,000/month depending on workload
```

### 8.3 AI/ML Focused Environment

When AI capabilities are the priority:

```hcl
# Standard H1/H2 modules...

# AI Foundry with multiple models
module "ai_foundry" {
  source   = "./modules/ai-foundry"
  location = "eastus2"  # Best model availability

  model_deployments = [
    {
      name          = "gpt-4o"
      model_name    = "gpt-4o"
      model_version = "2024-05-13"
      capacity      = 30  # Higher capacity
    },
    {
      name          = "gpt-4o-mini"
      model_name    = "gpt-4o-mini"
      model_version = "2024-07-18"
      capacity      = 50
    },
    {
      name          = "text-embedding-3-large"
      model_name    = "text-embedding-3-large"
      model_version = "1"
      capacity      = 100  # High capacity for embeddings
    }
  ]
}

# AKS with GPU nodes for local inference
module "aks" {
  # ... standard config ...

  user_node_pools = [
    {
      name      = "gpu"
      vm_size   = "Standard_NC6s_v3"
      min_count = 0
      max_count = 5
      labels    = { accelerator = "nvidia" }
      taints    = ["gpu=true:NoSchedule"]
    }
  ]
}
```

---

## 9. Troubleshooting Module Issues

### 9.1 Common Errors and Solutions

#### "Resource not found" Errors

```
Error: Resource group "rg-xxx" was not found

CAUSE: Module dependency not satisfied
SOLUTION: Add depends_on to ensure correct order

module "networking" {
  source = "./modules/networking"
  depends_on = [azurerm_resource_group.main]  # Add this
}
```

#### "Name already exists" Errors

```
Error: The storage account name "stcontoso" is already taken

CAUSE: Global resources (storage, ACR) require globally unique names
SOLUTION:
1. Use naming module with unique customer_name
2. Add random suffix: "stcontoso${random_string.suffix.result}"
```

#### "Subnet not found" Errors

```
Error: Subnet with ID ".../subnets/aks-nodes" was not found

CAUSE: AKS module running before networking completes
SOLUTION: Add explicit dependency

module "aks" {
  depends_on = [module.networking]
}
```

#### "Insufficient quota" Errors

```
Error: Operation could not be completed as it results in exceeding quota

CAUSE: Azure subscription limits
SOLUTION:
1. Check current usage: az vm list-usage --location brazilsouth
2. Request quota increase via Azure Portal
3. Or use smaller VM sizes
```

### 9.2 Module Upgrade Process

When upgrading module versions:

```bash
# 1. Review changes in the new version
git log --oneline modules/aks-cluster

# 2. Plan changes (don't apply yet)
terraform plan -target=module.aks

# 3. Review the plan carefully
# Look for: destroy/recreate vs in-place updates

# 4. Apply during maintenance window
terraform apply -target=module.aks

# 5. Verify functionality
kubectl get nodes
kubectl get pods -A
```

### 9.3 State Management Issues

```
Error: Error acquiring the state lock

CAUSE: Previous terraform command didn't complete
SOLUTION:
1. Wait for other operations to complete
2. Or force unlock (CAREFUL!):
   terraform force-unlock <LOCK_ID>
```

```
Error: Resource already exists

CAUSE: Resource created outside Terraform
SOLUTION:
1. Import existing resource:
   terraform import module.aks.azurerm_kubernetes_cluster.main /subscriptions/.../aks
2. Or delete resource and let Terraform create it
```

### 9.4 Getting Help

If you encounter issues not covered here:

1. **Check Azure activity logs**:
   - Azure Portal → Resource Group → Activity Log
   - Look for failed operations with error details

2. **Review Terraform debug logs**:
   ```bash
   TF_LOG=DEBUG terraform apply 2>&1 | tee terraform.log
   ```

3. **Common documentation**:
   - [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
   - [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
   - [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)

---

## Quick Reference Card

### Module Cheat Sheet

| Module | When to Use | Key Inputs |
|--------|-------------|------------|
| naming | Always first | customer_name, environment, region |
| networking | Always | vnet_cidr, dns_zone_name |
| security | Always | key_vault_name, tenant_id |
| aks-cluster | Always | vnet_subnet_id, system_node_pool |
| container-registry | Almost always | name, sku |
| databases | If need SQL | enable_postgresql, postgresql_config |
| argocd | For GitOps | github_org |
| external-secrets | For secrets sync | key_vault_name, workload_identity_client_id |
| observability | Always | aks_cluster_id |
| github-runners | For private CI/CD | github_app_id, github_app_private_key |
| ai-foundry | For AI/ML | model_deployments |
| cost-management | Always | budget_amount, alert_emails |
| disaster-recovery | For production | primary_location, secondary_location |

### Environment Recommendations

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| AKS SKU | Free | Standard | Standard/Premium |
| Node count | 1-2 | 3 | 3+ (autoscale) |
| Zones | 1 | 2 | 3 |
| ACR SKU | Standard | Premium | Premium |
| PostgreSQL HA | Disabled | SameZone | ZoneRedundant |
| DR enabled | No | No | Yes |
| Budget alerts | 50%, 100% | 75%, 100% | 50%, 75%, 90%, 100% |

---

## 🤖 Using Copilot Agents for Module Configuration

| Task | Agent / Prompt | Example |
|------|---------------|---------|
| Module selection guidance | `@terraform` | *"Which modules do I need for a production AKS deployment?"* |
| Input variable configuration | `@terraform` | *"Help me configure the networking module variables for a hub-spoke topology"* |
| Module dependency analysis | `@architect` | *"Show me the dependency graph between aks-cluster and networking modules"* |
| Security review of module config | `@security` | *"Review my terraform.tfvars for security best practices"* |
| Cost estimation | `@architect` | *"Estimate monthly costs for this module configuration"* |

> **Tip:** Use `@terraform` to get help with module configuration and `@architect` to understand module dependencies and architecture decisions.

---

## 📚 Related Documentation

| Document | Description |
|----------|-------------|
| [Architecture Guide](ARCHITECTURE_GUIDE.md) | Platform architecture and design decisions |
| [Deployment Guide](DEPLOYMENT_GUIDE.md) | Step-by-step deployment procedures |
| [Terraform README](../../terraform/README.md) | Terraform workspace and backend configuration |
| [Performance Tuning Guide](PERFORMANCE_TUNING_GUIDE.md) | Performance optimization and sizing |

## ➡️ Next Steps

- **Deploy modules**: Follow the [Deployment Guide](DEPLOYMENT_GUIDE.md) to deploy your configured modules
- **Review architecture**: Understand the platform design in the [Architecture Guide](ARCHITECTURE_GUIDE.md)
- **Create custom modules**: Reference the existing modules as templates for organization-specific infrastructure

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
