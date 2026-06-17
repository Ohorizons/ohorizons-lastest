# =============================================================================
# OPEN HORIZONS PLATFORM - DATABASES MODULE VARIABLES
# =============================================================================

variable "customer_name" {
  description = "Customer name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs for database services"
  type = object({
    postgres = string
    redis    = string
  })
}

variable "postgresql_config" {
  description = "PostgreSQL configuration"
  type = object({
    enabled               = bool
    sku_name              = string
    storage_mb            = number
    version               = string
    admin_username        = string
    backup_retention_days = number
    geo_redundant_backup  = bool
    high_availability     = bool
    databases             = list(string)
  })
  default = {
    enabled               = true
    sku_name              = "GP_Standard_D2s_v3"
    storage_mb            = 32768
    version               = "16"
    admin_username        = "pgadmin"
    backup_retention_days = 7
    geo_redundant_backup  = false
    high_availability     = false
    databases             = ["backstage"]
  }
}

variable "redis_config" {
  description = "Redis configuration"
  type = object({
    enabled             = bool
    sku_name            = string
    family              = string
    capacity            = number
    enable_non_ssl_port = bool
    minimum_tls_version = string
    maxmemory_policy    = string
  })
  default = {
    enabled             = true
    sku_name            = "Standard"
    family              = "C"
    capacity            = 1
    enable_non_ssl_port = false
    minimum_tls_version = "1.2"
    maxmemory_policy    = "volatile-lru"
  }
}

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
