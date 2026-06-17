# =============================================================================
# BACKSTAGE MODULE — VARIABLES
# =============================================================================

variable "portal_name" {
  description = "Portal name for branding (e.g. acme-developer-portal)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Backstage"
  type        = string
  default     = "backstage"
}

variable "replicas" {
  description = "Number of Backstage replicas"
  type        = number
  default     = 1
}

variable "base_url" {
  description = "Base URL for the Backstage portal"
  type        = string
  default     = "http://localhost:7007"
}

variable "backstage_chart_version" {
  description = "Backstage Helm chart version"
  type        = string
  default     = "2.3.0"
}

# --- Custom Image ---
variable "image_registry" {
  description = "Container registry for the custom Backstage image"
  type        = string
  default     = ""
}

variable "image_repository" {
  description = "Image repository name"
  type        = string
}

variable "image_tag" {
  description = "Image tag"
  type        = string
  default     = "latest"
}

# --- Database ---
variable "database_host" {
  description = "PostgreSQL host"
  type        = string
}

variable "database_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "database_user" {
  description = "PostgreSQL user"
  type        = string
}

variable "database_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

# --- GitHub App ---
variable "github_app_id" {
  description = "GitHub App numeric ID"
  type        = string
}

variable "github_app_client_id" {
  description = "GitHub App Client ID"
  type        = string
}

variable "github_app_client_secret" {
  description = "GitHub App Client Secret"
  type        = string
  sensitive   = true
}

variable "github_app_private_key" {
  description = "GitHub App Private Key (PEM format)"
  type        = string
  sensitive   = true
}

# --- Ingress ---
variable "ingress_enabled" {
  description = "Enable ingress for external access"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Ingress hostname"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
