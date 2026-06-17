output "id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "name" {
  description = "Container Registry name"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "Container Registry admin username (if enabled)"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "identity_principal_id" {
  description = "Container Registry managed identity principal ID"
  value       = azurerm_container_registry.main.identity[0].principal_id
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address"
  value       = azurerm_private_endpoint.acr.private_service_connection[0].private_ip_address
}

output "scope_map_ids" {
  description = "Scope map IDs for token creation"
  value = {
    ci_push  = azurerm_container_registry_scope_map.ci_push.id
    readonly = azurerm_container_registry_scope_map.readonly.id
  }
}
