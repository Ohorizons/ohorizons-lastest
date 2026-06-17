output "openai_id" {
  description = "Azure OpenAI account ID"
  value       = var.openai_config.enabled ? azurerm_cognitive_account.openai[0].id : null
}

output "openai_endpoint" {
  description = "Azure OpenAI endpoint"
  value       = var.openai_config.enabled ? azurerm_cognitive_account.openai[0].endpoint : null
}

output "openai_principal_id" {
  description = "Azure OpenAI managed identity principal ID"
  value       = var.openai_config.enabled ? azurerm_cognitive_account.openai[0].identity[0].principal_id : null
}

output "openai_deployments" {
  description = "Azure OpenAI model deployments"
  value = var.openai_config.enabled ? {
    for name, deployment in azurerm_cognitive_deployment.models : name => {
      id   = deployment.id
      name = deployment.name
    }
  } : {}
}

output "search_id" {
  description = "Azure AI Search ID"
  value       = var.ai_search_config.enabled ? azurerm_search_service.main[0].id : null
}

output "search_endpoint" {
  description = "Azure AI Search endpoint"
  value       = var.ai_search_config.enabled ? "https://${azurerm_search_service.main[0].name}.search.windows.net" : null
}

output "search_principal_id" {
  description = "Azure AI Search managed identity principal ID"
  value       = var.ai_search_config.enabled ? azurerm_search_service.main[0].identity[0].principal_id : null
}

output "content_safety_id" {
  description = "Azure AI Content Safety ID"
  value       = var.content_safety_config.enabled ? azurerm_cognitive_account.content_safety[0].id : null
}

output "content_safety_endpoint" {
  description = "Azure AI Content Safety endpoint"
  value       = var.content_safety_config.enabled ? azurerm_cognitive_account.content_safety[0].endpoint : null
}

output "private_endpoint_ips" {
  description = "Private endpoint IPs"
  value = {
    openai         = var.openai_config.enabled ? azurerm_private_endpoint.openai[0].private_service_connection[0].private_ip_address : null
    search         = var.ai_search_config.enabled ? azurerm_private_endpoint.search[0].private_service_connection[0].private_ip_address : null
    content_safety = var.content_safety_config.enabled ? azurerm_private_endpoint.content_safety[0].private_service_connection[0].private_ip_address : null
  }
}

output "key_vault_secrets" {
  description = "Key Vault secret names"
  value = {
    openai_endpoint         = var.openai_config.enabled ? azurerm_key_vault_secret.openai_endpoint[0].name : null
    openai_key              = var.openai_config.enabled ? azurerm_key_vault_secret.openai_key[0].name : null
    search_endpoint         = var.ai_search_config.enabled ? azurerm_key_vault_secret.search_endpoint[0].name : null
    search_admin_key        = var.ai_search_config.enabled ? azurerm_key_vault_secret.search_admin_key[0].name : null
    content_safety_endpoint = var.content_safety_config.enabled ? azurerm_key_vault_secret.content_safety_endpoint[0].name : null
    content_safety_key      = var.content_safety_config.enabled ? azurerm_key_vault_secret.content_safety_key[0].name : null
  }
}
