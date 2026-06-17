output "postgresql_server_id" {
  description = "PostgreSQL server ID"
  value       = var.postgresql_config.enabled ? azurerm_postgresql_flexible_server.main[0].id : null
}

output "postgresql_server_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = var.postgresql_config.enabled ? azurerm_postgresql_flexible_server.main[0].fqdn : null
}

output "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  value       = var.postgresql_config.enabled ? var.postgresql_config.admin_username : null
}

output "postgresql_databases" {
  description = "Created PostgreSQL databases"
  value       = var.postgresql_config.enabled ? var.postgresql_config.databases : []
}

output "redis_id" {
  description = "Redis cache ID"
  value       = var.redis_config.enabled ? azurerm_redis_cache.main[0].id : null
}

output "redis_hostname" {
  description = "Redis hostname"
  value       = var.redis_config.enabled ? azurerm_redis_cache.main[0].hostname : null
}

output "redis_ssl_port" {
  description = "Redis SSL port"
  value       = var.redis_config.enabled ? azurerm_redis_cache.main[0].ssl_port : null
}

output "redis_private_ip" {
  description = "Redis private endpoint IP"
  value       = var.redis_config.enabled ? azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address : null
}

output "key_vault_secret_names" {
  description = "Names of secrets stored in Key Vault"
  value = {
    postgresql_connection_string = var.postgresql_config.enabled ? azurerm_key_vault_secret.postgresql_connection_string[0].name : null
    postgresql_password          = var.postgresql_config.enabled ? azurerm_key_vault_secret.postgresql_password[0].name : null
    redis_connection_string      = var.redis_config.enabled ? azurerm_key_vault_secret.redis_connection_string[0].name : null
    redis_primary_key            = var.redis_config.enabled ? azurerm_key_vault_secret.redis_primary_key[0].name : null
  }
}

output "server_name" {
  description = "Database server name"
  value       = var.postgresql_config.enabled ? azurerm_postgresql_flexible_server.main[0].name : null
}

output "server_fqdn" {
  description = "Database server FQDN"
  value       = var.postgresql_config.enabled ? azurerm_postgresql_flexible_server.main[0].fqdn : null
}

output "connection_string" {
  description = "Database connection string"
  value       = var.postgresql_config.enabled ? "postgresql://${var.postgresql_config.admin_username}@${azurerm_postgresql_flexible_server.main[0].name}:@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/${var.postgresql_config.databases[0]}?sslmode=require" : null
  sensitive   = true
}
