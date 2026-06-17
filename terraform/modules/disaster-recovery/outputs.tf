# =============================================================================
# DISASTER RECOVERY MODULE - OUTPUTS
# =============================================================================

output "recovery_vault_id" {
  value       = azurerm_recovery_services_vault.main.id
  description = "Resource ID of the Recovery Services Vault"
}

output "recovery_vault_name" {
  value       = azurerm_recovery_services_vault.main.name
  description = "Name of the Recovery Services Vault"
}

output "recovery_vault_identity" {
  value       = azurerm_recovery_services_vault.main.identity[0].principal_id
  description = "Principal ID of the vault's managed identity"
}

# Backup Policies
output "vm_backup_policy_daily_id" {
  value       = azurerm_backup_policy_vm.daily.id
  description = "Resource ID of the daily VM backup policy"
}

output "vm_backup_policy_weekly_id" {
  value       = azurerm_backup_policy_vm.weekly.id
  description = "Resource ID of the weekly VM backup policy"
}

output "fileshare_backup_policy_id" {
  value       = azurerm_backup_policy_file_share.default.id
  description = "Resource ID of the file share backup policy"
}

# Site Recovery
output "asr_primary_fabric_id" {
  value       = var.enable_site_recovery ? azurerm_site_recovery_fabric.primary[0].id : null
  description = "Resource ID of the primary ASR fabric"
}

output "asr_secondary_fabric_id" {
  value       = var.enable_site_recovery ? azurerm_site_recovery_fabric.secondary[0].id : null
  description = "Resource ID of the secondary ASR fabric"
}

output "asr_primary_container_id" {
  value       = var.enable_site_recovery ? azurerm_site_recovery_protection_container.primary[0].id : null
  description = "Resource ID of the primary protection container"
}

output "asr_secondary_container_id" {
  value       = var.enable_site_recovery ? azurerm_site_recovery_protection_container.secondary[0].id : null
  description = "Resource ID of the secondary protection container"
}

output "asr_replication_policy_id" {
  value       = var.enable_site_recovery ? azurerm_site_recovery_replication_policy.default[0].id : null
  description = "Resource ID of the ASR replication policy"
}

output "dr_cache_storage_account_id" {
  value       = var.enable_site_recovery ? azurerm_storage_account.dr_cache[0].id : null
  description = "Resource ID of the DR cache storage account"
}

# Recovery Objectives
output "recovery_objectives" {
  value = {
    rpo = var.recovery_point_objective
    rto = var.recovery_time_objective
  }
  description = "Configured recovery objectives"
}

# Retention Settings
output "retention_policy" {
  value = {
    daily   = var.retention_daily_count
    weekly  = var.retention_weekly_count
    monthly = var.retention_monthly_count
    yearly  = var.retention_yearly_count
  }
  description = "Backup retention policy settings"
}

# Region Information
output "dr_configuration" {
  value = {
    primary_region        = var.primary_location
    dr_region             = var.dr_location
    storage_type          = var.storage_redundancy
    cross_region_restore  = var.enable_cross_region_restore
    site_recovery_enabled = var.enable_site_recovery
  }
  description = "Disaster recovery configuration summary"
}
