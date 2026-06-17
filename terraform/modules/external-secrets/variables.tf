# =============================================================================
# EXTERNAL SECRETS OPERATOR MODULE - VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "customer_name" {
  type        = string
  description = "Customer name for resource naming"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.customer_name))
    error_message = "Customer name must be 3-21 lowercase alphanumeric characters, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "aks_cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "key_vault_id" {
  type        = string
  description = "Resource ID of the Azure Key Vault"
}

variable "key_vault_uri" {
  type        = string
  description = "URI of the Azure Key Vault (e.g., https://myvault.vault.azure.net/)"
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES
# -----------------------------------------------------------------------------

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for External Secrets Operator"
  default     = "external-secrets"
}

variable "eso_chart_version" {
  type        = string
  description = "Version of the External Secrets Operator Helm chart"
  default     = "0.9.11"
}

variable "use_key_vault_rbac" {
  type        = bool
  description = "Use RBAC for Key Vault access instead of access policies"
  default     = false
}

variable "enable_prometheus_metrics" {
  type        = bool
  description = "Enable Prometheus metrics endpoint"
  default     = true
}

variable "create_example_secret" {
  type        = bool
  description = "Create an example ExternalSecret resource"
  default     = false
}

variable "enable_push_secrets" {
  type        = bool
  description = "Enable PushSecret functionality to sync secrets to Key Vault"
  default     = false
}

variable "node_selector" {
  type        = map(string)
  description = "Node selector for ESO pods"
  default     = {}
}

variable "tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  description = "Tolerations for ESO pods"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to Azure resources"
  default     = {}
}
