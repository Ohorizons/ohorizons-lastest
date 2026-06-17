# =============================================================================
# OPEN HORIZONS PLATFORM - OBSERVABILITY TERRAFORM MODULE
# =============================================================================
#
# Deploys observability stack on AKS using Azure Managed services.
#
# Components:
#   - Azure Managed Prometheus
#   - Azure Managed Grafana
#   - Container Insights
#   - Prometheus rules and alerts
#
# =============================================================================

# NOTE: Terraform block is in versions.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}-${var.environment}"

  common_tags = merge(var.tags, {
    "open-horizons/customer"    = var.customer_name
    "open-horizons/environment" = var.environment
    "open-horizons/component"   = "observability"
  })
}

# =============================================================================
# AZURE MONITOR WORKSPACE (for Managed Prometheus)
# =============================================================================

resource "azurerm_monitor_workspace" "prometheus" {
  name                = "amw-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# =============================================================================
# AZURE MANAGED GRAFANA
# =============================================================================

resource "azurerm_dashboard_grafana" "main" {
  name                  = "grafana-${local.name_prefix}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  grafana_major_version = 10

  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true
  zone_redundancy_enabled           = var.environment == "prod"

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }

  tags = local.common_tags
}

# Grafana Admin role assignment
resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.main.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_group_id
}

# Grafana Viewer role assignment (if provided)
resource "azurerm_role_assignment" "grafana_viewer" {
  count = var.grafana_viewer_group_id != "" ? 1 : 0

  scope                = azurerm_dashboard_grafana.main.id
  role_definition_name = "Grafana Viewer"
  principal_id         = var.grafana_viewer_group_id
}

# Grant Grafana access to read from Azure Monitor workspace
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.main.identity[0].principal_id
}

# =============================================================================
# DATA COLLECTION RULES (for Prometheus scraping)
# =============================================================================

resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  name                          = "dce-prometheus-${local.name_prefix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "Linux"
  public_network_access_enabled = true

  tags = local.common_tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                        = "dcr-prometheus-${local.name_prefix}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
  kind                        = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  tags = local.common_tags
}

# Associate DCR with AKS cluster
resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  name                    = "dcra-prometheus-${local.name_prefix}"
  target_resource_id      = var.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
}

# =============================================================================
# PROMETHEUS RECORDING RULES
# =============================================================================

resource "azurerm_monitor_alert_prometheus_rule_group" "recording_rules" {
  name                = "RecordingRules-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  cluster_name        = split("/", var.aks_cluster_id)[8]
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.prometheus.id]

  # Node recording rules
  rule {
    record     = "node:node_cpu_utilization:avg1m"
    expression = <<-EOT
      1 - avg by (node) (
        rate(node_cpu_seconds_total{mode="idle"}[1m])
      )
    EOT
  }

  rule {
    record     = "node:node_memory_utilization:ratio"
    expression = <<-EOT
      1 - (
        node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
      )
    EOT
  }

  # Pod recording rules
  rule {
    record     = "namespace:container_cpu_usage_seconds_total:sum_rate"
    expression = <<-EOT
      sum by (namespace) (
        rate(container_cpu_usage_seconds_total{container!=""}[5m])
      )
    EOT
  }

  rule {
    record     = "namespace:container_memory_working_set_bytes:sum"
    expression = <<-EOT
      sum by (namespace) (
        container_memory_working_set_bytes{container!=""}
      )
    EOT
  }

  # DORA metrics recording rules
  rule {
    record     = "deployment:deployment_frequency:count_per_day"
    expression = <<-EOT
      count by (namespace, deployment) (
        changes(kube_deployment_status_observed_generation[24h])
      )
    EOT
  }

  tags = local.common_tags
}

# =============================================================================
# PROMETHEUS ALERT RULES
# =============================================================================

resource "azurerm_monitor_alert_prometheus_rule_group" "alerts" {
  name                = "AlertRules-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  cluster_name        = split("/", var.aks_cluster_id)[8]
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.prometheus.id]

  # Node alerts
  rule {
    alert      = "NodeHighCPU"
    expression = "node:node_cpu_utilization:avg1m > 0.85"
    for        = "PT5M"
    severity   = 2

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "Node CPU usage is high"
      description = "Node {{ $labels.node }} CPU usage is above 85% for 5 minutes."
    }

    action {
      action_group_id = length(azurerm_monitor_action_group.alerts) > 0 ? azurerm_monitor_action_group.alerts[0].id : null
    }
  }

  rule {
    alert      = "NodeHighMemory"
    expression = "node:node_memory_utilization:ratio > 0.85"
    for        = "PT5M"
    severity   = 2

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "Node memory usage is high"
      description = "Node {{ $labels.node }} memory usage is above 85% for 5 minutes."
    }
  }

  # Pod alerts
  rule {
    alert      = "PodCrashLooping"
    expression = "increase(kube_pod_container_status_restarts_total[1h]) > 5"
    for        = "PT15M"
    severity   = 2

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "Pod is crash looping"
      description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} has restarted more than 5 times in the last hour."
    }
  }

  rule {
    alert      = "PodNotReady"
    expression = <<-EOT
      sum by (namespace, pod) (
        kube_pod_status_phase{phase=~"Pending|Unknown"}
      ) > 0
    EOT
    for        = "PT15M"
    severity   = 3

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "Pod not ready"
      description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for 15 minutes."
    }
  }

  # Deployment alerts
  rule {
    alert      = "DeploymentReplicasMismatch"
    expression = <<-EOT
      kube_deployment_spec_replicas != kube_deployment_status_replicas_available
    EOT
    for        = "PT10M"
    severity   = 2

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "Deployment replicas mismatch"
      description = "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has {{ $value }} available replicas, expected {{ $labels.replicas }}."
    }
  }

  # PVC alerts
  rule {
    alert      = "PVCAlmostFull"
    expression = <<-EOT
      (
        kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes
      ) > 0.85
    EOT
    for        = "PT5M"
    severity   = 2

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "PVC almost full"
      description = "PVC {{ $labels.persistentvolumeclaim }} in namespace {{ $labels.namespace }} is more than 85% full."
    }
  }

  # Certificate alerts
  rule {
    alert      = "CertificateExpiringSoon"
    expression = <<-EOT
      (certmanager_certificate_expiration_timestamp_seconds - time()) < 604800
    EOT
    for        = "PT1H"
    severity   = 2

    labels = {
      severity = "warning"
    }

    annotations = {
      summary     = "Certificate expiring soon"
      description = "Certificate {{ $labels.name }} in namespace {{ $labels.namespace }} expires in less than 7 days."
    }
  }

  tags = local.common_tags
}

