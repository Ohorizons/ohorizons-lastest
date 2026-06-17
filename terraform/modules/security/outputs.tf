output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "keyvault_name" {
  description = "Key Vault name (alias)"
  value       = azurerm_key_vault.main.name
}

output "keyvault_uri" {
  description = "Key Vault URI (alias)"
  value       = azurerm_key_vault.main.vault_uri
}

output "workload_identity_client_ids" {
  description = "Workload identity client IDs"
  value = {
    for name, identity in azurerm_user_assigned_identity.workload : name => identity.client_id
  }
}

output "workload_identity_principal_ids" {
  description = "Workload identity principal IDs"
  value = {
    for name, identity in azurerm_user_assigned_identity.workload : name => identity.principal_id
  }
}

output "external_secrets_client_id" {
  description = "External Secrets Operator client ID"
  value       = azurerm_user_assigned_identity.external_secrets.client_id
}

output "aad_application_id" {
  description = "Azure AD application ID for SSO"
  value       = azuread_application.github_sso.client_id
}

output "aad_tenant_id" {
  description = "Azure AD tenant ID"
  value       = var.tenant_id
}

output "private_endpoint_ip" {
  description = "Key Vault private endpoint IP"
  value       = azurerm_private_endpoint.key_vault.private_service_connection[0].private_ip_address
}
