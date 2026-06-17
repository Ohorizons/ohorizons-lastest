# =============================================================================
# OPEN HORIZONS PLATFORM - DISASTER RECOVERY MODULE
# =============================================================================
#
# Azure Disaster Recovery configuration including:
#   - Recovery Services Vault
#   - Backup policies for VMs and databases
#   - Azure Site Recovery for regional failover
#   - Geo-redundant storage for backups
#   - Cross-region replication
#
# =============================================================================

# -----------------------------------------------------------------------------
# LOCAL VALUES
# -----------------------------------------------------------------------------

locals {
  rsv_name = "rsv-${var.customer_name}-${var.environment}-${var.primary_region_short}"

  common_tags = merge(var.tags, {
    "app.kubernetes.io/managed-by" = "terraform"
    "platform.open-horizons/tier" = "disaster-recovery"
    "disaster-recovery/rpo"        = var.recovery_point_objective
    "disaster-recovery/rto"        = var.recovery_time_objective
  })

  # Backup schedule mappings
  backup_schedules = {
    daily = {
      frequency = "Daily"
      time      = "23:00"
    }
    weekly = {
      frequency = "Weekly"
      time      = "23:00"
      weekdays  = ["Sunday"]
    }
  }
}

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "primary" {
  name = var.primary_resource_group_name
}

# -----------------------------------------------------------------------------
# RECOVERY SERVICES VAULT
# -----------------------------------------------------------------------------

