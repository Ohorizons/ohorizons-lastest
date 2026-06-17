# =============================================================================
# DISASTER RECOVERY MODULE - VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "customer_name" {
  type        = string
  description = "Customer name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "primary_location" {
  type        = string
  description = "Primary Azure region"
}

variable "primary_region_short" {
  type        = string
  description = "Short code for primary region (e.g., brz, eus2)"
}

variable "primary_resource_group_name" {
  type        = string
  description = "Name of the primary resource group"
}

# -----------------------------------------------------------------------------
# DR REGION CONFIGURATION
# -----------------------------------------------------------------------------

variable "dr_location" {
  type        = string
  description = "Disaster recovery Azure region"
  default     = "eastus2"
}

variable "dr_region_short" {
  type        = string
  description = "Short code for DR region"
  default     = "eu2"
}

# -----------------------------------------------------------------------------
# RECOVERY OBJECTIVES
# -----------------------------------------------------------------------------

variable "recovery_point_objective" {
  type        = string
  description = "Recovery Point Objective (RPO) - acceptable data loss duration"
  default     = "1h"

  validation {
    condition     = can(regex("^[0-9]+[mhd]$", var.recovery_point_objective))
    error_message = "RPO must be in format: Xm (minutes), Xh (hours), or Xd (days)."
  }
}

variable "recovery_time_objective" {
  type        = string
  description = "Recovery Time Objective (RTO) - acceptable downtime duration"
  default     = "4h"

  validation {
    condition     = can(regex("^[0-9]+[mhd]$", var.recovery_time_objective))
    error_message = "RTO must be in format: Xm (minutes), Xh (hours), or Xd (days)."
  }
}

# -----------------------------------------------------------------------------
# BACKUP RETENTION SETTINGS
# -----------------------------------------------------------------------------

variable "retention_daily_count" {
  type        = number
  description = "Number of daily backups to retain"
  default     = 7

  validation {
    condition     = var.retention_daily_count >= 1 && var.retention_daily_count <= 9999
    error_message = "Daily retention must be between 1 and 9999."
  }
}

variable "retention_weekly_count" {
  type        = number
  description = "Number of weekly backups to retain"
  default     = 4

  validation {
    condition     = var.retention_weekly_count >= 1 && var.retention_weekly_count <= 5163
    error_message = "Weekly retention must be between 1 and 5163."
  }
}

variable "retention_monthly_count" {
  type        = number
  description = "Number of monthly backups to retain"
  default     = 12

  validation {
    condition     = var.retention_monthly_count >= 1 && var.retention_monthly_count <= 1188
    error_message = "Monthly retention must be between 1 and 1188."
  }
}

variable "retention_yearly_count" {
  type        = number
  description = "Number of yearly backups to retain (0 to disable)"
  default     = 1

  validation {
    condition     = var.retention_yearly_count >= 0 && var.retention_yearly_count <= 99
    error_message = "Yearly retention must be between 0 and 99."
  }
}

variable "instant_restore_days" {
  type        = number
  description = "Number of days for instant restore snapshots"
  default     = 2

  validation {
    condition     = var.instant_restore_days >= 1 && var.instant_restore_days <= 5
    error_message = "Instant restore days must be between 1 and 5."
  }
}

variable "timezone" {
  type        = string
  description = "Timezone for backup schedules"
  default     = "E. South America Standard Time"
}

# -----------------------------------------------------------------------------
# STORAGE SETTINGS
# -----------------------------------------------------------------------------

variable "storage_redundancy" {
  type        = string
  description = "Storage redundancy type for Recovery Services Vault"
  default     = "GeoRedundant"

  validation {
    condition     = contains(["GeoRedundant", "LocallyRedundant", "ZoneRedundant"], var.storage_redundancy)
    error_message = "Storage redundancy must be: GeoRedundant, LocallyRedundant, or ZoneRedundant."
  }
}

variable "enable_cross_region_restore" {
  type        = bool
  description = "Enable cross-region restore capability"
  default     = true
}

# -----------------------------------------------------------------------------
# SITE RECOVERY SETTINGS
# -----------------------------------------------------------------------------

variable "enable_site_recovery" {
  type        = bool
  description = "Enable Azure Site Recovery for VM replication"
  default     = false
}

variable "replication_recovery_point_retention_minutes" {
  type        = number
  description = "Recovery point retention in minutes for ASR"
  default     = 1440 # 24 hours

  validation {
    condition     = var.replication_recovery_point_retention_minutes >= 0 && var.replication_recovery_point_retention_minutes <= 43200
    error_message = "Recovery point retention must be between 0 and 43200 minutes."
  }
}

variable "app_consistent_snapshot_frequency_minutes" {
  type        = number
  description = "App-consistent snapshot frequency in minutes"
  default     = 240 # 4 hours

  validation {
    condition     = var.app_consistent_snapshot_frequency_minutes >= 0 && var.app_consistent_snapshot_frequency_minutes <= 720
    error_message = "Snapshot frequency must be between 0 and 720 minutes."
  }
}

variable "primary_vnet_id" {
  type        = string
  description = "Resource ID of primary VNet for network mapping"
  default     = null
}

variable "dr_vnet_id" {
  type        = string
  description = "Resource ID of DR VNet for network mapping"
  default     = null
}

# -----------------------------------------------------------------------------
# SECURITY SETTINGS
# -----------------------------------------------------------------------------

variable "enable_immutability" {
  type        = bool
  description = "Enable immutability for vault (compliance requirement)"
  default     = false
}

variable "customer_managed_key_id" {
  type        = string
  description = "Key Vault Key ID for customer-managed encryption"
  default     = null
}

# -----------------------------------------------------------------------------
# MONITORING
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostics"
  default     = null
}

variable "enable_alerts" {
  type        = bool
  description = "Enable monitoring alerts for DR operations"
  default     = true
}

variable "action_group_id" {
  type        = string
  description = "Action Group ID for alert notifications"
  default     = null
}

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
