# =============================================================================
# OPEN HORIZONS PLATFORM - AKS CLUSTER MODULE
# =============================================================================
# 
# This module creates a production-ready Azure Kubernetes Service cluster
# optimized for the Open Horizons Platform.
#
# Features:
#   - Multi-zone deployment for high availability
#   - System and user node pools separation
#   - Azure CNI with Overlay networking
#   - Workload Identity for secure pod authentication
#   - Azure Key Vault integration
#   - Container Insights for monitoring
#   - Azure Policy for governance
#
# =============================================================================

# NOTE: Terraform block is in versions.tf
# NOTE: Variables are defined in variables.tf


# =============================================================================
# LOCALS
# =============================================================================

locals {
  cluster_name = "aks-${var.customer_name}-${var.environment}"
  dns_prefix   = "${var.customer_name}-${var.environment}"

  default_tags = merge(var.tags, {
    Component = "AKS"
    Module    = "open-horizons-accelerator"
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}

# =============================================================================
# AKS CLUSTER
# =============================================================================

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # ==========================================================================
  # SYSTEM NODE POOL
  # ==========================================================================
  default_node_pool {
    name                = var.default_node_pool.name
    vm_size             = var.default_node_pool.vm_size
    node_count          = var.default_node_pool.node_count
    zones               = var.default_node_pool.zones
    vnet_subnet_id      = var.network_config.nodes_subnet_id
    min_count           = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count           = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    enable_auto_scaling = var.default_node_pool.enable_auto_scaling
    os_disk_size_gb     = var.default_node_pool.os_disk_size_gb
    os_disk_type        = var.default_node_pool.os_disk_type
    max_pods            = var.default_node_pool.max_pods

    # Pod subnet for Azure CNI Overlay
    pod_subnet_id = var.network_config.pods_subnet_id

    # System pool settings
    only_critical_addons_enabled = true

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }

    # Upgrade settings
    upgrade_settings {
      max_surge = "33%"
    }

    tags = local.default_tags
  }

  # ==========================================================================
  # IDENTITY
  # ==========================================================================
  identity {
    type = "SystemAssigned"
  }

  # ==========================================================================
  # NETWORK PROFILE
  # ==========================================================================
  network_profile {
    network_plugin      = var.network_config.network_plugin
    network_plugin_mode = "overlay"
    network_policy      = var.network_config.network_policy
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"

    # Service CIDR (internal Kubernetes services)
    service_cidr   = var.network_config.service_cidr
    dns_service_ip = var.network_config.dns_service_ip
  }

  # ==========================================================================
  # OIDC & WORKLOAD IDENTITY
  # ==========================================================================
  oidc_issuer_enabled       = var.enable_workload_identity
  workload_identity_enabled = var.enable_workload_identity

  # ==========================================================================
  # AZURE AD INTEGRATION
  # ==========================================================================
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # ==========================================================================
  # KEY VAULT SECRETS PROVIDER
  # ==========================================================================
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # ==========================================================================
  # AZURE POLICY
  # ==========================================================================
  azure_policy_enabled = var.enable_azure_policy

  # ==========================================================================
  # CONTAINER INSIGHTS (OMS AGENT)
  # ==========================================================================
  dynamic "oms_agent" {
    for_each = var.log_analytics_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_id
    }
  }

  # ==========================================================================
  # AUTO-SCALER PROFILE
  # ==========================================================================
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max            = 10
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
  }

  # ==========================================================================
  # MAINTENANCE WINDOW
  # ==========================================================================
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
    utc_offset  = "-03:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "04:00"
    utc_offset  = "-03:00"
  }

  tags = local.default_tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }
}

# =============================================================================
# USER NODE POOLS
# =============================================================================

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.additional_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  zones                 = each.value.zones
  vnet_subnet_id        = var.network_config.nodes_subnet_id
  pod_subnet_id         = var.network_config.pods_subnet_id
  max_pods              = each.value.max_pods

  # Auto-scaling
  enable_auto_scaling = each.value.enable_auto_scaling
  min_count           = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count           = each.value.enable_auto_scaling ? each.value.max_count : null
  node_count          = each.value.enable_auto_scaling ? null : each.value.node_count

  # Labels and taints
  node_labels = merge(each.value.node_labels, {
    "environment" = var.environment
  })

  node_taints = each.value.node_taints

  # Upgrade settings
  upgrade_settings {
    max_surge = "33%"
  }

  tags = local.default_tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

# =============================================================================
# RBAC - ACR PULL PERMISSION
# =============================================================================

resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr_id != null ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# =============================================================================
# RBAC - KEY VAULT ACCESS
# =============================================================================

resource "azurerm_role_assignment" "keyvault_secrets" {
  count = var.key_vault_id != null ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = var.key_vault_id
  skip_service_principal_aad_check = true
}

# =============================================================================
# DIAGNOSTIC SETTINGS
# =============================================================================

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.log_analytics_id != null ? 1 : 0

  name                       = "aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_id

  # Control plane logs
  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "guard"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================
