# GitHub Runners Module

Self-hosted GitHub Actions runners on AKS using Actions Runner Controller (ARC) v2.

## Features

- Actions Runner Controller (ARC) v2
- Runner Scale Sets for autoscaling
- Multiple runner groups for team isolation
- Workload Identity for Azure access
- Docker-in-Docker or Kubernetes modes
- Network policies for security
- Resource quotas
- Prometheus metrics

## Usage

```hcl
module "github_runners" {
  source = "./modules/github-runners"

  customer_name = "threehorizons"
  environment   = "prod"
  namespace     = "github-runners"

  github_org                 = "my-org"
  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_private_key     = var.github_app_private_key

  controller_replicas = 2

  runner_groups = {
    default = {
      runner_group = "default"
      min_runners  = 2
      max_runners  = 10
      resources = {
        cpu_request    = "500m"
        cpu_limit      = "2000m"
        memory_request = "1Gi"
        memory_limit   = "4Gi"
      }
      container_mode = "dind"
      node_selector  = {}
      tolerations    = []
    }
    large = {
      runner_group = "large-runners"
      min_runners  = 0
      max_runners  = 5
      resources = {
        cpu_request    = "2000m"
        cpu_limit      = "4000m"
        memory_request = "8Gi"
        memory_limit   = "16Gi"
      }
      container_mode = "dind"
      node_selector = {
        "node.kubernetes.io/instance-type" = "Standard_D8s_v3"
      }
      tolerations = []
    }
  }

  # Azure credentials for Workload Identity
  azure_credentials = {
    client_id       = module.security.runner_identity_client_id
    tenant_id       = data.azurerm_client_config.current.tenant_id
    subscription_id = data.azurerm_subscription.current.subscription_id
  }

  # Custom runner image (optional)
  custom_runner_image = ""

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| namespace | Kubernetes namespace | `string` | `"github-runners"` | no |
| github_org | GitHub organization | `string` | n/a | yes |
| github_app_id | GitHub App ID | `string` | n/a | yes |
| github_app_installation_id | GitHub App installation ID | `string` | n/a | yes |
| github_app_private_key | GitHub App private key | `string` | n/a | yes |
| controller_replicas | ARC controller replicas | `number` | `2` | no |
| runner_groups | Runner group configurations | `map(object)` | n/a | yes |
| azure_credentials | Azure credentials for Workload Identity | `object` | `null` | no |
| custom_runner_image | Custom runner image | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Runners namespace |
| controller_release_name | ARC controller Helm release |
| runner_scale_sets | Runner scale set names |

## Runner Groups

Configure multiple runner groups for different workloads:

| Group | Use Case | Resources |
|-------|----------|-----------|
| default | Standard builds | 2 CPU, 4GB RAM |
| large | Heavy builds, integration tests | 4 CPU, 16GB RAM |
| gpu | ML/AI workloads | GPU-enabled nodes |

## Container Modes

- **dind (Docker-in-Docker)**: Full Docker support, good for building images
- **kubernetes**: Uses Kubernetes for container operations, more secure

## Network Policy

Default policy:
- Egress: Allow all (runners need internet access)
- Ingress: Only from ARC controller

## Resource Quotas

Default quotas per namespace:
- CPU requests: 50 cores
- Memory requests: 100Gi
- Max pods: 100
