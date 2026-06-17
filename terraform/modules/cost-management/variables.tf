# =============================================================================
# COST MANAGEMENT MODULE - VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "customer_name" {
  type        = string
  description = "Customer name for resource naming"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.customer_name))
    error_message = "Customer name must be 3-21 lowercase alphanumeric characters."
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
  description = "Name of the resource group to monitor"
}

variable "monthly_budget" {
  type        = number
  description = "Monthly budget amount in USD"

  validation {
    condition     = var.monthly_budget > 0
    error_message = "Monthly budget must be greater than 0."
  }
}

variable "alert_email_addresses" {
  type        = list(string)
  description = "Email addresses for budget alerts"

  validation {
    condition     = length(var.alert_email_addresses) > 0
    error_message = "At least one email address must be provided."
  }
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES
# -----------------------------------------------------------------------------

variable "cost_center" {
  type        = string
  description = "Cost center tag for resource allocation"
  default     = "platform"
}

variable "budget_end_date" {
  type        = string
  description = "End date for budget period (format: YYYY-MM-DDT00:00:00Z)"
  default     = "2030-12-31T00:00:00Z"
}

variable "budget_filter_tags" {
  type        = map(list(string))
  description = "Tags to filter budget scope"
  default     = {}
}

variable "action_group_ids" {
  type        = list(string)
  description = "IDs of existing Azure Monitor Action Groups"
  default     = []
}

variable "create_action_group" {
  type        = bool
  description = "Create a new Action Group for cost alerts"
  default     = true
}

variable "webhook_urls" {
  type        = list(string)
  description = "Webhook URLs for alert notifications"
  default     = []
}

variable "azure_function_id" {
  type        = string
  description = "Resource ID of Azure Function for cost alert handling"
  default     = null
}

variable "azure_function_url" {
  type        = string
  description = "HTTP trigger URL for Azure Function"
  default     = null
}

# Subscription Budget
variable "create_subscription_budget" {
  type        = bool
  description = "Create a subscription-level budget"
  default     = false
}

variable "subscription_monthly_budget" {
  type        = number
  description = "Monthly budget for subscription level"
  default     = 10000
}

# Cost Export
variable "enable_cost_export" {
  type        = bool
  description = "Enable automated cost data export"
  default     = true
}

variable "export_recurrence" {
  type        = string
  description = "Cost export recurrence (Daily, Weekly, Monthly)"
  default     = "Daily"

  validation {
    condition     = contains(["Daily", "Weekly", "Monthly"], var.export_recurrence)
    error_message = "Export recurrence must be: Daily, Weekly, or Monthly."
  }
}

# Custom Alerts
variable "enable_custom_cost_alerts" {
  type        = bool
  description = "Enable custom cost alert rules"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
