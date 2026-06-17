output "defender_status" {
  description = "Defender for Cloud pricing status by resource type"
  value = {
    cspm       = local.current_pricing.cspm
    containers = local.current_pricing.containers
    servers    = "${local.current_pricing.servers} (${local.current_pricing.servers_plan != null ? local.current_pricing.servers_plan : "N/A"})"
  }
}

output "compliance_standards" {
  description = "Enabled regulatory compliance standards"
  value       = local.effective_compliance
}

output "security_contact" {
  description = "Security contact email"
  value       = var.security_contact_email
}

output "sizing_profile" {
  description = "Active sizing profile"
  value       = var.sizing_profile
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost range"
  value = {
    small  = "$100-200"
    medium = "$500-1,000"
    large  = "$2,000-3,000"
  }
}

output "continuous_export_id" {
  description = "Continuous export automation ID"
  value       = azurerm_security_center_automation.export_to_log_analytics.id
}

output "workspace_id" {
  description = "Log Analytics workspace ID for Defender"
  value       = azurerm_log_analytics_workspace.defender.id
}
