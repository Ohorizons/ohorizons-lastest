# =============================================================================
# OPEN HORIZONS PLATFORM - MICROSOFT PURVIEW TERRAFORM MODULE
# =============================================================================
#
# Deploys Microsoft Purview for enterprise data governance.
#
# Components:
#   - Purview Account with managed resource group
#   - Data Catalog with automated scanning
#   - Business Glossary with approval workflows
#   - Data Quality rules (completeness, uniqueness, validity)
#   - Data Lineage tracking
#   - LATAM-specific classifications (CPF, CNPJ, RUT, RFC, NIT)
#   - Sensitivity labels integration
#   - Private endpoint connectivity
#   - Collection hierarchy by horizon and environment
#
# Sizing Profiles:
#   - Small:  Free tier, basic catalog (~$0-100/mo)
#   - Medium: 1 CU, daily scans, LATAM classifications (~$500/mo)
#   - Large:  4 CU, data quality, full lineage (~$2,000/mo)
#   - XLarge: 16 CU, continuous scans, data products (~$5,000/mo)
#
# =============================================================================

# NOTE: Terraform block is in versions.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}-${var.environment}"

  # Purview names must be alphanumeric, 3-63 chars
  purview_name = "pv${replace(var.customer_name, "-", "")}${var.environment}"

  # Capacity units by sizing profile
  capacity_config = {
    small  = 0 # Free tier
    medium = 1
    large  = 4
    xlarge = 16
  }

  # Scan frequency by sizing profile
  scan_frequency = {
    small  = "weekly"
    medium = "daily"
    large  = "daily"
    xlarge = "continuous"
  }

  # LATAM-specific classification rules
  latam_classifications = {
    "BRAZIL_CPF" = {
      name        = "Brazil CPF (Individual Tax ID)"
      description = "Brazilian Cadastro de Pessoas Físicas - 11 digit individual taxpayer ID"
      pattern     = "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}|\\d{11}"
      country     = "Brazil"
    }
    "BRAZIL_CNPJ" = {
      name        = "Brazil CNPJ (Company Tax ID)"
      description = "Brazilian Cadastro Nacional da Pessoa Jurídica - 14 digit company ID"
      pattern     = "\\d{2}\\.\\d{3}\\.\\d{3}/\\d{4}-\\d{2}|\\d{14}"
      country     = "Brazil"
    }
    "BRAZIL_RG" = {
      name        = "Brazil RG (Identity Card)"
      description = "Brazilian Registro Geral - State-issued identity number"
      pattern     = "\\d{1,2}\\.?\\d{3}\\.?\\d{3}-?[0-9Xx]"
      country     = "Brazil"
    }
    "CHILE_RUT" = {
      name        = "Chile RUT (Tax ID)"
      description = "Chilean Rol Único Tributario - Tax identification number"
      pattern     = "\\d{1,2}\\.\\d{3}\\.\\d{3}-[0-9Kk]"
      country     = "Chile"
    }
    "MEXICO_RFC" = {
      name        = "Mexico RFC (Tax ID)"
      description = "Mexican Registro Federal de Contribuyentes - Tax ID"
      pattern     = "[A-Z&Ñ]{3,4}\\d{6}[A-Z0-9]{3}"
      country     = "Mexico"
    }
    "MEXICO_CURP" = {
      name        = "Mexico CURP (Personal ID)"
      description = "Mexican Clave Única de Registro de Población - Personal ID"
      pattern     = "[A-Z]{4}\\d{6}[HM][A-Z]{5}[A-Z0-9]\\d"
      country     = "Mexico"
    }
    "COLOMBIA_NIT" = {
      name        = "Colombia NIT (Tax ID)"
      description = "Colombian Número de Identificación Tributaria"
      pattern     = "\\d{9,10}-\\d"
      country     = "Colombia"
    }
    "COLOMBIA_CC" = {
      name        = "Colombia Cedula (ID Card)"
      description = "Colombian Cédula de Ciudadanía - National ID"
      pattern     = "\\d{6,10}"
      country     = "Colombia"
    }
    "ARGENTINA_CUIT" = {
      name        = "Argentina CUIT (Tax ID)"
      description = "Argentine Clave Única de Identificación Tributaria"
      pattern     = "\\d{2}-\\d{8}-\\d"
      country     = "Argentina"
    }
    "PERU_RUC" = {
      name        = "Peru RUC (Tax ID)"
      description = "Peruvian Registro Único de Contribuyentes"
      pattern     = "\\d{11}"
      country     = "Peru"
    }
  }

  common_tags = merge(var.tags, {
    "open-horizons/customer"    = var.customer_name
    "open-horizons/environment" = var.environment
    "open-horizons/component"   = "purview-governance"
    "open-horizons/sizing"      = var.sizing_profile
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}

# =============================================================================
# PURVIEW ACCOUNT
# =============================================================================

resource "azurerm_purview_account" "main" {
  name                = local.purview_name
  resource_group_name = var.resource_group_name
  location            = var.location

  public_network_enabled = false

  managed_resource_group_name = "rg-${local.purview_name}-managed"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# =============================================================================
# PRIVATE ENDPOINTS
# =============================================================================

# Portal private endpoint
resource "azurerm_private_endpoint" "purview_portal" {
  name                = "pe-${local.purview_name}-portal"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "purview-portal-connection"
    private_connection_resource_id = azurerm_purview_account.main.id
    is_manual_connection           = false
    subresource_names              = ["portal"]
  }

  private_dns_zone_group {
    name                 = "purview-portal-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.purview_studio]
  }

  tags = local.common_tags
}

# Account private endpoint
resource "azurerm_private_endpoint" "purview_account" {
  name                = "pe-${local.purview_name}-account"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "purview-account-connection"
    private_connection_resource_id = azurerm_purview_account.main.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "purview-account-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.purview]
  }

  tags = local.common_tags
}

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

