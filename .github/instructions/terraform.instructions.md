---
applyTo: "**/*.tf,**/terraform/**,**/*.tf.example,**/*.tfvars.example"
description: "Use when editing Open Horizons Terraform modules, environments, providers, variables, outputs, and Azure infrastructure examples."
---

# Terraform Conventions — Azure Infrastructure Modules and Environments

This file activates when you edit Terraform modules, environment variable files, provider configuration, and Terraform examples. It teaches how Open Horizons provisions Azure foundation resources for AKS, networking, security, databases, observability, ArgoCD, and Backstage using reusable modules. It does **not** cover Kubernetes manifests deployed after infrastructure exists, which belong to [Kubernetes standards](kubernetes.instructions.md), shell deployment orchestration, which belongs to [Shell script standards](shell.instructions.md), GitHub Actions workflows that run Terraform, which belong to [GitHub Actions standards](github-actions.instructions.md), or container image definitions, which belong to [Dockerfile standards](dockerfile.instructions.md).

> [!IMPORTANT]
> The Kubernetes, Helm, and kubectl providers depend on AKS outputs. On an empty subscription, apply H1 infrastructure before H2 modules or use the repository deployment script.

## Module Structure

Keep modules focused and organized with `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`. Existing modules under `terraform/modules/` follow this shape.

```hcl
# Wrong: mixes provider constraints, variables, and unrelated resources in one file.
resource "azurerm_kubernetes_cluster" "main" {
  name = "aks-dev"
}
```

```hcl
# main.tf
locals {
  cluster_name = "aks-${var.customer_name}-${var.environment}"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
}
```

## Naming and Tags

Use repo naming patterns and merge module-specific tags with caller-provided tags. The AKS module uses `aks-${var.customer_name}-${var.environment}` and adds component metadata.

```hcl
# Wrong: hard-coded name and no caller tags.
name = "mycluster"
tags = {}
```

```hcl
locals {
  cluster_name = "aks-${var.customer_name}-${var.environment}"
  default_tags = merge(var.tags, {
    Component = "AKS"
    Module    = "open-horizons-accelerator"
  })
}
```

> [!WARNING]
> Never commit subscription secrets, client secrets, storage account keys, database passwords, or generated kubeconfigs in `.tf`, `.tfvars`, or examples.

## Variables and Validation

Use typed variables with descriptions, defaults only where safe, and validation for constrained values. Keep deprecated inputs only when needed for backward compatibility and mark them clearly.

```hcl
# Wrong: untyped environment with no description.
variable "environment" {}
```

```hcl
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

## Azure Identity and Security

Use managed identity and Workload Identity patterns. For AKS, keep OIDC issuer and workload identity controlled by variables and defaulted on.

```hcl
# Wrong: service principal secret embedded in cluster configuration.
service_principal {
  client_id     = var.client_id
  client_secret = var.client_secret
}
```

```hcl
identity {
  type = "SystemAssigned"
}

oidc_issuer_enabled       = var.enable_workload_identity
workload_identity_enabled = var.enable_workload_identity
```

> [!NOTE]
> Use data sources for existing Azure resources and pass IDs between modules through explicit outputs and variables.

## Networking and AKS

Keep AKS networking explicit: Azure CNI overlay, network policy, standard load balancer, and service CIDR values come from typed network configuration.

```hcl
# Wrong: implicit networking hides tenant and cluster constraints.
network_profile {}
```

```hcl
network_profile {
  network_plugin      = var.network_config.network_plugin
  network_plugin_mode = "overlay"
  network_policy      = var.network_config.network_policy
  load_balancer_sku   = "standard"
  outbound_type       = "loadBalancer"
  service_cidr        = var.network_config.service_cidr
  dns_service_ip      = var.network_config.dns_service_ip
}
```

## Outputs and Sensitive Values

Describe every output and mark sensitive values. Prefer outputting resource IDs and names rather than secrets.

```hcl
# Wrong: exposes a secret as a normal output.
output "database_password" {
  value = random_password.postgres.result
}
```

```hcl
output "key_vault_id" {
  description = "ID of the Key Vault used by platform workloads."
  value       = azurerm_key_vault.main.id
}

output "database_password" {
  description = "Generated database password."
  value       = random_password.postgres.result
  sensitive   = true
}
```

## Conventions

| Rule | Rationale |
|---|---|
| Keep each module focused with `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf` | Consistent module shape makes reviews and reuse predictable. |
| Use typed variables with descriptions and validations | Terraform plans should fail early with useful errors. |
| Merge caller tags with module-specific tags | Cost, ownership, and component reporting depend on tags. |
| Use Managed Identity or Workload Identity instead of service principal secrets | The platform security model avoids long-lived credentials. |
| Enable private endpoints or private access patterns for PaaS where modules support them | Azure services should not be public by default. |
| Mark sensitive outputs and avoid outputting secrets when IDs are enough | State files and plan logs can expose outputs. |
| Keep provider versions pinned and do not use `terraform init -upgrade` casually | `.terraform.lock.hcl` represents the tested provider set. |

## Do / Do Not

| Do | Do not |
|---|---|
| Apply H1 modules before H2 modules that need AKS provider outputs | Expect a single empty-subscription apply to plan all Kubernetes providers. |
| Use `for_each` for maps of optional resources such as node pools | Copy and paste nearly identical resources. |
| Keep `.tfvars.example` sanitized | Commit real customer values in environment files. |
| Run `terraform fmt` and a targeted `terraform validate` or plan where possible | Ship formatting or provider errors untested. |

## Checklist Before Opening a PR

- [ ] Module files follow the existing `main`, `variables`, `outputs`, `versions` layout.
- [ ] Variables are typed, described, and validated where constrained.
- [ ] Resources use managed identity, private access, diagnostics, and tags where supported.
- [ ] No secrets or tenant-specific credentials are committed.
- [ ] Outputs are described and sensitive values are marked.
- [ ] Terraform formatting and targeted validation or planning has been run where feasible.