resource "azurerm_recovery_services_vault" "main" {
  name                = local.rsv_name
  location            = var.primary_location
  resource_group_name = var.primary_resource_group_name
  sku                 = "Standard"

  # Soft delete settings
  soft_delete_enabled = true

  # Cross-region restore
  cross_region_restore_enabled = var.enable_cross_region_restore

  # Storage settings
  storage_mode_type = var.storage_redundancy

  # Immutability (for compliance)
  dynamic "immutability" {
    for_each = var.enable_immutability ? [1] : []
    content {
      state = "Unlocked"
    }
  }

  # Encryption
  dynamic "encryption" {
    for_each = var.customer_managed_key_id != null ? [1] : []
    content {
      key_id                            = var.customer_managed_key_id
      infrastructure_encryption_enabled = true
      use_system_assigned_identity      = true
    }
  }

  identity {
    type = "SystemAssigned"
  }

  monitoring {
    alerts_for_all_job_failures_enabled            = true
    alerts_for_critical_operation_failures_enabled = true
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# BACKUP POLICIES - VIRTUAL MACHINES
# -----------------------------------------------------------------------------

resource "azurerm_backup_policy_vm" "daily" {
  name                = "policy-vm-daily"
  resource_group_name = var.primary_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  timezone = var.timezone

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = var.retention_daily_count
  }

  retention_weekly {
    count    = var.retention_weekly_count
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = var.retention_monthly_count
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  dynamic "retention_yearly" {
    for_each = var.retention_yearly_count > 0 ? [1] : []
    content {
      count    = var.retention_yearly_count
      weekdays = ["Sunday"]
      weeks    = ["First"]
      months   = ["January"]
    }
  }

  instant_restore_retention_days = var.instant_restore_days
}

resource "azurerm_backup_policy_vm" "weekly" {
  name                = "policy-vm-weekly"
  resource_group_name = var.primary_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  timezone = var.timezone

  backup {
    frequency = "Weekly"
    time      = "23:00"
    weekdays  = ["Sunday"]
  }

  retention_weekly {
    count    = var.retention_weekly_count * 2
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = var.retention_monthly_count
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

# -----------------------------------------------------------------------------
# BACKUP POLICIES - AZURE FILES
# -----------------------------------------------------------------------------

resource "azurerm_backup_policy_file_share" "default" {
  name                = "policy-fileshare-default"
  resource_group_name = var.primary_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  timezone = var.timezone

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = var.retention_daily_count
  }

  retention_weekly {
    count    = var.retention_weekly_count
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = var.retention_monthly_count
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

# -----------------------------------------------------------------------------
# AZURE SITE RECOVERY - FABRICS
# -----------------------------------------------------------------------------

resource "azurerm_site_recovery_fabric" "primary" {
  count = var.enable_site_recovery ? 1 : 0

  name                = "fabric-${var.primary_region_short}"
  resource_group_name = var.primary_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  location            = var.primary_location
}

resource "azurerm_site_recovery_fabric" "secondary" {
  count = var.enable_site_recovery ? 1 : 0

  name                = "fabric-${var.dr_region_short}"
  resource_group_name = var.primary_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  location            = var.dr_location
}

# -----------------------------------------------------------------------------
# AZURE SITE RECOVERY - PROTECTION CONTAINERS
# -----------------------------------------------------------------------------

resource "azurerm_site_recovery_protection_container" "primary" {
  count = var.enable_site_recovery ? 1 : 0

  name                 = "container-${var.primary_region_short}"
  resource_group_name  = var.primary_resource_group_name
  recovery_vault_name  = azurerm_recovery_services_vault.main.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary[0].name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  count = var.enable_site_recovery ? 1 : 0

  name                 = "container-${var.dr_region_short}"
  resource_group_name  = var.primary_resource_group_name
  recovery_vault_name  = azurerm_recovery_services_vault.main.name
  recovery_fabric_name = azurerm_site_recovery_fabric.secondary[0].name
}

# -----------------------------------------------------------------------------
# AZURE SITE RECOVERY - REPLICATION POLICY
# -----------------------------------------------------------------------------

resource "azurerm_site_recovery_replication_policy" "default" {
  count = var.enable_site_recovery ? 1 : 0

  name                                                 = "policy-replication-default"
  resource_group_name                                  = var.primary_resource_group_name
  recovery_vault_name                                  = azurerm_recovery_services_vault.main.name
  recovery_point_retention_in_minutes                  = var.replication_recovery_point_retention_minutes
  application_consistent_snapshot_frequency_in_minutes = var.app_consistent_snapshot_frequency_minutes
}

# -----------------------------------------------------------------------------
# AZURE SITE RECOVERY - CONTAINER MAPPING
# -----------------------------------------------------------------------------

resource "azurerm_site_recovery_protection_container_mapping" "primary_to_secondary" {
  count = var.enable_site_recovery ? 1 : 0

  name                                      = "mapping-${var.primary_region_short}-to-${var.dr_region_short}"
  resource_group_name                       = var.primary_resource_group_name
  recovery_vault_name                       = azurerm_recovery_services_vault.main.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary[0].name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary[0].name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary[0].id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.default[0].id
}

# Reverse mapping for failback
resource "azurerm_site_recovery_protection_container_mapping" "secondary_to_primary" {
  count = var.enable_site_recovery ? 1 : 0

  name                                      = "mapping-${var.dr_region_short}-to-${var.primary_region_short}"
  resource_group_name                       = var.primary_resource_group_name
  recovery_vault_name                       = azurerm_recovery_services_vault.main.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.secondary[0].name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.secondary[0].name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.primary[0].id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.default[0].id
}

# -----------------------------------------------------------------------------
# AZURE SITE RECOVERY - NETWORK MAPPING
# -----------------------------------------------------------------------------

resource "azurerm_site_recovery_network_mapping" "primary_to_secondary" {
  count = var.enable_site_recovery && var.primary_vnet_id != null && var.dr_vnet_id != null ? 1 : 0

  name                        = "network-mapping-${var.primary_region_short}-to-${var.dr_region_short}"
  resource_group_name         = var.primary_resource_group_name
  recovery_vault_name         = azurerm_recovery_services_vault.main.name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary[0].name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary[0].name
  source_network_id           = var.primary_vnet_id
  target_network_id           = var.dr_vnet_id
}

# -----------------------------------------------------------------------------
# DR STORAGE ACCOUNT (for cache and staging)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "dr_cache" {
  count = var.enable_site_recovery ? 1 : 0

  name                     = "st${replace(var.customer_name, "-", "")}drcache"
  resource_group_name      = var.primary_resource_group_name
  location                 = var.primary_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "rsv" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${local.rsv_name}"
  target_resource_id         = azurerm_recovery_services_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "CoreAzureBackup"
  }

  enabled_log {
    category = "AddonAzureBackupJobs"
  }

  enabled_log {
    category = "AddonAzureBackupAlerts"
  }

  enabled_log {
    category = "AddonAzureBackupPolicy"
  }

  enabled_log {
    category = "AddonAzureBackupStorage"
  }

  enabled_log {
    category = "AddonAzureBackupProtectedInstance"
  }

  enabled_log {
    category = "AzureSiteRecoveryJobs"
  }

  enabled_log {
    category = "AzureSiteRecoveryEvents"
  }

  enabled_log {
    category = "AzureSiteRecoveryReplicatedItems"
  }

  metric {
    category = "Health"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# ALERTS FOR DR OPERATIONS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "backup_health" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-backup-health-${var.customer_name}"
  resource_group_name = var.primary_resource_group_name
  scopes              = [azurerm_recovery_services_vault.main.id]
  description         = "Alert when backup health degrades"
  severity            = 2
  frequency           = "PT1H"
  window_size         = "PT1H"

  criteria {
    metric_namespace = "Microsoft.RecoveryServices/vaults"
    metric_name      = "BackupHealthEvent"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "HealthStatus"
      operator = "Include"
      values   = ["PersistentUnhealthy", "TransientUnhealthy"]
    }
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = local.common_tags
}
