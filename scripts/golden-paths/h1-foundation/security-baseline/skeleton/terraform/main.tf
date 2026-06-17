resource "azurerm_key_vault" "main" {
  name                      = "kv-security"
  location                  = var.location
  resource_group_name       = var.resource_group
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = true
  enable_rbac_authorization = true
}

data "azurerm_client_config" "current" {}
