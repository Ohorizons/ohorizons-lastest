# =============================================================================
# OPEN HORIZONS PLATFORM - CONTAINER REGISTRY MODULE VARIABLES
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

variable "sku" {
  description = "ACR SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for ACR"
  type        = string
}

variable "geo_replication_locations" {
  description = "Locations for geo-replication (Premium only)"
  type        = list(string)
  default     = []
}

variable "retention_policy_days" {
  description = "Days to retain untagged manifests"
  type        = number
  default     = 30
}

variable "enable_content_trust" {
  description = "Enable content trust (image signing)"
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for container images"
  type        = bool
  default     = true
}

variable "aks_kubelet_identity_object_id" {
  description = "AKS kubelet managed identity object ID for ACR pull"
  type        = string
}

variable "github_actions_identity_ids" {
  description = "Managed identity IDs for GitHub Actions push access"
  type        = list(string)
  default     = []
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

# =============================================================================
# WEBHOOK CONFIGURATION
# =============================================================================

variable "enable_webhook" {
  description = "Enable webhook for image push notifications"
  type        = bool
  default     = false
}

variable "webhook_service_uri" {
  description = "Webhook service URI for image push notifications"
  type        = string
  default     = ""
}
