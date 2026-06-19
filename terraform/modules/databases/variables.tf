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
  description = "Azure Managed Redis (Microsoft.Cache/redisEnterprise) configuration. Classic Azure Cache for Redis is retiring; this module provisions Azure Managed Redis via azapi."
  type = object({
    enabled             = bool
    sku_name            = string       # Balanced_B0|Balanced_B1|Balanced_B3|MemoryOptimized_M10|ComputeOptimized_X3|FlashOptimized_A250 ...
    high_availability   = bool         # Disable ONLY for dev/test. Balanced_B0/B1 have no geo-replication.
    minimum_tls_version = string       # "1.2"
    client_protocol     = string       # "Encrypted" (TLS) or "Plaintext"
    clustering_policy   = string       # "OSSCluster" (default) or "EnterpriseCluster"
    eviction_policy     = string       # "VolatileLRU" | "AllKeysLRU" | "NoEviction" ...
    modules             = list(string) # ["RediSearch", "RedisJSON"] to enable vector / semantic cache
  })
  default = {
    enabled             = true
    sku_name            = "Balanced_B0"
    high_availability   = false
    minimum_tls_version = "1.2"
    client_protocol     = "Encrypted"
    clustering_policy   = "OSSCluster"
    eviction_policy     = "VolatileLRU"
    modules             = []
  }

  validation {
    condition = alltrue([
      for module_name in var.redis_config.modules : contains([
        "RediSearch",
        "RedisBloom",
        "RedisTimeSeries",
        "RedisJSON"
      ], module_name)
    ])
    error_message = "Azure Managed Redis modules must be one of: RediSearch, RedisBloom, RedisTimeSeries, RedisJSON."
  }

  validation {
    condition = !contains(var.redis_config.modules, "RediSearch") || (
      var.redis_config.clustering_policy == "EnterpriseCluster" &&
      var.redis_config.eviction_policy == "NoEviction" &&
      !can(regex("^FlashOptimized_", var.redis_config.sku_name))
    )
    error_message = "When modules includes RediSearch, Azure Managed Redis requires clustering_policy = EnterpriseCluster, eviction_policy = NoEviction, and a non-FlashOptimized SKU."
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
