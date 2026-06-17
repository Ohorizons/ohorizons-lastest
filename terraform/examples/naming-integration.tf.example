# =============================================================================
# NAMING MODULE INTEGRATION EXAMPLE
# =============================================================================
#
# Add this to your main.tf to use consistent naming across all resources
#
# =============================================================================

# -----------------------------------------------------------------------------
# NAMING MODULE
# -----------------------------------------------------------------------------

module "naming" {
  source = "../modules/naming"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location
  instance     = var.instance
  org_code     = var.org_code # Optional: "ms", "cont", etc.
}

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = var.location
  tags     = module.naming.tags
}

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

module "networking" {
  source = "../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module outputs
  vnet_name       = module.naming.virtual_network
  aks_subnet_name = module.naming.subnet_aks
  db_subnet_name  = module.naming.subnet_db
  pe_subnet_name  = module.naming.subnet_pe
  nsg_name        = module.naming.network_security_group

  # ... other variables
  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# AKS CLUSTER
# -----------------------------------------------------------------------------

module "aks_cluster" {
  source = "../modules/aks-cluster"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module outputs
  cluster_name   = module.naming.aks_cluster
  node_pool_name = module.naming.aks_node_pool_system
  identity_name  = module.naming.managed_identity_aks

  # ... other variables
  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# CONTAINER REGISTRY (No hyphens allowed!)
# -----------------------------------------------------------------------------

module "container_registry" {
  source = "../modules/container-registry"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module - automatically removes hyphens
  acr_name = module.naming.container_registry # e.g., "crthreehorizonsprdbrs"

  # ... other variables
  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT (Lowercase + numbers only!)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  # Use naming module - automatically handles constraints
  name                     = module.naming.storage_account # e.g., "stthreehorizonsprdbrs001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# KEY VAULT
# -----------------------------------------------------------------------------

module "security" {
  source = "../modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module
  key_vault_name = module.naming.key_vault # e.g., "kv-threehorizons-prd-brs"
  identity_name  = module.naming.managed_identity

  # ... other variables
  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# DATABASE
# -----------------------------------------------------------------------------

module "databases" {
  source = "../modules/databases"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module
  server_name   = module.naming.postgresql_server # e.g., "psql-threehorizons-prd-brs"
  database_name = module.naming.postgresql_database

  # ... other variables
  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# MONITORING
# -----------------------------------------------------------------------------

module "observability" {
  source = "../modules/observability"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module
  log_analytics_name = module.naming.log_analytics_workspace
  app_insights_name  = module.naming.application_insights
  grafana_name       = module.naming.grafana

  # ... other variables
  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# AI SERVICES
# -----------------------------------------------------------------------------

module "ai_foundry" {
  source = "../modules/ai-foundry"
  count  = var.enable_ai_foundry ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module
  openai_name = module.naming.openai_service
  search_name = module.naming.search_service
  ai_hub_name = module.naming.ai_hub

  # ... other variables
  tags = module.naming.tags
}

# -----------------------------------------------------------------------------
# GOVERNANCE
# -----------------------------------------------------------------------------

module "purview" {
  source = "../modules/purview"
  count  = var.enable_purview ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Use naming module
  purview_name = module.naming.purview_account

  # ... other variables
  tags = module.naming.tags
}

module "defender" {
  source = "../modules/defender"
  count  = var.enable_defender ? 1 : 0

  # Defender is subscription-level, not resource group
  # ... other variables
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINTS - Example naming
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "keyvault" {
  name                = "${module.naming.private_endpoint}-kv" # pe-threehorizons-prd-brs-kv
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.pe_subnet_id

  private_service_connection {
    name                           = "psc-${module.naming.key_vault}"
    private_connection_resource_id = module.security.key_vault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = module.naming.tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "${module.naming.private_endpoint}-acr" # pe-threehorizons-prd-brs-acr
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.pe_subnet_id

  private_service_connection {
    name                           = "psc-${module.naming.container_registry}"
    private_connection_resource_id = module.container_registry.acr_id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  tags = module.naming.tags
}
