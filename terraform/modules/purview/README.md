# Purview Module

Microsoft Purview for enterprise data governance with LATAM-specific classifications.

## Features

- Purview Account with managed resource group
- Data Catalog with automated scanning
- Business Glossary with approval workflows
- Data Quality rules (completeness, uniqueness, validity)
- Data Lineage tracking
- LATAM-specific classifications (CPF, CNPJ, RUT, RFC, NIT)
- Sensitivity labels integration
- Private endpoint connectivity
- Collection hierarchy by horizon and environment

## Sizing Profiles

| Profile | Capacity | Scans | Cost/Month |
|---------|----------|-------|------------|
| small | Free | Weekly | ~$0-100 |
| medium | 1 CU | Daily | ~$500 |
| large | 4 CU | Daily | ~$2,000 |
| xlarge | 16 CU | Continuous | ~$5,000 |

## Usage

```hcl
module "purview" {
  source = "./modules/purview"

  customer_name       = "threehorizons"
  environment         = "prod"
  sizing_profile      = "large"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  subnet_id = module.networking.private_endpoints_subnet_id

  private_dns_zone_ids = {
    purview        = module.networking.private_dns_zone_ids["privatelink.purview.azure.com"]
    purview_studio = module.networking.private_dns_zone_ids["privatelink.purviewstudio.azure.com"]
  }

  admin_group_id = var.platform_admins_group_id

  # LATAM classifications
  enable_latam_classifications = true

  # Collection hierarchy
  collection_hierarchy = [
    {
      name        = "H1-Foundation"
      description = "Foundation horizon data assets"
      parent      = ""
    },
    {
      name        = "H2-Enhancement"
      description = "Enhancement horizon data assets"
      parent      = ""
    },
    {
      name        = "H3-Innovation"
      description = "Innovation horizon data assets"
      parent      = ""
    }
  ]

  # Data sources to scan
  data_sources = [
    {
      name        = "datalake"
      type        = "AzureDataLakeStorage"
      resource_id = module.storage.datalake_id
    },
    {
      name        = "postgresql"
      type        = "AzureSqlDatabase"
      resource_id = module.databases.postgresql_id
    }
  ]

  # Business glossary
  glossary_terms = [
    {
      name       = "Customer ID"
      definition = "Unique identifier for customers in the CRM system"
      status     = "Approved"
      experts    = ["user@example.com"]
      stewards   = ["admin@example.com"]
    }
  ]

  # Data quality rules
  data_quality_rules = [
    {
      name        = "Email Completeness"
      description = "Email field must not be null"
      dimension   = "Completeness"
      threshold   = 99.0
      applies_to  = ["**/customers/**"]
    }
  ]

  log_analytics_workspace_id = module.observability.log_analytics_workspace_id

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
| azapi | ~> 1.9 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| sizing_profile | Sizing profile | `string` | `"medium"` | no |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| subnet_id | Subnet ID for private endpoints | `string` | n/a | yes |
| private_dns_zone_ids | Map of private DNS zone IDs | `map(string)` | n/a | yes |
| admin_group_id | Admin group ID | `string` | n/a | yes |
| enable_latam_classifications | Enable LATAM classifications | `bool` | `true` | no |
| collection_hierarchy | Collection structure | `list(object)` | `[]` | no |
| data_sources | Data sources to register | `list(object)` | `[]` | no |
| glossary_terms | Business glossary terms | `list(object)` | `[]` | no |
| data_quality_rules | Data quality rules | `list(object)` | `[]` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `""` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| purview_id | Purview account ID |
| purview_name | Purview account name |
| purview_endpoint | Purview catalog endpoint |
| purview_identity_principal_id | Purview managed identity |
| scan_rule_set_name | Custom scan rule set name |

## LATAM Classifications

Pre-built classification rules:

| Classification | Country | Pattern |
|----------------|---------|---------|
| BRAZIL_CPF | Brazil | Individual Tax ID (11 digits) |
| BRAZIL_CNPJ | Brazil | Company Tax ID (14 digits) |
| BRAZIL_RG | Brazil | State ID Card |
| CHILE_RUT | Chile | Tax ID |
| MEXICO_RFC | Mexico | Tax ID |
| MEXICO_CURP | Mexico | Personal ID |
| COLOMBIA_NIT | Colombia | Tax ID |
| COLOMBIA_CC | Colombia | National ID |
| ARGENTINA_CUIT | Argentina | Tax ID |
| PERU_RUC | Peru | Tax ID |

## Data Quality Dimensions

Supported quality dimensions:
- **Completeness**: Data is not null
- **Uniqueness**: Data is unique
- **Validity**: Data matches expected format
- **Accuracy**: Data matches source of truth
- **Consistency**: Data is consistent across systems
