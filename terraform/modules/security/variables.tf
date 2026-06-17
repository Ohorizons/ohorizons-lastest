# =============================================================================
# OPEN HORIZONS PLATFORM - SECURITY MODULE VARIABLES
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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL for workload identity"
  type        = string
}

variable "key_vault_config" {
  description = "Key Vault configuration"
  type = object({
    sku_name                      = string
    soft_delete_retention_days    = number
    purge_protection_enabled      = bool
    enable_rbac_authorization     = bool
    public_network_access_enabled = bool
    network_acls = object({
      bypass                     = string
      default_action             = string
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    })
  })
  default = {
    sku_name                      = "standard"
    soft_delete_retention_days    = 90
    purge_protection_enabled      = true
    enable_rbac_authorization     = true
    public_network_access_enabled = false
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      ip_rules                   = []
      virtual_network_subnet_ids = []
    }
  }
}

variable "admin_group_id" {
  description = "Azure AD group ID for Key Vault administrators"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for Key Vault"
  type        = string
}

variable "workload_identities" {
  description = "Workload identities to create"
  type = map(object({
    namespace       = string
    service_account = string
    key_vault_role  = string
    additional_role_assignments = list(object({
      scope                = string
      role_definition_name = string
    }))
  }))
  default = {
    "backstage" = {
      namespace                   = "backstage"
      service_account             = "backstage"
      key_vault_role              = "Key Vault Secrets User"
      additional_role_assignments = []
    }
    "argocd" = {
      namespace                   = "argocd"
      service_account             = "argocd-server"
      key_vault_role              = "Key Vault Secrets User"
      additional_role_assignments = []
    }
    "external-secrets" = {
      namespace                   = "external-secrets"
      service_account             = "external-secrets"
      key_vault_role              = "Key Vault Secrets User"
      additional_role_assignments = []
    }
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
