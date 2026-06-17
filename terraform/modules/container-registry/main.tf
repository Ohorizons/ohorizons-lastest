# =============================================================================
# OPEN HORIZONS PLATFORM - CONTAINER REGISTRY TERRAFORM MODULE
# =============================================================================
#
# Deploys Azure Container Registry with enterprise features.
#
# Components:
#   - Azure Container Registry (Premium for geo-replication)
#   - Private endpoint connectivity
#   - Retention policies
#   - Security scanning integration
#   - Workload identity access
#
# =============================================================================

# NOTE: Terraform block is in versions.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}${var.environment}"

  # ACR names must be alphanumeric only
  acr_name = replace("cr${local.name_prefix}", "-", "")

  common_tags = merge(var.tags, {
    "open-horizons/customer"    = var.customer_name
    "open-horizons/environment" = var.environment
    "open-horizons/component"   = "container-registry"
  })
}

# =============================================================================
# AZURE CONTAINER REGISTRY
# =============================================================================

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false

  # Network rules (Premium only)
  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" ? [1] : []
    content {
      default_action = "Deny"

      # Allow Azure services
      ip_rule = []

      virtual_network {
        action    = "Allow"
        subnet_id = var.subnet_id
      }
    }
  }

  # Content trust (Premium only)
  trust_policy {
    enabled = var.sku == "Premium" ? var.enable_content_trust : false
  }

  # Retention policy (Premium only)
  retention_policy {
    enabled = var.sku == "Premium"
    days    = var.retention_policy_days
  }

  # Quarantine policy for security scanning
  quarantine_policy_enabled = var.sku == "Premium"

  # Export policy
  export_policy_enabled = true

  # Zone redundancy (Premium in supported regions)
  zone_redundancy_enabled = var.sku == "Premium" && var.environment == "prod"

  # Data endpoint (Premium only)
  data_endpoint_enabled = var.sku == "Premium"

  # Public network access
  public_network_access_enabled = false

  # Encryption
  encryption {
    enabled = false # Use platform-managed keys by default
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# =============================================================================
# GEO-REPLICATION (Premium only)
# =============================================================================

resource "azurerm_container_registry_replication" "replicas" {
  for_each = var.sku == "Premium" ? toset(var.geo_replication_locations) : []

  name                  = each.key
  container_registry_id = azurerm_container_registry.main.id
  location              = each.key

  zone_redundancy_enabled = var.environment == "prod"

  tags = local.common_tags
}

# =============================================================================
# PRIVATE ENDPOINT
# =============================================================================

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${local.acr_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "acr-connection"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = local.common_tags
}

# =============================================================================
# ROLE ASSIGNMENTS
# =============================================================================

# AKS Kubelet identity - AcrPull
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_identity_object_id
}

# GitHub Actions identities - AcrPush
resource "azurerm_role_assignment" "github_actions_push" {
  for_each = toset(var.github_actions_identity_ids)

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
}

# =============================================================================
# SCOPE MAPS AND TOKENS (for fine-grained access)
# =============================================================================

resource "azurerm_container_registry_scope_map" "ci_push" {
  name                    = "ci-push-scope"
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/*/content/read",
    "repositories/*/content/write",
    "repositories/*/metadata/read",
    "repositories/*/metadata/write"
  ]
}

resource "azurerm_container_registry_scope_map" "readonly" {
  name                    = "readonly-scope"
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = var.resource_group_name

  actions = [
    "repositories/*/content/read",
    "repositories/*/metadata/read"
  ]
}

# =============================================================================
# WEBHOOKS (for CI/CD integration)
# =============================================================================

resource "azurerm_container_registry_webhook" "image_push" {
  count = var.enable_webhook && var.webhook_service_uri != "" ? 1 : 0

  name                = "imagepush"
  resource_group_name = var.resource_group_name
  registry_name       = azurerm_container_registry.main.name
  location            = var.location

  service_uri = var.webhook_service_uri
  status      = "enabled"
  scope       = "*:*"
  actions     = ["push"]

  custom_headers = {
    "Content-Type" = "application/json"
  }

  tags = local.common_tags
}

# =============================================================================
# TASKS (for automated builds - Premium only)
# =============================================================================

resource "azurerm_container_registry_task" "purge_old_images" {
  count = var.sku == "Premium" ? 1 : 0

  name                  = "purge-old-images"
  container_registry_id = azurerm_container_registry.main.id

  platform {
    os = "Linux"
  }

  encoded_step {
    task_content = base64encode(<<-EOT
      version: v1.1.0
      steps:
        - cmd: acr purge --filter '*:.*' --ago 90d --untagged --keep 10
          disableWorkingDirectoryOverride: true
          timeout: 3600
    EOT
    )
  }

  timer_trigger {
    name     = "weekly-purge"
    schedule = "0 0 * * 0" # Weekly on Sunday at midnight
    enabled  = true
  }

  tags = local.common_tags
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================


resource "azurerm_monitor_diagnostic_setting" "acr" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "acr-diagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================


