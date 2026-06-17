# =============================================================================
# OPEN HORIZONS PLATFORM - AI FOUNDRY TERRAFORM MODULE
# =============================================================================
#
# Deploys Azure AI services for H3 Innovation workloads.
#
# Components:
#   - Azure OpenAI Service
#   - Azure AI Search
#   - Azure AI Content Safety
#   - Model deployments (GPT-4o, embeddings)
#   - Private endpoints
#
# =============================================================================

# NOTE: Terraform block is in versions.tf
# NOTE: Variables are defined in variables.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}-${var.environment}"

  common_tags = merge(var.tags, {
    "open-horizons/customer"    = var.customer_name
    "open-horizons/environment" = var.environment
    "open-horizons/component"   = "ai-foundry"
    "open-horizons/horizon"     = "H3"
  })
}

# =============================================================================
# AZURE OPENAI SERVICE
# =============================================================================

resource "azurerm_cognitive_account" "openai" {
  count = var.openai_config.enabled ? 1 : 0

  name                = "oai-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = var.openai_config.sku_name

  custom_subdomain_name = "oai-${replace(local.name_prefix, "-", "")}"

  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    ip_rules       = []
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }
}

# OpenAI Model Deployments
resource "azurerm_cognitive_deployment" "models" {
  for_each = var.openai_config.enabled ? {
    for model in var.openai_config.models : model.name => model
  } : {}

  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.openai[0].id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  scale {
    type     = "Standard"
    capacity = each.value.capacity
  }

  rai_policy_name = each.value.rai_policy
}

# OpenAI Private Endpoint
resource "azurerm_private_endpoint" "openai" {
  count = var.openai_config.enabled ? 1 : 0

  name                = "pe-oai-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "openai-connection"
    private_connection_resource_id = azurerm_cognitive_account.openai[0].id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "openai-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.openai]
  }

  tags = local.common_tags
}

# =============================================================================
# AZURE AI SEARCH
# =============================================================================

resource "azurerm_search_service" "main" {
  count = var.ai_search_config.enabled ? 1 : 0

  name                = "srch-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.ai_search_config.sku_name

  replica_count   = var.ai_search_config.replica_count
  partition_count = var.ai_search_config.partition_count

  public_network_access_enabled = var.ai_search_config.public_network_access_enabled

  semantic_search_sku = var.ai_search_config.semantic_search_sku

  local_authentication_enabled = true
  authentication_failure_mode  = "http403"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# AI Search Private Endpoint
resource "azurerm_private_endpoint" "search" {
  count = var.ai_search_config.enabled ? 1 : 0

  name                = "pe-srch-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "search-connection"
    private_connection_resource_id = azurerm_search_service.main[0].id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "search-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.search]
  }

  tags = local.common_tags
}

# =============================================================================
# AZURE AI CONTENT SAFETY
# =============================================================================

resource "azurerm_cognitive_account" "content_safety" {
  count = var.content_safety_config.enabled ? 1 : 0

  name                = "cs-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "ContentSafety"
  sku_name            = var.content_safety_config.sku_name

  custom_subdomain_name = "cs-${replace(local.name_prefix, "-", "")}"

  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    ip_rules       = []
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Content Safety Private Endpoint
resource "azurerm_private_endpoint" "content_safety" {
  count = var.content_safety_config.enabled ? 1 : 0

  name                = "pe-cs-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "content-safety-connection"
    private_connection_resource_id = azurerm_cognitive_account.content_safety[0].id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "cs-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.cognitiveservices]
  }

  tags = local.common_tags
}

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

# Grant AI Search access to OpenAI (for integrated vectorization)
resource "azurerm_role_assignment" "search_to_openai" {
  count = var.openai_config.enabled && var.ai_search_config.enabled ? 1 : 0

  scope                = azurerm_cognitive_account.openai[0].id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_search_service.main[0].identity[0].principal_id
}

# =============================================================================
# KEY VAULT SECRETS
# =============================================================================

# Store OpenAI endpoint and key
resource "azurerm_key_vault_secret" "openai_endpoint" {
  count = var.openai_config.enabled ? 1 : 0

  name         = "openai-endpoint"
  value        = azurerm_cognitive_account.openai[0].endpoint
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "openai_key" {
  count = var.openai_config.enabled ? 1 : 0

  name         = "openai-api-key"
  value        = azurerm_cognitive_account.openai[0].primary_access_key
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

# Store AI Search endpoint and key
resource "azurerm_key_vault_secret" "search_endpoint" {
  count = var.ai_search_config.enabled ? 1 : 0

  name         = "search-endpoint"
  value        = "https://${azurerm_search_service.main[0].name}.search.windows.net"
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "search_admin_key" {
  count = var.ai_search_config.enabled ? 1 : 0

  name         = "search-admin-key"
  value        = azurerm_search_service.main[0].primary_key
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

# Store Content Safety endpoint and key
resource "azurerm_key_vault_secret" "content_safety_endpoint" {
  count = var.content_safety_config.enabled ? 1 : 0

  name         = "content-safety-endpoint"
  value        = azurerm_cognitive_account.content_safety[0].endpoint
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "content_safety_key" {
  count = var.content_safety_config.enabled ? 1 : 0

  name         = "content-safety-api-key"
  value        = azurerm_cognitive_account.content_safety[0].primary_access_key
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "openai" {
  count = var.openai_config.enabled && var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "openai-diagnostics"
  target_resource_id         = azurerm_cognitive_account.openai[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_log {
    category = "Trace"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "search" {
  count = var.ai_search_config.enabled && var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "search-diagnostics"
  target_resource_id         = azurerm_search_service.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# NOTE: Outputs are defined in outputs.tf
