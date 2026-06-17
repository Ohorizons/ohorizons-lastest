# =============================================================================
# OPEN HORIZONS PLATFORM - AKS CLUSTER MODULE VARIABLES
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
  description = "Name of the resource group"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "sku_tier" {
  description = "AKS SKU tier (Free, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "network_config" {
  description = "Network configuration for AKS"
  type = object({
    vnet_id         = string
    nodes_subnet_id = string
    pods_subnet_id  = string
    network_plugin  = string
    network_policy  = string
    service_cidr    = string
    dns_service_ip  = string
  })
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes (deprecated, use network_config)"
  type        = string
  default     = null
}

variable "pod_subnet_id" {
  description = "Subnet ID for pods (deprecated, use network_config)"
  type        = string
  default     = null
}

variable "default_node_pool" {
  description = "Default (system) node pool configuration"
  type = object({
    name                = string
    node_count          = number
    vm_size             = string
    min_count           = number
    max_count           = number
    os_disk_size_gb     = number
    os_disk_type        = string
    max_pods            = number
    enable_auto_scaling = bool
    zones               = list(string)
  })
  default = {
    name                = "system"
    node_count          = 3
    vm_size             = "Standard_D4s_v5"
    min_count           = 3
    max_count           = 6
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    max_pods            = 110
    enable_auto_scaling = true
    zones               = ["1", "2", "3"]
  }
}

variable "additional_node_pools" {
  description = "Additional (user) node pools configuration"
  type = map(object({
    name                = string
    node_count          = number
    vm_size             = string
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    max_pods            = number
    node_labels         = map(string)
    node_taints         = list(string)
    zones               = list(string)
  }))
  default = {}
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy"
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers"
  type        = bool
  default     = false
}

variable "enable_image_cleaner" {
  description = "Enable image cleaner"
  type        = bool
  default     = true
}

variable "enable_cost_analysis" {
  description = "Enable cost analysis"
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaler" {
  description = "Enable vertical pod autoscaler"
  type        = bool
  default     = true
}

variable "admin_group_ids" {
  description = "Azure AD group IDs for cluster admin access"
  type        = list(string)
  default     = []
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private cluster"
  type        = string
  default     = null
}

variable "acr_id" {
  description = "Azure Container Registry ID for pull permissions"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault ID for secrets integration"
  type        = string
  default     = null
}

variable "log_analytics_id" {
  description = "Log Analytics Workspace ID for Container Insights"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
