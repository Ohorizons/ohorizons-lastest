# =============================================================================
# OPEN HORIZONS PLATFORM - COST MANAGEMENT MODULE
# =============================================================================
#
# Azure Cost Management configuration including:
#   - Resource group budgets with alerts
#   - Subscription-level budgets
#   - Cost anomaly detection
#   - Cost exports for analysis
#   - Azure Advisor recommendations
#
# =============================================================================

# -----------------------------------------------------------------------------
# LOCAL VALUES
# -----------------------------------------------------------------------------

locals {
  budget_name  = "budget-${var.customer_name}-${var.environment}"
  export_name  = "export-${var.customer_name}-${var.environment}"
  alert_emails = var.alert_email_addresses

  # Calculate budget thresholds
  warning_threshold  = var.monthly_budget * 0.8
  critical_threshold = var.monthly_budget * 0.9
  exceeded_threshold = var.monthly_budget * 1.0

  common_tags = {
    "app.kubernetes.io/managed-by" = "terraform"
    "platform.open-horizons/tier" = "operations"
    "cost-center"                  = var.cost_center
  }
}

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# -----------------------------------------------------------------------------
# RESOURCE GROUP BUDGET
# -----------------------------------------------------------------------------

resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "${local.budget_name}-rg"
  resource_group_id = data.azurerm_resource_group.main.id
  amount            = var.monthly_budget
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = var.budget_end_date
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        var.resource_group_name
      ]
    }

    dynamic "tag" {
      for_each = var.budget_filter_tags
      content {
        name   = tag.key
        values = tag.value
      }
    }
  }

  # 50% threshold - informational
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = local.alert_emails

    contact_groups = var.action_group_ids
  }

  # 80% threshold - warning
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = local.alert_emails

    contact_groups = var.action_group_ids
  }

  # 90% threshold - critical
  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = local.alert_emails

    contact_groups = var.action_group_ids
  }

  # 100% threshold - exceeded
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = local.alert_emails

    contact_groups = var.action_group_ids
  }

  # Forecasted 100% - proactive alert
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = local.alert_emails

    contact_groups = var.action_group_ids
  }

  lifecycle {
    ignore_changes = [
      time_period[0].start_date
    ]
  }
}

# -----------------------------------------------------------------------------
# SUBSCRIPTION BUDGET (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_consumption_budget_subscription" "main" {
  count = var.create_subscription_budget ? 1 : 0

  name            = "${local.budget_name}-subscription"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.subscription_monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = var.budget_end_date
  }

  filter {
    tag {
      name   = "project"
      values = [var.customer_name]
    }
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = local.alert_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = local.alert_emails
  }

  lifecycle {
    ignore_changes = [
      time_period[0].start_date
    ]
  }
}

# -----------------------------------------------------------------------------
# COST ANOMALY ALERT
# -----------------------------------------------------------------------------

resource "azurerm_cost_anomaly_alert" "main" {
  name            = "anomaly-${var.customer_name}-${var.environment}"
  display_name    = "Cost Anomaly Alert - ${var.customer_name} ${var.environment}"
  email_addresses = local.alert_emails
  email_subject   = "[Azure] Cost Anomaly Detected - ${var.customer_name}"
  message         = "A cost anomaly has been detected for ${var.customer_name} ${var.environment} environment. Please review Azure Cost Management for details."
}

# -----------------------------------------------------------------------------
# COST EXPORT (to Storage Account)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "cost_export" {
  count = var.enable_cost_export ? 1 : 0

  name                     = "st${replace(var.customer_name, "-", "")}cost${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "cost_export" {
  count = var.enable_cost_export ? 1 : 0

  name                  = "cost-exports"
  storage_account_name  = azurerm_storage_account.cost_export[0].name
  container_access_type = "private"
}

resource "azurerm_resource_group_cost_management_export" "main" {
  count = var.enable_cost_export ? 1 : 0

  name                         = local.export_name
  resource_group_id            = data.azurerm_resource_group.main.id
  recurrence_type              = var.export_recurrence
  recurrence_period_start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  recurrence_period_end_date   = var.budget_end_date

  export_data_storage_location {
    container_id     = azurerm_storage_container.cost_export[0].resource_manager_id
    root_folder_path = "/${var.customer_name}/${var.environment}"
  }

  export_data_options {
    type       = "ActualCost"
    time_frame = "MonthToDate"
  }

  lifecycle {
    ignore_changes = [
      recurrence_period_start_date
    ]
  }
}

# -----------------------------------------------------------------------------
# ACTION GROUP FOR BUDGET ALERTS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_action_group" "cost_alerts" {
  count = var.create_action_group ? 1 : 0

  name                = "ag-${var.customer_name}-${var.environment}-cost"
  resource_group_name = var.resource_group_name
  short_name          = "CostAlerts"

  dynamic "email_receiver" {
    for_each = local.alert_emails
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_urls
    content {
      name                    = "webhook-${webhook_receiver.key}"
      service_uri             = webhook_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "azure_function_receiver" {
    for_each = var.azure_function_id != null ? [1] : []
    content {
      name                     = "function-cost-handler"
      function_app_resource_id = var.azure_function_id
      function_name            = "CostAlertHandler"
      http_trigger_url         = var.azure_function_url
      use_common_alert_schema  = true
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# AZURE ADVISOR RECOMMENDATIONS (Read-only data source)
# -----------------------------------------------------------------------------

data "azurerm_advisor_recommendations" "cost" {
  filter_by_category        = ["Cost"]
  filter_by_resource_groups = [var.resource_group_name]
}

# -----------------------------------------------------------------------------
# SCHEDULED QUERY RULE FOR CUSTOM COST ALERTS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_cost_resources" {
  count = var.enable_custom_cost_alerts ? 1 : 0

  name                = "alert-${var.customer_name}-${var.environment}-high-cost"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Alert when specific resources exceed cost thresholds"
  severity            = 2
  enabled             = true

  evaluation_frequency = "PT1H"
  window_duration      = "PT1H"
  scopes               = [data.azurerm_resource_group.main.id]

  criteria {
    query = <<-QUERY
      AzureActivity
      | where OperationNameValue contains "Microsoft.CostManagement"
      | summarize count() by Resource
      | where count_ > 100
    QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = var.create_action_group ? [azurerm_monitor_action_group.cost_alerts[0].id] : var.action_group_ids
  }

  tags = var.tags
}
