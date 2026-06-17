# =============================================================================
# OPEN HORIZONS PLATFORM - GITHUB RUNNERS MODULE VARIABLES
# =============================================================================

variable "customer_name" {
  description = "Customer name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for runners"
  type        = string
  default     = "github-runners"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID for runner authentication"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID"
  type        = string
  sensitive   = true
}

variable "github_app_private_key" {
  description = "GitHub App private key (PEM format)"
  type        = string
  sensitive   = true
}

variable "runner_groups" {
  description = "Runner scale set configurations"
  type = map(object({
    min_runners   = number
    max_runners   = number
    runner_group  = string
    labels        = list(string)
    node_selector = map(string)
    tolerations = list(object({
      key      = string
      operator = string
      value    = string
      effect   = string
    }))
    resources = object({
      cpu_request    = string
      cpu_limit      = string
      memory_request = string
      memory_limit   = string
    })
    container_mode = string
  }))
  default = {
    "default" = {
      min_runners   = 1
      max_runners   = 10
      runner_group  = "default"
      labels        = ["self-hosted", "linux", "x64"]
      node_selector = {}
      tolerations   = []
      resources = {
        cpu_request    = "500m"
        cpu_limit      = "2000m"
        memory_request = "1Gi"
        memory_limit   = "4Gi"
      }
      container_mode = "dind"
    }
  }
}

variable "controller_replicas" {
  description = "Number of controller replicas"
  type        = number
  default     = 2
}

variable "acr_login_server" {
  description = "Azure Container Registry login server for custom runner images"
  type        = string
  default     = ""
}

variable "custom_runner_image" {
  description = "Custom runner image (if not using default)"
  type        = string
  default     = ""
}

variable "azure_credentials" {
  description = "Azure credentials for runners (workload identity)"
  type = object({
    client_id       = string
    tenant_id       = string
    subscription_id = string
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
