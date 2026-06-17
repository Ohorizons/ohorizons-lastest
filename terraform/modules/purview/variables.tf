# =============================================================================
# OPEN HORIZONS PLATFORM - PURVIEW MODULE VARIABLES
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

variable "sizing_profile" {
  description = "Sizing profile: small, medium, large, xlarge"
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.sizing_profile)
    error_message = "Sizing profile must be small, medium, large, or xlarge."
  }
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs for Purview endpoints"
  type = object({
    purview        = string
    purview_studio = string
    storage_blob   = string
    storage_queue  = string
    servicebus     = string
    eventhub       = string
  })
}

variable "data_sources" {
  description = "Data sources to register and scan"
  type = list(object({
    name           = string
    type           = string
    resource_id    = string
    scan_frequency = string
  }))
  default = []
}

variable "admin_group_id" {
  description = "Azure AD group ID for Purview administrators"
  type        = string
}

variable "enable_latam_classifications" {
  description = "Enable LATAM-specific data classifications"
  type        = bool
  default     = true
}

variable "glossary_terms" {
  description = "Business glossary terms to create"
  type = list(object({
    name       = string
    definition = string
    stewards   = list(string)
    experts    = list(string)
    status     = string
  }))
  default = []
}

variable "collection_hierarchy" {
  description = "Collection structure for organizing assets"
  type = list(object({
    name        = string
    parent      = string
    description = string
  }))
  default = [
    { name = "H1-Foundation", parent = "", description = "Foundation infrastructure assets" },
    { name = "H2-Enhancement", parent = "", description = "Enhanced platform assets" },
    { name = "H3-Innovation", parent = "", description = "AI/ML innovation assets" }
  ]
}

variable "data_quality_rules" {
  description = "Data quality rules to configure"
  type = list(object({
    name        = string
    description = string
    dimension   = string
    threshold   = number
    applies_to  = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
