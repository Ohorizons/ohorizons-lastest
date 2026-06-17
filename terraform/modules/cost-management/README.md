# Cost Management Module

Azure Cost Management configuration with budgets, alerts, and cost exports.

## Features

- Resource group budgets with multi-threshold alerts
- Subscription-level budgets (optional)
- Cost anomaly detection
- Cost exports to storage account
- Action groups for notifications
- Azure Advisor cost recommendations
- Custom cost alerts via scheduled queries

## Usage

```hcl
module "cost_management" {
  source = "./modules/cost-management"

  customer_name       = "openhorizons"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  monthly_budget = 10000
  cost_center    = "platform-engineering"

  alert_email_addresses = [
    "platform-team@example.com",
    "finance@example.com"
  ]

  # Optional subscription budget
  create_subscription_budget     = true
  subscription_monthly_budget    = 50000

  # Cost exports
  enable_cost_export = true
  export_recurrence  = "Daily"

  # Custom cost alerts
  enable_custom_cost_alerts = true

  # Action groups for alerts
  create_action_group = true
  webhook_urls        = ["https://teams.webhook.url"]

  budget_filter_tags = {
    Environment = ["prod"]
    Project     = ["open-horizons"]
  }

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| monthly_budget | Monthly budget in USD | `number` | n/a | yes |
| cost_center | Cost center tag | `string` | n/a | yes |
| alert_email_addresses | Email addresses for alerts | `list(string)` | n/a | yes |
| create_subscription_budget | Create subscription budget | `bool` | `false` | no |
| subscription_monthly_budget | Subscription budget in USD | `number` | `0` | no |
| enable_cost_export | Enable cost export | `bool` | `true` | no |
| export_recurrence | Export frequency (Daily, Weekly, Monthly) | `string` | `"Daily"` | no |
| enable_custom_cost_alerts | Enable custom cost alerts | `bool` | `false` | no |
| create_action_group | Create action group | `bool` | `true` | no |
| action_group_ids | Existing action group IDs | `list(string)` | `[]` | no |
| webhook_urls | Webhook URLs for alerts | `list(string)` | `[]` | no |
| budget_filter_tags | Tags to filter budget scope | `map(list(string))` | `{}` | no |
| budget_end_date | Budget end date | `string` | `"2030-12-31T00:00:00Z"` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| budget_id | Resource group budget ID |
| subscription_budget_id | Subscription budget ID |
| anomaly_alert_id | Cost anomaly alert ID |
| action_group_id | Action group ID |
| cost_export_storage_account | Storage account for cost exports |
| advisor_recommendations | Azure Advisor cost recommendations |

## Alert Thresholds

Pre-configured budget notifications:
- **50%**: Informational - halfway through budget
- **80%**: Warning - approaching budget limit
- **90%**: Critical - near budget exhaustion
- **100%**: Exceeded - budget exceeded
- **100% Forecasted**: Proactive - projected to exceed

## Cost Anomaly Detection

Automatically detects unusual spending patterns and sends alerts when anomalies are identified.

## Cost Exports

When enabled, creates a storage account and exports:
- Actual costs (month-to-date)
- Exported daily/weekly/monthly to blob storage
- Data available for Power BI or custom analysis
