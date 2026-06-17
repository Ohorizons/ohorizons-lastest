# =============================================================================
# OPEN HORIZONS PLATFORM - SECURITY TERRAFORM MODULE
# =============================================================================
#
# Deploys security infrastructure for the platform.
#
# Components:
#   - Azure Key Vault with RBAC
#   - User-assigned managed identities
#   - Workload identity for AKS
#   - Role assignments
#
# =============================================================================

# NOTE: Terraform block is in versions.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}-${var.environment}"

  common_tags = merge(var.tags, {
    "open-horizons/customer"    = var.customer_name
    "open-horizons/environment" = var.environment
    "open-horizons/component"   = "security"
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}

# =============================================================================
# KEY VAULT
# =============================================================================

resource "azurerm_key_vault" "main" {
  name                = substr("kv-${local.name_prefix}", 0, 24)
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name = var.key_vault_config.sku_name

  soft_delete_retention_days = var.key_vault_config.soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_config.purge_protection_enabled
  enable_rbac_authorization  = var.key_vault_config.enable_rbac_authorization

  public_network_access_enabled = var.key_vault_config.public_network_access_enabled

  network_acls {
    bypass                     = var.key_vault_config.network_acls.bypass
    default_action             = var.key_vault_config.network_acls.default_action
    ip_rules                   = var.key_vault_config.network_acls.ip_rules
    virtual_network_subnet_ids = var.key_vault_config.network_acls.virtual_network_subnet_ids
  }

  tags = local.common_tags
}

# Key Vault Private Endpoint
resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-kv-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = local.common_tags
}

# Key Vault Administrator role for admin group
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_group_id
}

# Key Vault Administrator role for current deployment identity
resource "azurerm_role_assignment" "kv_admin_deployer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# =============================================================================
# USER-ASSIGNED MANAGED IDENTITIES
# =============================================================================

resource "azurerm_user_assigned_identity" "workload" {
  for_each = var.workload_identities

  name                = "id-${each.key}-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# Key Vault role assignments for workload identities
resource "azurerm_role_assignment" "workload_kv" {
  for_each = var.workload_identities

  scope                = azurerm_key_vault.main.id
  role_definition_name = each.value.key_vault_role
  principal_id         = azurerm_user_assigned_identity.workload[each.key].principal_id
}

# Additional role assignments for workload identities
resource "azurerm_role_assignment" "workload_additional" {
  for_each = {
    for item in flatten([
      for name, identity in var.workload_identities : [
        for idx, assignment in identity.additional_role_assignments : {
          key                  = "${name}-${idx}"
          principal_id         = azurerm_user_assigned_identity.workload[name].principal_id
          scope                = assignment.scope
          role_definition_name = assignment.role_definition_name
        }
      ]
    ]) : item.key => item
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# =============================================================================
# FEDERATED IDENTITY CREDENTIALS (Workload Identity)
# =============================================================================

resource "azurerm_federated_identity_credential" "workload" {
  for_each = var.workload_identities

  name                = "federated-${each.key}"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload[each.key].id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.aks_oidc_issuer_url
  subject  = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}

# =============================================================================
# EXTERNAL SECRETS OPERATOR IDENTITY (for cluster-wide secret management)
# =============================================================================

resource "azurerm_user_assigned_identity" "external_secrets" {
  name                = "id-external-secrets-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

resource "azurerm_role_assignment" "external_secrets_kv" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.external_secrets.principal_id
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  name                = "federated-external-secrets"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.external_secrets.id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.aks_oidc_issuer_url
  subject  = "system:serviceaccount:external-secrets:external-secrets"
}

# =============================================================================
# AZURE AD APPLICATION FOR GITHUB SSO (Optional)
# =============================================================================

resource "azuread_application" "github_sso" {
  display_name = "GitHub-SSO-${local.name_prefix}"

  web {
    redirect_uris = [
      "https://argocd.${var.customer_name}.com/api/dex/callback",
      "https://backstage.${var.customer_name}.com/api/auth/microsoft/handler/frame"
    ]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }

    resource_access {
      id   = "5f8c59db-677d-491f-a6b8-5f174b11ec1d" # Group.Read.All
      type = "Scope"
    }
  }

  group_membership_claims = ["SecurityGroup"]

  optional_claims {
    id_token {
      name = "groups"
    }
  }

  tags = ["open-horizons", var.environment]
}

resource "azuread_service_principal" "github_sso" {
  client_id = azuread_application.github_sso.client_id

  app_role_assignment_required = false

  tags = ["open-horizons", var.environment]
}

resource "azuread_application_password" "github_sso" {
  application_id = azuread_application.github_sso.id
  display_name   = "GitHub SSO Secret"
  end_date       = timeadd(timestamp(), "8760h") # 1 year

  lifecycle {
    ignore_changes = [end_date]
  }
}

# Store Azure AD app credentials in Key Vault
resource "azurerm_key_vault_secret" "aad_client_id" {
  name         = "aad-client-id"
  value        = azuread_application.github_sso.client_id
  key_vault_id = azurerm_key_vault.main.id

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.kv_admin_deployer]
}

resource "azurerm_key_vault_secret" "aad_client_secret" {
  name         = "aad-client-secret"
  value        = azuread_application_password.github_sso.value
  key_vault_id = azurerm_key_vault.main.id

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.kv_admin_deployer]
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "kv-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.tags["log_analytics_workspace_id"] != null ? var.tags["log_analytics_workspace_id"] : null

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================


