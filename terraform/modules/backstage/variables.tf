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

# --- Open Horizons Backstage distribution image ---
# The runtime image is the Open Horizons distribution of Backstage OSS: the
# upstream Backstage app built with the Open Horizons custom plugins and pages,
# then published to a registry under a pinned, immutable tag. Never deploy
# `latest` in any environment.
variable "image_registry" {
  description = "Container registry that hosts the Open Horizons Backstage distribution image (for example ghcr.io/ohorizons)"
  type        = string
  default     = ""
}

variable "image_repository" {
  description = "Image repository name for the Open Horizons Backstage distribution (for example ohorizons-backstage)"
  type        = string
}

variable "image_tag" {
  description = "Pinned, immutable image tag for the Open Horizons Backstage distribution (for example v7.2.4). Mutable tags such as 'latest' are rejected."
  type        = string
  default     = "v7.2.4"

  validation {
    condition     = var.image_tag != "" && var.image_tag != "latest"
    error_message = "image_tag must be a pinned, immutable tag (for example v7.2.4). The mutable tag 'latest' is not allowed in any environment."
  }
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
