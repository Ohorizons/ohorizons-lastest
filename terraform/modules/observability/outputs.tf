output "prometheus_workspace_id" {
  description = "Azure Monitor workspace ID"
  value       = azurerm_monitor_workspace.prometheus.id
}

output "prometheus_query_endpoint" {
  description = "Prometheus query endpoint"
  value       = azurerm_monitor_workspace.prometheus.query_endpoint
}

output "grafana_id" {
  description = "Azure Managed Grafana ID"
  value       = azurerm_dashboard_grafana.main.id
}

output "grafana_endpoint" {
  description = "Grafana endpoint URL"
  value       = azurerm_dashboard_grafana.main.endpoint
}

output "grafana_identity_principal_id" {
  description = "Grafana managed identity principal ID"
  value       = azurerm_dashboard_grafana.main.identity[0].principal_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = var.enable_container_insights ? (var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.main[0].id) : null
}

output "data_collection_rule_id" {
  description = "Prometheus data collection rule ID"
  value       = azurerm_monitor_data_collection_rule.prometheus.id
}