# Purview Data Curator for admin group
resource "azurerm_role_assignment" "purview_curator" {
  scope                = azurerm_purview_account.main.id
  role_definition_name = "Purview Data Curator"
  principal_id         = var.admin_group_id
}

# Purview Data Source Administrator for admin group
resource "azurerm_role_assignment" "purview_ds_admin" {
  scope                = azurerm_purview_account.main.id
  role_definition_name = "Purview Data Source Administrator"
  principal_id         = var.admin_group_id
}

# Storage Blob Data Reader for Purview managed identity (scanning)
resource "azurerm_role_assignment" "purview_storage_reader" {
  for_each = { for ds in var.data_sources : ds.name => ds if ds.type == "AzureDataLakeStorage" || ds.type == "AzureBlobStorage" }

  scope                = each.value.resource_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_purview_account.main.identity[0].principal_id
}

# SQL Server role for Purview (via azapi for databases)
resource "azurerm_role_assignment" "purview_sql_reader" {
  for_each = { for ds in var.data_sources : ds.name => ds if ds.type == "AzureSqlDatabase" }

  scope                = each.value.resource_id
  role_definition_name = "Reader"
  principal_id         = azurerm_purview_account.main.identity[0].principal_id
}

# =============================================================================
# COLLECTIONS (via Azure API)
# =============================================================================

resource "azapi_resource" "collections" {
  for_each = { for coll in var.collection_hierarchy : coll.name => coll }

  type      = "Microsoft.Purview/accounts/collections@2021-12-01"
  name      = replace(lower(each.value.name), "-", "")
  parent_id = each.value.parent == "" ? azurerm_purview_account.main.id : azapi_resource.collections[each.value.parent].id

  body = jsonencode({
    properties = {
      description  = each.value.description
      friendlyName = each.value.name
    }
  })

  depends_on = [azurerm_purview_account.main]
}

# Environment sub-collections
resource "azapi_resource" "environment_collections" {
  for_each = toset(["Development", "Staging", "Production"])

  type      = "Microsoft.Purview/accounts/collections@2021-12-01"
  name      = lower(each.value)
  parent_id = azurerm_purview_account.main.id

  body = jsonencode({
    properties = {
      description  = "${each.value} environment assets"
      friendlyName = each.value
    }
  })

  depends_on = [azurerm_purview_account.main]
}

# =============================================================================
# LATAM CUSTOM CLASSIFICATIONS (via Azure API)
# =============================================================================

