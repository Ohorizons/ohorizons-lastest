# =============================================================================
# OPEN HORIZONS PLATFORM - AI FOUNDRY MODULE VARIABLES
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
  description = "Private DNS zone IDs"
  type = object({
    openai            = string
    cognitiveservices = string
    search            = string
  })
}

variable "openai_config" {
  description = "Azure OpenAI configuration"
  type = object({
    enabled  = bool
    sku_name = string
    models = list(object({
      name          = string
      model_name    = string
      model_version = string
      capacity      = number
      rai_policy    = string
    }))
  })
  default = {
    enabled  = true
    sku_name = "S0"
    models = [
      {
        name          = "gpt-4o"
        model_name    = "gpt-4o"
        model_version = "2024-05-13"
        capacity      = 30
        rai_policy    = "Microsoft.Default"
      },
      {
        name          = "gpt-4o-mini"
        model_name    = "gpt-4o-mini"
        model_version = "2024-07-18"
        capacity      = 100
        rai_policy    = "Microsoft.Default"
      },
      {
        name          = "text-embedding-3-large"
        model_name    = "text-embedding-3-large"
        model_version = "1"
        capacity      = 100
        rai_policy    = "Microsoft.Default"
      }
    ]
  }
}

variable "ai_search_config" {
  description = "Azure AI Search configuration"
  type = object({
    enabled                       = bool
    sku_name                      = string
    replica_count                 = number
    partition_count               = number
    semantic_search_sku           = string
    public_network_access_enabled = bool
  })
  default = {
    enabled                       = true
    sku_name                      = "standard"
    replica_count                 = 1
    partition_count               = 1
    semantic_search_sku           = "standard"
    public_network_access_enabled = false
  }
}

variable "content_safety_config" {
  description = "Azure AI Content Safety configuration"
  type = object({
    enabled  = bool
    sku_name = string
  })
  default = {
    enabled  = true
    sku_name = "S0"
  }
}

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