# =============================================================================
# ACTION GROUP (for alerts)
# =============================================================================

resource "azurerm_monitor_action_group" "alerts" {
  count = length(var.alert_email_receivers) > 0 ? 1 : 0

  name                = "ag-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = substr(local.name_prefix, 0, 12)

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = local.common_tags
}

# =============================================================================
# LOG ANALYTICS WORKSPACE (if Container Insights enabled)
# =============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  count = var.enable_container_insights && var.log_analytics_workspace_id == "" ? 1 : 0

  name                = "law-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days

  tags = local.common_tags
}

# =============================================================================
# CONTAINER INSIGHTS SOLUTION
# =============================================================================

resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.main[0].id
  workspace_name        = var.log_analytics_workspace_id != "" ? split("/", var.log_analytics_workspace_id)[8] : azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = local.common_tags
}

# =============================================================================
# GRAFANA DASHBOARDS (deployed via Kubernetes ConfigMaps)
# =============================================================================

resource "kubernetes_namespace" "grafana_dashboards" {
  metadata {
    name = "grafana-dashboards"

    labels = {
      "open-horizons/component" = "observability"
    }
  }
}

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "open-horizons-dashboards"
    namespace = kubernetes_namespace.grafana_dashboards.metadata[0].name

    labels = {
      "grafana_dashboard" = "1"
    }
  }

  data = {
    "cluster-overview.json" = jsonencode({
      annotations = {
        list = []
      }
      editable     = true
      graphTooltip = 0
      id           = null
      links        = []
      panels = [
        {
          title   = "Node CPU Usage"
          type    = "timeseries"
          gridPos = { h = 8, w = 12, x = 0, y = 0 }
          targets = [
            {
              expr         = "node:node_cpu_utilization:avg1m"
              legendFormat = "{{ node }}"
            }
          ]
        },
        {
          title   = "Node Memory Usage"
          type    = "timeseries"
          gridPos = { h = 8, w = 12, x = 12, y = 0 }
          targets = [
            {
              expr         = "node:node_memory_utilization:ratio"
              legendFormat = "{{ node }}"
            }
          ]
        },
        {
          title   = "Pod Count by Namespace"
          type    = "bargauge"
          gridPos = { h = 8, w = 12, x = 0, y = 8 }
          targets = [
            {
              expr         = "count by (namespace) (kube_pod_info)"
              legendFormat = "{{ namespace }}"
            }
          ]
        },
        {
          title   = "Container Restarts"
          type    = "stat"
          gridPos = { h = 8, w = 12, x = 12, y = 8 }
          targets = [
            {
              expr = "sum(increase(kube_pod_container_status_restarts_total[24h]))"
            }
          ]
        }
      ]
      schemaVersion = 38
      tags          = ["kubernetes", "open-horizons"]
      templating    = { list = [] }
      time          = { from = "now-6h", to = "now" }
      title         = "Open Horizons - Cluster Overview"
      uid           = "open-horizons-cluster"
    })

    "golden-path-apps.json" = jsonencode({
      annotations = {
        list = []
      }
      editable     = true
      graphTooltip = 0
      id           = null
      links        = []
      panels = [
        {
          title   = "Request Rate by Service"
          type    = "timeseries"
          gridPos = { h = 8, w = 12, x = 0, y = 0 }
          targets = [
            {
              expr         = "sum by (service) (rate(http_requests_total[5m]))"
              legendFormat = "{{ service }}"
            }
          ]
        },
        {
          title   = "Response Latency (p95)"
          type    = "timeseries"
          gridPos = { h = 8, w = 12, x = 12, y = 0 }
          targets = [
            {
              expr         = "histogram_quantile(0.95, sum by (service, le) (rate(http_request_duration_seconds_bucket[5m])))"
              legendFormat = "{{ service }}"
            }
          ]
        },
        {
          title   = "Error Rate"
          type    = "timeseries"
          gridPos = { h = 8, w = 24, x = 0, y = 8 }
          targets = [
            {
              expr         = "sum by (service) (rate(http_requests_total{status=~\"5..\"}[5m])) / sum by (service) (rate(http_requests_total[5m]))"
              legendFormat = "{{ service }}"
            }
          ]
        }
      ]
      schemaVersion = 38
      tags          = ["golden-path", "open-horizons"]
      templating = {
        list = [
          {
            name    = "namespace"
            type    = "query"
            query   = "label_values(kube_pod_info, namespace)"
            refresh = 2
          }
        ]
      }
      time  = { from = "now-1h", to = "now" }
      title = "Open Horizons - Golden Path Applications"
      uid   = "open-horizons-apps"
    })
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================


