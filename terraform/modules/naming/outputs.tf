# =============================================================================
# NAMING MODULE - OUTPUTS
# =============================================================================
#
# This file re-exports the key outputs from main.tf for easier consumption.
# All outputs are already defined in main.tf following Azure CAF naming.
#
# Usage:
#   module "naming" {
#     source       = "./modules/naming"
#     project_name = "myproject"
#     environment  = "dev"
#     location     = "eastus2"
#   }
#
#   # Then use: module.naming.aks_cluster, module.naming.key_vault, etc.
#
# =============================================================================

# Note: All 60+ outputs are defined directly in main.tf
# This file serves as documentation and follows module conventions.

# =============================================================================
# FREQUENTLY USED OUTPUTS - Quick Reference
# =============================================================================
#
# Infrastructure:
#   - resource_group      : "rg-{prefix}"
#   - virtual_network     : "vnet-{prefix}"
#   - aks_cluster         : "aks-{prefix}"
#   - container_registry  : "cr{prefix}" (no dashes)
#
# Security:
#   - key_vault           : "kv-{prefix}" (max 24 chars)
#   - managed_identity    : "id-{prefix}"
#
# Data:
#   - postgresql_server   : "psql-{prefix}"
#   - redis_cache         : "redis-{prefix}"
#   - storage_account     : "st{prefix}" (max 24 chars, no dashes)
#
# Monitoring:
#   - log_analytics_workspace : "log-{prefix}"
#   - application_insights    : "appi-{prefix}"
#
# AI:
#   - openai_service      : "oai-{prefix}"
#   - ai_hub              : "aih-{prefix}"
#   - search_service      : "srch-{prefix}"
#
# Helpers:
#   - name_prefix         : Full base prefix
#   - name_prefix_no_dash : Prefix without dashes
#   - short_prefix        : Short version for limited resources
#   - region_code         : Region abbreviation
#   - tags                : Standard tags map
#
# =============================================================================
