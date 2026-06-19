# =============================================================================
# OPEN HORIZONS PLATFORM - DATABASES TERRAFORM MODULE
# =============================================================================
#
# Deploys managed database services for the platform.
#
# Components:
#   - Azure Database for PostgreSQL Flexible Server
#   - Azure Cache for Redis
#   - Private endpoints for secure connectivity
#   - Backup and geo-replication (prod)
#
# =============================================================================

# NOTE: Terraform block is in versions.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}-${var.environment}"

  common_tags = merge(var.tags, {
    "open-horizons/customer"    = var.customer_name
    "open-horizons/environment" = var.environment
    "open-horizons/component"   = "databases"
  })

  # Production settings
  is_prod = var.environment == "prod"

  # Azure Managed Redis exposes the cluster endpoint on a fixed port.
  redis_port = 10000
}

# =============================================================================
# RANDOM PASSWORD GENERATION
# =============================================================================

resource "random_password" "postgresql" {
  count = var.postgresql_config.enabled ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Azure Managed Redis access keys are retrieved via the listKeys action
# (azapi_resource_action.redis_keys); no generated password is required.

# =============================================================================
# POSTGRESQL FLEXIBLE SERVER
# =============================================================================

resource "azurerm_postgresql_flexible_server" "main" {
  count = var.postgresql_config.enabled ? 1 : 0

  name                = "psql-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  version    = var.postgresql_config.version
  sku_name   = var.postgresql_config.sku_name
  storage_mb = var.postgresql_config.storage_mb

  administrator_login    = var.postgresql_config.admin_username
  administrator_password = random_password.postgresql[0].result

  backup_retention_days        = var.postgresql_config.backup_retention_days
  geo_redundant_backup_enabled = local.is_prod && var.postgresql_config.geo_redundant_backup

  # High availability (prod only)
  dynamic "high_availability" {
    for_each = local.is_prod && var.postgresql_config.high_availability ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  # Private access via delegated subnet
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = var.private_dns_zone_ids.postgres

  # Maintenance window
  maintenance_window {
    day_of_week  = 0 # Sunday
    start_hour   = 3
    start_minute = 0
  }

  # Authentication
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

# PostgreSQL Databases
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each = var.postgresql_config.enabled ? toset(var.postgresql_config.databases) : []

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# PostgreSQL Configuration
resource "azurerm_postgresql_flexible_server_configuration" "configs" {
  for_each = var.postgresql_config.enabled ? {
    "log_checkpoints"            = "on"
    "log_connections"            = "on"
    "log_disconnections"         = "on"
    "log_lock_waits"             = "on"
    "log_min_duration_statement" = "1000"
    "shared_preload_libraries"   = "pg_stat_statements"
    "track_activity_query_size"  = "4096"
    "work_mem"                   = "32768"
    "maintenance_work_mem"       = "524288"
    "effective_cache_size"       = "1572864"
  } : {}

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main[0].id
  value     = each.value
}

# PostgreSQL Firewall Rule (allow Azure services)
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  count = var.postgresql_config.enabled ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# =============================================================================
# AZURE MANAGED REDIS (Microsoft.Cache/redisEnterprise)
# =============================================================================
#
# Classic Azure Cache for Redis (azurerm_redis_cache) is retiring for new
# creations, so the platform provisions Azure Managed Redis through azapi.
# The cluster exposes the endpoint; a single "default" database carries the
# protocol, clustering, eviction and (optional) RediSearch/RedisJSON modules
# used by the agent semantic cache and vector memory.

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azapi_resource" "redis_enterprise" {
  count = var.redis_config.enabled ? 1 : 0

  type      = "Microsoft.Cache/redisEnterprise@2025-07-01"
  name      = "redis-${local.name_prefix}"
  parent_id = data.azurerm_resource_group.main.id
  location  = var.location

  body = {
    sku = {
      name = var.redis_config.sku_name
    }
    properties = {
      minimumTlsVersion   = var.redis_config.minimum_tls_version
      highAvailability    = var.redis_config.high_availability ? "Enabled" : "Disabled"
      publicNetworkAccess = "Disabled"
    }
  }

  response_export_values = ["properties.hostName"]

  tags = local.common_tags
}

resource "azapi_resource" "redis_database" {
  count = var.redis_config.enabled ? 1 : 0

  type      = "Microsoft.Cache/redisEnterprise/databases@2025-07-01"
  name      = "default"
  parent_id = azapi_resource.redis_enterprise[0].id

  body = {
    properties = {
      clientProtocol   = var.redis_config.client_protocol
      clusteringPolicy = var.redis_config.clustering_policy
      evictionPolicy   = var.redis_config.eviction_policy
      port             = local.redis_port
      modules          = [for m in var.redis_config.modules : { name = m }]
    }
  }
}

# Retrieve the database access keys (listKeys action).
resource "azapi_resource_action" "redis_keys" {
  count = var.redis_config.enabled ? 1 : 0

  type        = "Microsoft.Cache/redisEnterprise/databases@2025-07-01"
  resource_id = azapi_resource.redis_database[0].id
  action      = "listKeys"
  method      = "POST"

  response_export_values = ["primaryKey", "secondaryKey"]
}

# Redis Private Endpoint
resource "azurerm_private_endpoint" "redis" {
  count = var.redis_config.enabled ? 1 : 0

  name                = "pe-redis-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "redis-connection"
    private_connection_resource_id = azapi_resource.redis_enterprise[0].id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

  private_dns_zone_group {
    name                 = "redis-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.redis]
  }

  tags = local.common_tags
}

# =============================================================================
# KEY VAULT SECRETS
# =============================================================================

data "azurerm_client_config" "current" {}

# Store PostgreSQL connection string
resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  count = var.postgresql_config.enabled ? 1 : 0

  name         = "postgresql-connection-string"
  value        = "postgresql://${var.postgresql_config.admin_username}:${random_password.postgresql[0].result}@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/postgres?sslmode=require"
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

# Store PostgreSQL admin password
resource "azurerm_key_vault_secret" "postgresql_password" {
  count = var.postgresql_config.enabled ? 1 : 0

  name         = "postgresql-admin-password"
  value        = random_password.postgresql[0].result
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

# Store Redis connection string
resource "azurerm_key_vault_secret" "redis_connection_string" {
  count = var.redis_config.enabled ? 1 : 0

  name         = "redis-connection-string"
  value        = "${azapi_resource.redis_enterprise[0].output.properties.hostName}:${local.redis_port},password=${azapi_resource_action.redis_keys[0].output.primaryKey},ssl=True,abortConnect=False"
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

# Store Redis primary key
resource "azurerm_key_vault_secret" "redis_primary_key" {
  count = var.redis_config.enabled ? 1 : 0

  name         = "redis-primary-key"
  value        = azapi_resource_action.redis_keys[0].output.primaryKey
  key_vault_id = var.key_vault_id

  tags = local.common_tags
}

# =============================================================================
# OUTPUTS
# =============================================================================


