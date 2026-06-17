# Container Registry Module

Azure Container Registry with enterprise features including geo-replication and security scanning.

## Features

- Azure Container Registry (Premium SKU recommended)
- Private endpoint connectivity
- Geo-replication for multi-region deployments
- Content trust for image signing
- Retention policies for image cleanup
- Quarantine policy for security scanning
- Scope maps and tokens for fine-grained access
- Automated purge tasks
- Webhooks for CI/CD integration

## Usage

```hcl
module "container_registry" {
  source = "./modules/container-registry"

  customer_name       = "threehorizons"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  sku                   = "Premium"
  enable_content_trust  = true
  retention_policy_days = 90

  subnet_id           = module.networking.private_endpoints_subnet_id
  private_dns_zone_id = module.networking.private_dns_zone_ids["privatelink.azurecr.io"]

  # Geo-replication (Premium only)
  geo_replication_locations = ["brazilsouth", "eastus2"]

  # AKS integration
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id

  # GitHub Actions push access
  github_actions_identity_ids = [module.github_runners.identity_principal_id]

  # Webhook for CI/CD
  enable_webhook      = true
  webhook_service_uri = "https://ci.example.com/webhook"

  log_analytics_workspace_id = module.observability.log_analytics_workspace_id

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
| customer_name | Customer name for resource naming | `string` | n/a | yes |
| environment | Environment (dev, staging, prod) | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| sku | ACR SKU (Basic, Standard, Premium) | `string` | `"Premium"` | no |
| enable_content_trust | Enable content trust | `bool` | `true` | no |
| retention_policy_days | Days to retain untagged images | `number` | `90` | no |
| subnet_id | Subnet ID for private endpoint | `string` | n/a | yes |
| private_dns_zone_id | Private DNS zone ID | `string` | n/a | yes |
| geo_replication_locations | Locations for geo-replication | `list(string)` | `[]` | no |
| aks_kubelet_identity_object_id | AKS kubelet identity for AcrPull | `string` | n/a | yes |
| github_actions_identity_ids | Identity IDs for AcrPush | `list(string)` | `[]` | no |
| enable_webhook | Enable webhook | `bool` | `false` | no |
| webhook_service_uri | Webhook service URI | `string` | `""` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `""` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr_id | Container Registry resource ID |
| acr_name | Container Registry name |
| acr_login_server | Container Registry login server |
| acr_admin_username | Admin username (if enabled) |

## Premium Features

When using Premium SKU:
- **Geo-replication**: Replicate images to multiple regions
- **Content trust**: Sign and verify images
- **Retention policies**: Automatically clean up old images
- **Quarantine**: Hold images until security scan completes
- **Customer-managed keys**: Encrypt registry with your own keys
- **Zone redundancy**: High availability within a region

## Automated Purge

The module creates an ACR task that runs weekly to:
- Remove untagged images older than 90 days
- Keep the 10 most recent tags per repository
