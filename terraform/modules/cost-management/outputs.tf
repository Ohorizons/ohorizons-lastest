# =============================================================================
# COST MANAGEMENT MODULE - OUTPUTS
# =============================================================================

output "resource_group_budget_id" {
  value       = azurerm_consumption_budget_resource_group.main.id
  description = "Resource ID of the resource group budget"
}

output "resource_group_budget_name" {
  value       = azurerm_consumption_budget_resource_group.main.name
  description = "Name of the resource group budget"
}

output "subscription_budget_id" {
  value       = var.create_subscription_budget ? azurerm_consumption_budget_subscription.main[0].id : null
  description = "Resource ID of the subscription budget"
}

output "cost_anomaly_alert_id" {
  value       = azurerm_cost_anomaly_alert.main.id
  description = "Resource ID of the cost anomaly alert"
}

output "action_group_id" {
  value       = var.create_action_group ? azurerm_monitor_action_group.cost_alerts[0].id : null
  description = "Resource ID of the cost alert Action Group"
}

output "cost_export_storage_account_name" {
  value       = var.enable_cost_export ? azurerm_storage_account.cost_export[0].name : null
  description = "Name of the storage account for cost exports"
}

output "cost_export_container_name" {
  value       = var.enable_cost_export ? azurerm_storage_container.cost_export[0].name : null
  description = "Name of the container for cost exports"
}

output "cost_export_id" {
  value       = var.enable_cost_export ? azurerm_resource_group_cost_management_export.main[0].id : null
  description = "Resource ID of the cost export"
}

output "advisor_recommendations" {
  value = {
    for rec in data.azurerm_advisor_recommendations.cost.recommendations :
    rec.recommendation_name => {
      category    = rec.category
      impact      = rec.impact
      description = rec.description
      resource_id = rec.resource_id
      suppressed  = rec.suppression_ids
    }
  }
  description = "Azure Advisor cost recommendations"
}

output "monthly_budget_amount" {
  value       = var.monthly_budget
  description = "Configured monthly budget amount"
}

output "alert_thresholds" {
  value = {
    warning  = var.monthly_budget * 0.8
    critical = var.monthly_budget * 0.9
    exceeded = var.monthly_budget
  }
  description = "Budget alert thresholds"
}
