# Azure Naming Module

This module generates Azure resource names following **Microsoft Cloud Adoption Framework (CAF)** naming conventions and Azure resource naming rules.

## References

- [CAF Naming Convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Azure Resource Name Rules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules)
- [CAF Abbreviation Examples](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)

## Naming Pattern

```
{resource-type}-{project}-{environment}-{region}-{instance}
```

Example: `aks-threehorizons-prd-brs-001`

## Usage

```hcl
module "naming" {
  source = "./modules/naming"

  project_name = "threehorizons"
  environment  = "prd"
  location     = "brazilsouth"
  instance     = "001"
  org_code     = "ms"  # Optional
}

# Use in resources
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = var.location
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = module.naming.aks_cluster
  resource_group_name = azurerm_resource_group.main.name
  # ...
}

resource "azurerm_container_registry" "main" {
  name                = module.naming.container_registry
  resource_group_name = azurerm_resource_group.main.name
  # ...
}
```

## Azure Naming Rules Quick Reference

| Resource Type | Prefix | Length | Allowed Characters | Scope |
|--------------|--------|--------|-------------------|-------|
| Resource Group | `rg-` | 1-90 | Alphanumeric, `_`, `-`, `.`, `()` | Subscription |
| Virtual Network | `vnet-` | 2-64 | Alphanumeric, `_`, `-`, `.` | Resource Group |
| Subnet | `snet-` | 1-80 | Alphanumeric, `_`, `-`, `.` | Virtual Network |
| NSG | `nsg-` | 1-80 | Alphanumeric, `_`, `-`, `.` | Resource Group |
| AKS Cluster | `aks-` | 1-63 | Alphanumeric, `_`, `-` | Resource Group |
| AKS Node Pool | - | 1-12 | Lowercase alphanumeric | AKS Cluster |
| **Container Registry** | `cr` | 5-50 | **Alphanumeric only** | **Global** |
| **Storage Account** | `st` | 3-24 | **Lowercase + numbers only** | **Global** |
| **Key Vault** | `kv-` | 3-24 | Alphanumeric, `-` | **Global** |
| PostgreSQL Server | `psql-` | 3-63 | Lowercase, numbers, `-` | **Global** |
| SQL Server | `sql-` | 1-63 | Lowercase, numbers, `-` | **Global** |
| Cosmos DB | `cosmos-` | 3-44 | Lowercase, numbers, `-` | **Global** |
| Log Analytics | `log-` | 4-63 | Alphanumeric, `-` | Resource Group |
| App Insights | `appi-` | 1-260 | Alphanumeric, `-`, `.`, `_` | Resource Group |
| Function App | `func-` | 2-60 | Alphanumeric, `-` | **Global** |
| Web App | `app-` | 2-60 | Alphanumeric, `-` | **Global** |
| API Management | `apim-` | 1-50 | Alphanumeric, `-` | **Global** |

## Critical Rules ⚠️

### Resources WITHOUT hyphens allowed:
- **Storage Account**: `st{project}{env}{region}{instance}` - lowercase + numbers only
- **Container Registry**: `cr{project}{env}{region}` - alphanumeric only

### Resources with Global Uniqueness:
- Storage Account
- Container Registry
- Key Vault
- PostgreSQL/MySQL/SQL Server
- Cosmos DB
- Web Apps / Function Apps
- API Management
- Service Bus / Event Hub

### Length-Limited Resources:
| Resource | Max Length | Strategy |
|----------|------------|----------|
| Storage Account | 24 | Use short codes |
| Key Vault | 24 | Truncate if needed |
| AKS Node Pool | 12 | Use abbreviations |
| VM Name (Windows) | 15 | Use short codes |

## Environment Codes

| Environment | Code |
|-------------|------|
| Development | `dev` |
| Staging | `stg` |
| Production | `prd` |
| Sandbox | `sbx` |
| Test | `tst` |

## Region Codes (LATAM Focus)

| Region | Code |
|--------|------|
| Brazil South | `brs` |
| Brazil Southeast | `brse` |
| East US | `eus` |
| East US 2 | `eus2` |
| South Central US | `scus` |
| West Europe | `weu` |

## Outputs Available

```hcl
# General
module.naming.resource_group         # rg-{prefix}
module.naming.management_group       # mg-{prefix}

# Networking
module.naming.virtual_network        # vnet-{prefix}
module.naming.subnet                 # snet-{prefix}
module.naming.subnet_aks             # snet-{prefix}-aks
module.naming.network_security_group # nsg-{prefix}
module.naming.public_ip              # pip-{prefix}
module.naming.private_endpoint       # pe-{prefix}
module.naming.application_gateway    # agw-{prefix}

# Compute
module.naming.aks_cluster            # aks-{prefix}
module.naming.aks_node_pool_system   # system
module.naming.container_registry     # cr{prefix-no-dash}
module.naming.container_app          # ca-{prefix}

# Storage
module.naming.storage_account        # st{prefix-no-dash} (max 24)
module.naming.key_vault              # kv-{prefix} (max 24)

# Database
module.naming.postgresql_server      # psql-{prefix}
module.naming.sql_server             # sql-{prefix}
module.naming.cosmos_account         # cosmos-{prefix}

# Monitoring
module.naming.log_analytics_workspace # log-{prefix}
module.naming.application_insights   # appi-{prefix}

# AI
module.naming.openai_service         # oai-{prefix}
module.naming.ai_hub                 # aih-{prefix}
module.naming.search_service         # srch-{prefix}

# Security
module.naming.managed_identity       # id-{prefix}
module.naming.service_principal      # sp-{prefix}

# Governance
module.naming.purview_account        # pview-{prefix}

# Helpers
module.naming.name_prefix            # {org}-{project}-{env}-{region}
module.naming.name_prefix_no_dash    # {org}{project}{env}{region}
module.naming.short_prefix           # {project}{env}{region}
module.naming.region_code            # brs, eus, etc.
module.naming.tags                   # Standard tags map
```
