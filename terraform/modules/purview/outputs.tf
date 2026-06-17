output "purview_account_id" {
  description = "Purview account ID"
  value       = azurerm_purview_account.main.id
}

output "purview_account_name" {
  description = "Purview account name"
  value       = azurerm_purview_account.main.name
}

output "purview_catalog_endpoint" {
  description = "Purview catalog endpoint"
  value       = azurerm_purview_account.main.catalog_endpoint
}

output "purview_guardian_endpoint" {
  description = "Purview guardian (scan) endpoint"
  value       = azurerm_purview_account.main.guardian_endpoint
}

output "purview_identity_principal_id" {
  description = "Purview managed identity principal ID"
  value       = azurerm_purview_account.main.identity[0].principal_id
}

output "purview_identity_tenant_id" {
  description = "Purview managed identity tenant ID"
  value       = azurerm_purview_account.main.identity[0].tenant_id
}

output "latam_classifications_enabled" {
  description = "LATAM classifications enabled"
  value       = var.enable_latam_classifications ? keys(local.latam_classifications) : []
}

output "collections" {
  description = "Created collections"
  value       = [for coll in var.collection_hierarchy : coll.name]
}

output "sizing_profile" {
  description = "Active sizing profile"
  value       = var.sizing_profile
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost range"
  value = {
    small  = "$0-100"
    medium = "$500-800"
    large  = "$2,000-3,000"
  }
}

output "portal_url" {
  description = "Purview governance portal URL"
  value       = "https://${local.purview_name}.purview.azure.com"
}
