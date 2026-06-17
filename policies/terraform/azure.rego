# =============================================================================
# OPEN HORIZONS PLATFORM - TERRAFORM POLICIES
# =============================================================================
#
# OPA/Conftest policies for validating Terraform configurations.
#
# Usage:
#   terraform plan -out=tfplan
#   terraform show -json tfplan > tfplan.json
#   conftest test tfplan.json -p policies/terraform/
#
# =============================================================================

package terraform.azure

import future.keywords.in

# -----------------------------------------------------------------------------
# REQUIRED TAGS
# -----------------------------------------------------------------------------

# Required tags for all Azure resources
required_tags := ["environment", "project", "owner", "cost-center"]

deny[msg] {
  resource := input.resource_changes[_]
  is_taggable_resource(resource.type)
  resource.change.actions[_] == "create"
  tags := object.get(resource.change.after, "tags", {})
  missing := {tag | tag := required_tags[_]; not tags[tag]}
  count(missing) > 0
  msg := sprintf("Resource %s is missing required tags: %v", [resource.address, missing])
}

is_taggable_resource(type) {
  taggable_types := [
    "azurerm_resource_group",
    "azurerm_kubernetes_cluster",
    "azurerm_virtual_network",
    "azurerm_storage_account",
    "azurerm_key_vault",
    "azurerm_container_registry",
    "azurerm_postgresql_flexible_server",
    "azurerm_redis_cache",
    "azurerm_application_insights",
    "azurerm_log_analytics_workspace",
    "azurerm_cognitive_account"
  ]
  type in taggable_types
}

# -----------------------------------------------------------------------------
# SECURITY - TLS VERSION
# -----------------------------------------------------------------------------

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.actions[_] in ["create", "update"]
  tls_version := object.get(resource.change.after, "min_tls_version", "TLS1_0")
  tls_version != "TLS1_2"
  msg := sprintf("Storage account %s must use TLS 1.2 minimum (current: %s)", [resource.address, tls_version])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_postgresql_flexible_server"
  resource.change.actions[_] in ["create", "update"]
  ssl_mode := object.get(resource.change.after, "ssl_enforcement_enabled", false)
  ssl_mode == false
  msg := sprintf("PostgreSQL server %s must have SSL enforcement enabled", [resource.address])
}

# -----------------------------------------------------------------------------
# SECURITY - ENCRYPTION
# -----------------------------------------------------------------------------

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.actions[_] in ["create", "update"]
  infra_encryption := object.get(resource.change.after, "infrastructure_encryption_enabled", false)
  infra_encryption == false
  msg := sprintf("Storage account %s should have infrastructure encryption enabled", [resource.address])
}

warn[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  resource.change.actions[_] in ["create", "update"]
  purge_protection := object.get(resource.change.after, "purge_protection_enabled", false)
  purge_protection == false
  msg := sprintf("Key Vault %s should have purge protection enabled for production", [resource.address])
}

# -----------------------------------------------------------------------------
# SECURITY - PUBLIC ACCESS
# -----------------------------------------------------------------------------

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.actions[_] in ["create", "update"]
  public_access := object.get(resource.change.after, "public_network_access_enabled", true)
  public_access == true
  msg := sprintf("Storage account %s should not allow public network access", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  resource.change.actions[_] in ["create", "update"]
  public_access := object.get(resource.change.after, "public_network_access_enabled", true)
  public_access == true
  msg := sprintf("Key Vault %s should not allow public network access", [resource.address])
}

warn[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  resource.change.actions[_] in ["create", "update"]
  api_access := object.get(resource.change.after, "public_network_access_enabled", true)
  api_access == true
  msg := sprintf("AKS cluster %s has public API access enabled. Consider using private cluster.", [resource.address])
}

# -----------------------------------------------------------------------------
# SECURITY - HTTPS ONLY
# -----------------------------------------------------------------------------

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.actions[_] in ["create", "update"]
  https_only := object.get(resource.change.after, "enable_https_traffic_only", false)
  https_only == false
  msg := sprintf("Storage account %s must enforce HTTPS only traffic", [resource.address])
}

# -----------------------------------------------------------------------------
# NETWORKING - PRIVATE ENDPOINTS
# -----------------------------------------------------------------------------

warn[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.actions[_] == "create"
  not has_private_endpoint(resource.address)
  msg := sprintf("Storage account %s should use private endpoints for secure access", [resource.address])
}

has_private_endpoint(resource_address) {
  pe := input.resource_changes[_]
  pe.type == "azurerm_private_endpoint"
  contains(pe.address, resource_address)
}

# -----------------------------------------------------------------------------
# AKS SPECIFIC POLICIES
# -----------------------------------------------------------------------------

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  resource.change.actions[_] in ["create", "update"]
  rbac := object.get(resource.change.after, "role_based_access_control_enabled", false)
  rbac == false
  msg := sprintf("AKS cluster %s must have RBAC enabled", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  resource.change.actions[_] in ["create", "update"]
  identity := object.get(resource.change.after, "identity", [])
  count(identity) == 0
  msg := sprintf("AKS cluster %s must use managed identity", [resource.address])
}

warn[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  resource.change.actions[_] in ["create", "update"]
  azure_policy := object.get(resource.change.after, "azure_policy_enabled", false)
  azure_policy == false
  msg := sprintf("AKS cluster %s should have Azure Policy enabled", [resource.address])
}

warn[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster"
  resource.change.actions[_] in ["create", "update"]
  defender := object.get(resource.change.after, "microsoft_defender", [])
  count(defender) == 0
  msg := sprintf("AKS cluster %s should have Microsoft Defender enabled", [resource.address])
}

# -----------------------------------------------------------------------------
# DATABASE POLICIES
# -----------------------------------------------------------------------------

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_postgresql_flexible_server"
  resource.change.actions[_] in ["create", "update"]
  geo_backup := object.get(resource.change.after, "geo_redundant_backup_enabled", false)
  geo_backup == false
  msg := sprintf("PostgreSQL server %s must have geo-redundant backup enabled for production", [resource.address])
}

# -----------------------------------------------------------------------------
# COST OPTIMIZATION
# -----------------------------------------------------------------------------

warn[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_kubernetes_cluster_node_pool"
  resource.change.actions[_] == "create"
  auto_scale := object.get(resource.change.after, "enable_auto_scaling", false)
  auto_scale == false
  msg := sprintf("Node pool %s should have autoscaling enabled for cost optimization", [resource.address])
}

warn[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_virtual_machine"
  resource.change.actions[_] == "create"
  vm_size := object.get(resource.change.after, "size", "")
  is_expensive_size(vm_size)
  msg := sprintf("VM %s uses expensive size %s. Consider if this is necessary.", [resource.address, vm_size])
}

is_expensive_size(size) {
  expensive_sizes := ["Standard_E64", "Standard_M", "Standard_L"]
  some prefix in expensive_sizes
  startswith(size, prefix)
}
