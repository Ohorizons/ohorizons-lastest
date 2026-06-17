# =============================================================================
# OPEN HORIZONS PLATFORM - OBSERVABILITY MODULE VARIABLES
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

variable "aks_cluster_id" {
  description = "AKS cluster resource ID"
  type        = string
}

variable "grafana_admin_group_id" {
  description = "Azure AD group ID for Grafana admins"
  type        = string
}

variable "grafana_viewer_group_id" {
  description = "Azure AD group ID for Grafana viewers"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Enable Container Insights"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (for Container Insights)"
  type        = string
  default     = ""
}

variable "retention_days" {
  description = "Data retention in days"
  type        = number
  default     = 30
}

variable "alert_email_receivers" {
  description = "Email addresses for alert notifications"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
