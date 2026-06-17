# =============================================================================
# AZURE NAMING MODULE - Cloud Adoption Framework (CAF) Compliant
# =============================================================================
#
# This module generates Azure resource names following Microsoft's Cloud Adoption
# Framework naming conventions and Azure resource naming rules.
#
# Reference: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
# Reference: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
#
# Variables are defined in variables.tf
# Provider requirements are defined in versions.tf
#
# =============================================================================

# -----------------------------------------------------------------------------
# LOCALS - Region Codes
# -----------------------------------------------------------------------------

locals {
  # Azure region short codes (CAF recommended)
  region_codes = {
    # Americas
    "brazilsouth"     = "brs"
    "brazilsoutheast" = "brse"
    "eastus"          = "eus"
    "eastus2"         = "eus2"
    "westus"          = "wus"
    "westus2"         = "wus2"
    "westus3"         = "wus3"
    "centralus"       = "cus"
    "northcentralus"  = "ncus"
    "southcentralus"  = "scus"
    "westcentralus"   = "wcus"
    "canadacentral"   = "cac"
    "canadaeast"      = "cae"

    # Europe
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "francecentral"      = "frc"
    "francesouth"        = "frs"
    "germanywestcentral" = "gwc"
    "switzerlandnorth"   = "chn"

    # Asia Pacific
    "eastasia"           = "ea"
    "southeastasia"      = "sea"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "centralindia"       = "inc"
    "southindia"         = "ins"
    "koreacentral"       = "krc"
    "koreasouth"         = "krs"
  }

  region_code = lookup(local.region_codes, var.location, substr(var.location, 0, 4))

  # Base naming components
  org_prefix = var.org_code != "" ? "${var.org_code}-" : ""

  # Standard prefix: {org}-{project}-{env}-{region}
  base_prefix = "${local.org_prefix}${var.project_name}-${var.environment}-${local.region_code}"

  # For resources that don't allow hyphens
  base_prefix_no_dash = replace(local.base_prefix, "-", "")

  # Short prefix for length-limited resources
  short_prefix = "${var.project_name}${var.environment}${local.region_code}"
}

# -----------------------------------------------------------------------------
# OUTPUTS - Resource Names with CAF Prefixes
# -----------------------------------------------------------------------------

# =============================================================================
# GENERAL / MANAGEMENT
# =============================================================================

output "resource_group" {
  description = "Resource Group name (rg-)"
  value       = "rg-${local.base_prefix}"
  # Rules: 1-90 chars, alphanumeric, underscore, hyphen, period, parenthesis
  # Cannot end with period
}

output "management_group" {
  description = "Management Group name (mg-)"
  value       = "mg-${local.base_prefix}"
}

output "policy_definition" {
  description = "Policy Definition name (policy-)"
  value       = "policy-${local.base_prefix}"
}

output "api_management" {
  description = "API Management name (apim-)"
  value       = "apim-${local.base_prefix}"
  # Rules: 1-50 chars, alphanumeric and hyphens, start with letter, end with alphanumeric
}

# =============================================================================
# NETWORKING
# =============================================================================

output "virtual_network" {
  description = "Virtual Network name (vnet-)"
  value       = "vnet-${local.base_prefix}"
  # Rules: 2-64 chars, alphanumeric, underscore, hyphen, period
}

output "subnet" {
  description = "Subnet name prefix (snet-)"
  value       = "snet-${local.base_prefix}"
  # Add suffix like: snet-{base}-aks, snet-{base}-db
}

output "subnet_aks" {
  description = "AKS Subnet name"
  value       = "snet-${local.base_prefix}-aks"
}

output "subnet_db" {
  description = "Database Subnet name"
  value       = "snet-${local.base_prefix}-db"
}

output "subnet_pe" {
  description = "Private Endpoint Subnet name"
  value       = "snet-${local.base_prefix}-pe"
}

output "network_security_group" {
  description = "Network Security Group name (nsg-)"
  value       = "nsg-${local.base_prefix}"
  # Rules: 1-80 chars, alphanumeric, underscore, hyphen, period
}

output "application_security_group" {
  description = "Application Security Group name (asg-)"
  value       = "asg-${local.base_prefix}"
}

output "route_table" {
  description = "Route Table name (rt-)"
  value       = "rt-${local.base_prefix}"
}

