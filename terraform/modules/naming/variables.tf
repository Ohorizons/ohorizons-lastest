# =============================================================================
# AZURE NAMING MODULE - VARIABLES
# =============================================================================
#
# Input variables for generating Azure resource names following
# Microsoft's Cloud Adoption Framework naming conventions.
#
# =============================================================================

variable "project_name" {
  description = "Project or workload name (e.g., 'threehorizons')"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.project_name))
    error_message = "Project name must be 2-10 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment short name"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prd", "sbx", "tst"], var.environment)
    error_message = "Environment must be: dev, stg, prd, sbx, or tst."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "instance" {
  description = "Instance number for multiple deployments (e.g., '001')"
  type        = string
  default     = "001"
}

variable "org_code" {
  description = "Organization code (2-4 chars, e.g., 'ms', 'cont')"
  type        = string
  default     = ""
}