resource "azapi_resource" "latam_classifications" {
  for_each = var.enable_latam_classifications ? local.latam_classifications : {}

  type      = "Microsoft.Purview/accounts/classificationRules@2022-02-01-preview"
  name      = each.key
  parent_id = azurerm_purview_account.main.id

  body = jsonencode({
    properties = {
      classificationName     = each.value.name
      description            = each.value.description
      kind                   = "Custom"
      ruleStatus             = "Enabled"
      minimumPercentageMatch = 60
      classificationAction   = "Classify"
      dataPatterns = [
        {
          kind    = "Regex"
          pattern = each.value.pattern
        }
      ]
    }
  })

  depends_on = [azurerm_purview_account.main]
}

# =============================================================================
# DATA SOURCES REGISTRATION (via Azure API)
# =============================================================================

resource "azapi_resource" "data_sources" {
  for_each = { for ds in var.data_sources : ds.name => ds }

  type      = "Microsoft.Purview/accounts/dataSources@2022-02-01-preview"
  name      = each.value.name
  parent_id = azurerm_purview_account.main.id

  body = jsonencode({
    kind = each.value.type
    properties = {
      resourceId = each.value.resource_id
      collection = {
        referenceName = replace(lower(var.collection_hierarchy[0].name), "-", "")
        type          = "CollectionReference"
      }
    }
  })

  depends_on = [azapi_resource.collections]
}

# =============================================================================
# SCAN RULE SETS (via Azure API)
# =============================================================================

resource "azapi_resource" "scan_rule_set" {
  type      = "Microsoft.Purview/accounts/scanRuleSets@2022-02-01-preview"
  name      = "ThreeHorizonsScanRuleSet"
  parent_id = azurerm_purview_account.main.id

  body = jsonencode({
    kind = "AzureStorage"
    properties = {
      description                           = "Open Horizons standard scan rule set with LATAM classifications"
      excludedSystemClassifications         = []
      includedCustomClassificationRuleNames = var.enable_latam_classifications ? keys(local.latam_classifications) : []
      scanningRule = {
        customFileExtensions = []
        fileExtensions = [
          "CSV", "JSON", "PARQUET", "AVRO", "ORC",
          "DOC", "DOCX", "PDF", "XLS", "XLSX",
          "TXT", "XML", "PSV", "TSV"
        ]
      }
    }
  })

  depends_on = [azapi_resource.latam_classifications]
}

# =============================================================================
# GLOSSARY TERMS (via Azure API)
# =============================================================================

resource "azapi_resource" "glossary_terms" {
  for_each = { for term in var.glossary_terms : term.name => term }

  type      = "Microsoft.Purview/accounts/glossaryTerms@2022-02-01-preview"
  name      = replace(lower(each.value.name), " ", "-")
  parent_id = azurerm_purview_account.main.id

  body = jsonencode({
    properties = {
      name            = each.value.name
      longDescription = each.value.definition
      status          = each.value.status
      contacts = {
        expert  = [for expert in each.value.experts : { id = expert }]
        steward = [for steward in each.value.stewards : { id = steward }]
      }
    }
  })

  depends_on = [azurerm_purview_account.main]
}

# =============================================================================
# DATA QUALITY (via Azure API - Preview)
# =============================================================================

resource "azapi_resource" "data_quality_rules" {
  for_each = { for rule in var.data_quality_rules : rule.name => rule }

  type      = "Microsoft.Purview/accounts/dataQualityRules@2023-02-01-preview"
  name      = replace(lower(each.value.name), " ", "-")
  parent_id = azurerm_purview_account.main.id

  body = jsonencode({
    properties = {
      displayName = each.value.name
      description = each.value.description
      dimension   = each.value.dimension
      threshold   = each.value.threshold
      status      = "Enabled"
      scope = {
        assetPatterns = each.value.applies_to
      }
    }
  })

  depends_on = [azurerm_purview_account.main]
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================


resource "azurerm_monitor_diagnostic_setting" "purview" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "purview-diagnostics"
  target_resource_id         = azurerm_purview_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ScanStatusLogEvent"
  }

  enabled_log {
    category = "DataSensitivityLogEvent"
  }

  metric {
    category = "AllMetrics"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================