output "nat_gateway" {
  description = "NAT Gateway name (ng-)"
  value       = "ng-${local.base_prefix}"
}

output "public_ip" {
  description = "Public IP name (pip-)"
  value       = "pip-${local.base_prefix}"
}

output "public_ip_prefix" {
  description = "Public IP Prefix name (ippre-)"
  value       = "ippre-${local.base_prefix}"
}

output "load_balancer_internal" {
  description = "Internal Load Balancer name (lbi-)"
  value       = "lbi-${local.base_prefix}"
}

output "load_balancer_external" {
  description = "External Load Balancer name (lbe-)"
  value       = "lbe-${local.base_prefix}"
}

output "application_gateway" {
  description = "Application Gateway name (agw-)"
  value       = "agw-${local.base_prefix}"
}

output "private_endpoint" {
  description = "Private Endpoint name prefix (pe-)"
  value       = "pe-${local.base_prefix}"
  # Add suffix like: pe-{base}-kv, pe-{base}-acr
}

output "private_dns_zone" {
  description = "Private DNS Zone name (not prefixed, use Azure standard names)"
  value       = "privatelink.azurecr.io"
}

output "firewall" {
  description = "Azure Firewall name (afw-)"
  value       = "afw-${local.base_prefix}"
}

output "firewall_policy" {
  description = "Firewall Policy name (afwp-)"
  value       = "afwp-${local.base_prefix}"
}

output "bastion" {
  description = "Azure Bastion name (bas-)"
  value       = "bas-${local.base_prefix}"
}

output "front_door" {
  description = "Azure Front Door name (fd-)"
  value       = "fd-${local.base_prefix}"
}

output "waf_policy" {
  description = "WAF Policy name (waf-)"
  value       = "waf-${local.base_prefix}"
}

# =============================================================================
# COMPUTE
# =============================================================================

output "virtual_machine" {
  description = "Virtual Machine name (vm-)"
  value       = "vm-${local.short_prefix}"
  # Rules: Windows 1-15 chars, Linux 1-64 chars
  # Alphanumeric and hyphens, cannot start/end with hyphen
}

output "virtual_machine_scale_set" {
  description = "VM Scale Set name (vmss-)"
  value       = "vmss-${local.base_prefix}"
}

output "availability_set" {
  description = "Availability Set name (avail-)"
  value       = "avail-${local.base_prefix}"
}

output "disk_managed" {
  description = "Managed Disk name (disk-)"
  value       = "disk-${local.base_prefix}"
}

output "disk_os" {
  description = "OS Disk name (osdisk-)"
  value       = "osdisk-${local.base_prefix}"
}

# =============================================================================
# CONTAINERS
# =============================================================================

output "aks_cluster" {
  description = "AKS Cluster name (aks-)"
  value       = "aks-${local.base_prefix}"
  # Rules: 1-63 chars, alphanumeric, underscore, hyphen
  # Start with letter, end with alphanumeric
}

output "aks_node_pool" {
  description = "AKS Node Pool name prefix"
  value       = substr(replace("${var.project_name}${var.environment}", "-", ""), 0, 6)
  # Rules: 1-12 chars for Windows, 1-12 for Linux, lowercase alphanumeric
  # Must start with letter
}

output "aks_node_pool_system" {
  description = "AKS System Node Pool name"
  value       = "system"
  # Common convention: system, user, gpu, spot
}

output "aks_node_pool_user" {
  description = "AKS User Node Pool name"
  value       = "user${var.instance}"
}

output "container_registry" {
  description = "Azure Container Registry name (cr or acr)"
  value       = "cr${local.base_prefix_no_dash}"
  # Rules: 5-50 chars, alphanumeric ONLY (no hyphens!)
  # Must be globally unique
}

output "container_instance" {
  description = "Container Instance name (ci-)"
  value       = "ci-${local.base_prefix}"
}

output "container_app" {
  description = "Container App name (ca-)"
  value       = "ca-${local.base_prefix}"
}

output "container_app_environment" {
  description = "Container App Environment name (cae-)"
  value       = "cae-${local.base_prefix}"
}

# =============================================================================
# DATABASES
# =============================================================================

