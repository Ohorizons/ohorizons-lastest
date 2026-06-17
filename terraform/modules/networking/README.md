# Networking Module

Azure Virtual Network with subnets, NSGs, private DNS zones, and private endpoints.

## Features

- Virtual Network with customizable address space
- Multiple subnets (AKS, databases, private endpoints, services)
- Network Security Groups with default rules
- Private DNS zones for Azure services
- NAT Gateway for outbound traffic
- Route tables for custom routing
- Service endpoints configuration

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  address_space = ["10.0.0.0/16"]

  subnets = {
    aks = {
      address_prefix    = "10.0.0.0/22"
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
    }
    services = {
      address_prefix = "10.0.4.0/24"
    }
    postgresql = {
      address_prefix = "10.0.5.0/24"
      delegation = {
        name    = "postgresql"
        service = "Microsoft.DBforPostgreSQL/flexibleServers"
      }
    }
    private_endpoints = {
      address_prefix                            = "10.0.6.0/24"
      private_endpoint_network_policies_enabled = true
    }
  }

  private_dns_zones = [
    "privatelink.azurecr.io",
    "privatelink.vaultcore.azure.net",
    "privatelink.postgres.database.azure.com"
  ]

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
| name | Virtual network name | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| address_space | VNet address space | `list(string)` | n/a | yes |
| subnets | Subnet configurations | `map(object)` | n/a | yes |
| private_dns_zones | Private DNS zones to create | `list(string)` | `[]` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Virtual network ID |
| vnet_name | Virtual network name |
| aks_subnet_id | AKS subnet ID |
| services_subnet_id | Services subnet ID |
| postgresql_subnet_id | PostgreSQL subnet ID |
| private_endpoints_subnet_id | Private endpoints subnet ID |
| private_dns_zone_ids | Map of private DNS zone IDs |
