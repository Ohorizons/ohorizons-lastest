# Security Module

Azure Key Vault, managed identities, and RBAC configuration for secure infrastructure.

## Features

- Azure Key Vault with private endpoint
- User-assigned managed identities
- Workload Identity federation
- RBAC role assignments
- Diagnostic settings
- Soft delete and purge protection

## Usage

```hcl
module "security" {
  source = "./modules/security"

  key_vault_name      = module.naming.key_vault
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Key Vault configuration
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  # Private endpoint
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  private_dns_zone_ids       = [module.networking.private_dns_zone_ids["privatelink.vaultcore.azure.net"]]

  # Managed identities
  managed_identities = {
    aks = {
      name = module.naming.managed_identity_aks
    }
    argocd = {
      name = "${module.naming.managed_identity}-argocd"
    }
  }

  # Workload Identity federations
  workload_identity_federations = {
    argocd = {
      identity_name = "argocd"
      issuer_url    = module.aks.oidc_issuer_url
      subject       = "system:serviceaccount:argocd:argocd-server"
    }
  }

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
| azuread | ~> 2.45 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| key_vault_name | Key Vault name | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| sku_name | Key Vault SKU | `string` | `"standard"` | no |
| purge_protection_enabled | Enable purge protection | `bool` | `true` | no |
| managed_identities | Managed identities to create | `map(object)` | `{}` | no |
| workload_identity_federations | Workload Identity configs | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | Key Vault resource ID |
| key_vault_uri | Key Vault URI |
| aks_identity_id | AKS managed identity ID |
| aks_identity_client_id | AKS managed identity client ID |
| identity_ids | Map of all managed identity IDs |
