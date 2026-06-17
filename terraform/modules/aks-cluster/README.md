# AKS Cluster Module

Azure Kubernetes Service (AKS) cluster with Workload Identity, Azure CNI, and enterprise security features.

## Features

- AKS cluster with managed identity
- Workload Identity for secure pod authentication
- Azure CNI networking with dynamic IP allocation
- System and user node pools with autoscaling
- Azure Policy addon for Kubernetes
- Azure Monitor integration
- Private cluster support
- Availability zones support

## Usage

```hcl
module "aks" {
  source = "./modules/aks-cluster"

  cluster_name        = module.naming.aks_cluster
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  kubernetes_version = "1.28"
  sku_tier          = "Standard"

  default_node_pool = {
    name                = "system"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 6
    zones               = ["1", "2", "3"]
  }

  network_config = {
    vnet_subnet_id     = module.networking.aks_subnet_id
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    network_plugin     = "azure"
    network_policy     = "calico"
  }

  identity_config = {
    type         = "UserAssigned"
    identity_ids = [module.security.aks_identity_id]
  }

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
| cluster_name | Name of the AKS cluster | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | `"1.28"` | no |
| sku_tier | AKS SKU tier (Free, Standard) | `string` | `"Standard"` | no |
| default_node_pool | Default node pool configuration | `object` | n/a | yes |
| network_config | Network configuration | `object` | n/a | yes |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | AKS cluster resource ID |
| cluster_name | AKS cluster name |
| kube_config | Kubernetes configuration |
| oidc_issuer_url | OIDC issuer URL for Workload Identity |
| node_resource_group | Node resource group name |

## Security Considerations

- Enable Azure Policy for Kubernetes compliance
- Use private cluster in production
- Configure network policies
- Enable Defender for Containers
- Use Workload Identity instead of pod identity
