# =============================================================================
# OPEN HORIZONS PLATFORM - DEFENDER MODULE VARIABLES
# =============================================================================

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "customer_name" {
  description = "Customer name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "sizing_profile" {
  description = "Sizing profile: small, medium, large, xlarge"
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.sizing_profile)
    error_message = "Sizing profile must be small, medium, large, or xlarge."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for continuous export"
  type        = string
}

variable "security_contact_email" {
  description = "Email for security alerts"
  type        = string
}

variable "security_contact_phone" {
  description = "Phone for security alerts (optional)"
  type        = string
  default     = ""
}

variable "aks_cluster_ids" {
  description = "AKS cluster resource IDs for Defender for Containers"
  type        = list(string)
  default     = []
}

variable "regulatory_compliance_standards" {
  description = "Regulatory compliance standards to enable"
  type        = list(string)
  default     = ["Azure-CIS-1.4.0"]
}

variable "enable_jit_access" {
  description = "Enable Just-In-Time VM access"
  type        = bool
  default     = true
}

variable "auto_provisioning_settings" {
  description = "Auto-provisioning settings for agents"
  type = object({
    log_analytics_agent      = bool
    vulnerability_assessment = bool
    defender_for_containers  = bool
  })
  default = {
    log_analytics_agent      = true
    vulnerability_assessment = true
    defender_for_containers  = true
  }
}

variable "governance_rules" {
  description = "Governance rules for auto-remediation"
  type = list(object({
    name              = string
    description       = string
    owner_email       = string
    grace_period_days = number
    severity          = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