output "sql_server" {
  description = "Azure SQL Server name (sql-)"
  value       = "sql-${local.base_prefix}"
  # Rules: 1-63 chars, lowercase, numbers, hyphens
  # Cannot start/end with hyphen, globally unique
}

output "sql_database" {
  description = "Azure SQL Database name (sqldb-)"
  value       = "sqldb-${local.base_prefix}"
}

output "sql_elastic_pool" {
  description = "SQL Elastic Pool name (sqlep-)"
  value       = "sqlep-${local.base_prefix}"
}

output "postgresql_server" {
  description = "PostgreSQL Flexible Server name (psql-)"
  value       = "psql-${local.base_prefix}"
  # Rules: 3-63 chars, lowercase, numbers, hyphens
  # Cannot start/end with hyphen, globally unique
}

output "postgresql_database" {
  description = "PostgreSQL Database name (psqldb-)"
  value       = "psqldb-${local.base_prefix}"
}

output "mysql_server" {
  description = "MySQL Flexible Server name (mysql-)"
  value       = "mysql-${local.base_prefix}"
}

output "cosmos_account" {
  description = "Cosmos DB Account name (cosmos-)"
  value       = "cosmos-${local.base_prefix}"
  # Rules: 3-44 chars, lowercase, numbers, hyphens
  # Cannot start/end with hyphen, globally unique
}

output "redis_cache" {
  description = "Azure Redis Cache name (redis-)"
  value       = "redis-${local.base_prefix}"
  # Rules: 1-63 chars, alphanumeric and hyphens
  # Cannot start/end with hyphen, globally unique
}

# =============================================================================
# STORAGE
# =============================================================================

output "storage_account" {
  description = "Storage Account name (st)"
  value       = substr("st${local.base_prefix_no_dash}${var.instance}", 0, 24)
  # Rules: 3-24 chars, lowercase and numbers ONLY
  # Must be globally unique
}

output "storage_account_diag" {
  description = "Diagnostics Storage Account name"
  value       = substr("stdiag${local.base_prefix_no_dash}", 0, 24)
}

output "storage_container" {
  description = "Storage Container name"
  value       = "blob-${local.base_prefix}"
  # Rules: 3-63 chars, lowercase, numbers, hyphens
}

output "storage_queue" {
  description = "Storage Queue name"
  value       = "queue-${local.base_prefix}"
}

output "storage_table" {
  description = "Storage Table name"
  value       = "table${local.base_prefix_no_dash}"
  # Rules: 3-63 chars, alphanumeric only
}

output "storage_file_share" {
  description = "Storage File Share name"
  value       = "share-${local.base_prefix}"
  # Rules: 3-63 chars, lowercase, numbers, hyphens
}

output "data_lake_store" {
  description = "Data Lake Store name (dls-)"
  value       = "dls${local.base_prefix_no_dash}"
  # Rules: 3-24 chars, lowercase and numbers only
}

# =============================================================================
# SECURITY
# =============================================================================

output "key_vault" {
  description = "Key Vault name (kv-)"
  value       = substr("kv-${local.base_prefix}", 0, 24)
  # Rules: 3-24 chars, alphanumeric and hyphens
  # Must start with letter, cannot end with hyphen
  # Must be globally unique
}

output "key_vault_key" {
  description = "Key Vault Key name"
  value       = "key-${local.base_prefix}"
}

output "key_vault_secret" {
  description = "Key Vault Secret name prefix"
  value       = "secret-${local.base_prefix}"
}

output "managed_identity" {
  description = "User Assigned Managed Identity name (id-)"
  value       = "id-${local.base_prefix}"
}

output "managed_identity_aks" {
  description = "AKS Managed Identity name"
  value       = "id-${local.base_prefix}-aks"
}

output "application_registration" {
  description = "App Registration name (app-)"
  value       = "app-${local.base_prefix}"
}

output "service_principal" {
  description = "Service Principal name (sp-)"
  value       = "sp-${local.base_prefix}"
}

# =============================================================================
# MONITORING & LOGGING
# =============================================================================

output "log_analytics_workspace" {
  description = "Log Analytics Workspace name (log-)"
  value       = "log-${local.base_prefix}"
  # Rules: 4-63 chars, alphanumeric and hyphens
  # Must be unique within resource group
}

