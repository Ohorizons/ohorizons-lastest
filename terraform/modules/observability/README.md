# Observability Module

Azure Managed Prometheus and Grafana with Container Insights integration.

## Features

- Azure Monitor Workspace (Managed Prometheus)
- Azure Managed Grafana
- Container Insights
- Prometheus recording rules
- Prometheus alert rules
- Data collection rules for AKS
- Action groups for notifications
- Pre-built Grafana dashboards
- DORA metrics recording rules

## Usage

```hcl
module "observability" {
  source = "./modules/observability"

  customer_name       = "threehorizons"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  aks_cluster_id = module.aks.cluster_id

  # Grafana RBAC
  grafana_admin_group_id  = var.grafana_admin_group_id
  grafana_viewer_group_id = var.grafana_viewer_group_id

  # Container Insights
  enable_container_insights = true
  retention_days            = 30

  # Alert recipients
  alert_email_receivers = [
    "platform-team@example.com",
    "oncall@example.com"
  ]

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
| kubernetes | ~> 2.23 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| aks_cluster_id | AKS cluster ID | `string` | n/a | yes |
| grafana_admin_group_id | Azure AD group for Grafana admins | `string` | n/a | yes |
| grafana_viewer_group_id | Azure AD group for Grafana viewers | `string` | `""` | no |
| enable_container_insights | Enable Container Insights | `bool` | `true` | no |
| retention_days | Log retention days | `number` | `30` | no |
| log_analytics_workspace_id | Existing Log Analytics workspace | `string` | `""` | no |
| alert_email_receivers | Email addresses for alerts | `list(string)` | `[]` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| prometheus_workspace_id | Azure Monitor workspace ID |
| grafana_id | Grafana instance ID |
| grafana_endpoint | Grafana endpoint URL |
| log_analytics_workspace_id | Log Analytics workspace ID |
| action_group_id | Action group ID for alerts |
| data_collection_rule_id | DCR ID for Prometheus |

## Recording Rules

Pre-configured recording rules:
- `node:node_cpu_utilization:avg1m` - Node CPU usage
- `node:node_memory_utilization:ratio` - Node memory usage
- `namespace:container_cpu_usage_seconds_total:sum_rate` - Namespace CPU
- `namespace:container_memory_working_set_bytes:sum` - Namespace memory
- `deployment:deployment_frequency:count_per_day` - DORA deployment frequency

## Alert Rules

Pre-configured alerts:
- **NodeHighCPU**: Node CPU > 85% for 5 minutes
- **NodeHighMemory**: Node memory > 85% for 5 minutes
- **PodCrashLooping**: Pod restarted > 5 times in 1 hour
- **PodNotReady**: Pod pending/unknown for 15 minutes
- **DeploymentReplicasMismatch**: Desired != available replicas
- **PVCAlmostFull**: PVC > 85% full
- **CertificateExpiringSoon**: Certificate expires in < 7 days

## Grafana Dashboards

Built-in dashboards:
- **Cluster Overview**: Node CPU, memory, pod counts, restarts
- **Golden Path Applications**: Request rate, latency, error rate
