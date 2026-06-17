# =============================================================================
# OPEN HORIZONS PLATFORM - NETWORKING MODULE VARIABLES
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

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_config" {
  description = "Subnet configuration"
  type = object({
    aks_nodes_cidr         = string
    aks_pods_cidr          = string
    private_endpoints_cidr = string
    bastion_cidr           = string
    app_gateway_cidr       = string
  })
  default = {
    aks_nodes_cidr         = "10.0.0.0/22"
    aks_pods_cidr          = "10.0.16.0/20"
    private_endpoints_cidr = "10.0.4.0/24"
    bastion_cidr           = "10.0.5.0/26"
    app_gateway_cidr       = "10.0.6.0/24"
  }
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure VM access"
  type        = bool
  default     = false
}

variable "enable_app_gateway" {
  description = "Enable Application Gateway subnet"
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Public DNS zone name"
  type        = string
}

variable "create_dns_zone" {
  description = "Create the public DNS zone"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