output "application_insights" {
  description = "Application Insights name (appi-)"
  value       = "appi-${local.base_prefix}"
}

output "action_group" {
  description = "Action Group name (ag-)"
  value       = "ag-${local.base_prefix}"
}

output "dashboard" {
  description = "Azure Dashboard name (dash-)"
  value       = "dash-${local.base_prefix}"
}

output "monitor_workspace" {
  description = "Azure Monitor Workspace name (amw-)"
  value       = "amw-${local.base_prefix}"
}

output "grafana" {
  description = "Azure Managed Grafana name (amg-)"
  value       = "amg-${local.base_prefix}"
}

# =============================================================================
# AI & MACHINE LEARNING
# =============================================================================

output "cognitive_services" {
  description = "Cognitive Services name (cog-)"
  value       = "cog-${local.base_prefix}"
}

output "openai_service" {
  description = "Azure OpenAI Service name (oai-)"
  value       = "oai-${local.base_prefix}"
}

output "ai_hub" {
  description = "Azure AI Hub name (aih-)"
  value       = "aih-${local.base_prefix}"
}

output "ai_project" {
  description = "Azure AI Project name (aip-)"
  value       = "aip-${local.base_prefix}"
}

output "machine_learning_workspace" {
  description = "ML Workspace name (mlw-)"
  value       = "mlw-${local.base_prefix}"
}

output "search_service" {
  description = "Azure AI Search name (srch-)"
  value       = "srch-${local.base_prefix}"
  # Rules: 2-60 chars, lowercase, numbers, hyphens
  # Cannot start/end with hyphen, globally unique
}

# =============================================================================
# GOVERNANCE & COMPLIANCE
# =============================================================================

output "purview_account" {
  description = "Microsoft Purview Account name (pview-)"
  value       = "pview-${local.base_prefix}"
  # Rules: 3-63 chars, alphanumeric and hyphens
}

output "defender_plan" {
  description = "Defender for Cloud plan name"
  value       = "defender-${local.base_prefix}"
}

# =============================================================================
# INTEGRATION
# =============================================================================

output "service_bus_namespace" {
  description = "Service Bus Namespace name (sb-)"
  value       = "sb-${local.base_prefix}"
  # Rules: 6-50 chars, alphanumeric and hyphens
  # Must start with letter, globally unique
}

output "event_hub_namespace" {
  description = "Event Hub Namespace name (evh-)"
  value       = "evh-${local.base_prefix}"
}

output "event_grid_topic" {
  description = "Event Grid Topic name (evgt-)"
  value       = "evgt-${local.base_prefix}"
}

output "logic_app" {
  description = "Logic App name (logic-)"
  value       = "logic-${local.base_prefix}"
}

output "function_app" {
  description = "Function App name (func-)"
  value       = "func-${local.base_prefix}"
}

output "app_service_plan" {
  description = "App Service Plan name (asp-)"
  value       = "asp-${local.base_prefix}"
}

output "web_app" {
  description = "Web App name (app-)"
  value       = "app-${local.base_prefix}"
  # Rules: 2-60 chars, alphanumeric and hyphens
  # Globally unique (.azurewebsites.net)
}

# =============================================================================
# DEVOPS
# =============================================================================

output "automation_account" {
  description = "Automation Account name (aa-)"
  value       = "aa-${local.base_prefix}"
}

output "deployment_environment" {
  description = "Azure Deployment Environment name (ade-)"
  value       = "ade-${local.base_prefix}"
}

output "dev_center" {
  description = "Dev Center name (dc-)"
  value       = "dc-${local.base_prefix}"
}

# =============================================================================
# HELPER OUTPUTS
# =============================================================================

output "name_prefix" {
  description = "Base name prefix for custom resources"
  value       = local.base_prefix
}

output "name_prefix_no_dash" {
  description = "Base name prefix without dashes (for resources that don't allow)"
  value       = local.base_prefix_no_dash
}

output "short_prefix" {
  description = "Short prefix for length-limited resources"
  value       = local.short_prefix
}

output "region_code" {
  description = "Region short code"
  value       = local.region_code
}

output "tags" {
  description = "Standard tags to apply to all resources"
  value = {
    Project     = var.project_name
    Environment = var.environment
    Region      = var.location
    ManagedBy   = "Terraform"
  }
}
