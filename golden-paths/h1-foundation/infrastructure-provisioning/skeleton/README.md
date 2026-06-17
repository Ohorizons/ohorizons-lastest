# ${{values.name}}

${{values.description}}

## Overview

Infrastructure as Code project using Terraform for Azure resources.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Cloud | Azure |

## Features

- Terraform modules for Azure resources
- Remote state management
- Environment-specific configurations
- Automated validation and deployment

## Getting Started

### Prerequisites

- Terraform >= 1.5.0
- Azure CLI
- Azure subscription

### Setup

```bash
# Login to Azure
az login

# Initialize Terraform
cd terraform
terraform init

# Plan changes
terraform plan -var-file=environments/dev.tfvars

# Apply changes
terraform apply -var-file=environments/dev.tfvars
```

## Structure

```
terraform/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── backend.tf           # State backend
└── environments/
    ├── dev.tfvars       # Development
    ├── staging.tfvars   # Staging
    └── prod.tfvars      # Production
```

## Environments

| Environment | Purpose |
|-------------|---------|
| dev | Development and testing |
| staging | Pre-production validation |
| prod | Production workloads |

## CI/CD

Infrastructure changes are deployed via GitHub Actions:

1. PR triggers `terraform plan`
2. Review plan output
3. Merge triggers `terraform apply`

## Links

- [Terraform Documentation](https://www.terraform.io/docs)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm)
