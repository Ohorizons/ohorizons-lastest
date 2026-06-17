---
applyTo: "**/*.tf,**/terraform/**,**/*.tfvars"
description: "Terraform coding standards — module structure, provider versions, naming conventions, tagging, and security practices for Azure."
---

# Terraform Coding Standards

## Project Structure

```
terraform/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/
│   └── <module-name>/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── backend.tf
└── versions.tf
```

## Provider Configuration

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
```

## Backend Configuration

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "project.tfstate"
    use_azuread_auth     = true
  }
}
```

## Naming Conventions

- Use lowercase with hyphens: `my-resource-name`
- Include environment: `project-env-resource-region`
- Use consistent abbreviations:
  - `rg` = Resource Group
  - `vnet` = Virtual Network
  - `aks` = Azure Kubernetes Service
  - `kv` = Key Vault
  - `acr` = Container Registry

## Variables

```hcl
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "eastus2"
}
```

## Outputs

```hcl
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "sensitive_data" {
  description = "Sensitive output example"
  value       = azurerm_key_vault_secret.example.value
  sensitive   = true
}
```

## Tagging Standards

```hcl
locals {
  common_tags = {
    Environment  = var.environment
    Project      = var.project_name
    Owner        = var.owner
    CostCenter   = var.cost_center
    ManagedBy    = "Terraform"
    Repository   = "ohorizons-lastest"
  }
}
```

## Security Requirements

- NEVER hardcode secrets
- ALWAYS use data sources for existing resources
- Use `sensitive = true` for sensitive outputs
- Enable soft delete and purge protection for Key Vault
- Use private endpoints for PaaS services
- Enable diagnostic settings on all resources

## Module Best Practices

- Keep modules focused and reusable
- Document all inputs and outputs
- Provide sensible defaults
- Use count or for_each for conditional resources
- Include examples in README.md
