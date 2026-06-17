# =============================================================================
# OPEN HORIZONS PLATFORM - VARIABLES
# =============================================================================
#
# All input variables for the platform. Use a .tfvars file to set values:
#   terraform plan -var-file=environments/dev.tfvars
#
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED — Must be provided via .tfvars or -var flags
# -----------------------------------------------------------------------------

variable "customer_name" {
  description = "Customer name for resource naming (lowercase, no spaces, 3-20 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.customer_name))
    error_message = "Customer name must be 3-20 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure AD / Entra ID tenant ID"
  type        = string
}

variable "admin_group_id" {
  description = "Azure AD group ID for platform administrators"
  type        = string
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token (set via TF_VAR_github_token or -var)"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Base domain name for the platform (e.g. platform.contoso.com)"
  type        = string
  default     = "internal.local"
}

# -----------------------------------------------------------------------------
# DEPLOYMENT MODE — Controls sizing and feature defaults
# -----------------------------------------------------------------------------

variable "deployment_mode" {
  description = "Deployment mode: express (minimal/dev), standard (production), enterprise (HA/multi-zone)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["express", "standard", "enterprise"], var.deployment_mode)
    error_message = "Deployment mode must be express, standard, or enterprise."
  }
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "brazilsouth"
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# H1 FOUNDATION — Feature flags
# -----------------------------------------------------------------------------

variable "enable_defender" {
  description = "Enable Microsoft Defender for Cloud"
  type        = bool
  default     = false
}

variable "enable_purview" {
  description = "Enable Microsoft Purview for data governance"
  type        = bool
  default     = false
}

variable "enable_container_registry" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = true
}

variable "enable_databases" {
  description = "Enable databases (PostgreSQL + Redis)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# H2 ENHANCEMENT — Feature flags
# -----------------------------------------------------------------------------

variable "enable_argocd" {
  description = "Deploy ArgoCD for GitOps"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Deploy External Secrets Operator"
  type        = bool
  default     = true
}

variable "enable_observability" {
  description = "Deploy observability stack (Prometheus, Grafana, Azure Monitor)"
  type        = bool
  default     = true
}

variable "enable_github_runners" {
  description = "Deploy self-hosted GitHub Actions runners on AKS"
  type        = bool
  default     = false
}

variable "enable_cost_management" {
  description = "Enable cost management module (budgets and alerts)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# H3 INNOVATION — Feature flags
# -----------------------------------------------------------------------------

variable "enable_ai_foundry" {
  description = "Enable Azure AI Foundry (OpenAI, AI Search, Content Safety)"
  type        = bool
  default     = false
}

variable "ai_foundry_location" {
  description = "Azure region for AI Foundry (use eastus2 for best model availability)"
  type        = string
  default     = "eastus2"
}

# -----------------------------------------------------------------------------
# PLATFORM — Disaster Recovery
# -----------------------------------------------------------------------------

variable "enable_disaster_recovery" {
  description = "Enable disaster recovery configuration"
  type        = bool
  default     = false
}

variable "dr_location" {
  description = "Azure region for disaster recovery"
  type        = string
  default     = "eastus2"
}

# -----------------------------------------------------------------------------
# Backstage Components — runtime toggles for plugins and agent APIs
# -----------------------------------------------------------------------------

variable "enable_ai_chat_plugin" {
  description = "Enable the Backstage AI Chat plugin in the portal UI."
  type        = bool
  default     = true
}

variable "enable_agent_api" {
  description = "Enable the AI Chat backend (agent-api). Required by enable_ai_chat_plugin."
  type        = bool
  default     = true
}

variable "enable_agent_api_impact" {
  description = "Enable the Agentic DevOps impact analytics runtime (agent-api-impact)."
  type        = bool
  default     = false
}

variable "enable_agent_api_maf" {
  description = "Enable the Microsoft Agent Framework reference runtime (agent-api-maf)."
  type        = bool
  default     = false
}

variable "enable_agent_api_sk" {
  description = "Enable the Semantic Kernel reference runtime (agent-api-sk)."
  type        = bool
  default     = false
}

variable "enable_mcp_ecosystem" {
  description = "Enable the MCP ecosystem deployment that exposes the 12 MCP servers."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# ArgoCD — Required when enable_argocd = true
# -----------------------------------------------------------------------------

variable "argocd_admin_password" {
  description = "ArgoCD admin password (bcrypt hash). Generate: htpasswd -nbBC 10 '' 'password' | tr -d ':'"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app_id" {
  description = "GitHub App ID for ArgoCD/Backstage authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app_client_id" {
  description = "GitHub App Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app_client_secret" {
  description = "GitHub App Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID for self-hosted runners"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_app_private_key" {
  description = "GitHub App Private Key (PEM format) for self-hosted runners"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Cost Management — Required when enable_cost_management = true
# -----------------------------------------------------------------------------

variable "budget_amount" {
  description = "Monthly budget in USD"
  type        = number
  default     = 5000
}

variable "alert_emails" {
  description = "Email addresses for cost and platform alerts"
  type        = list(string)
  default     = []
}