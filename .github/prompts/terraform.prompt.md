---
description: "Write or validate Terraform modules for Azure infrastructure. USE FOR: create Terraform module, terraform plan, terraform apply, write AKS module, Terraform validation, AVM module."
agent: "terraform"
---

# Terraform Module

Write or modify a Terraform module for Azure infrastructure following AVM patterns and project conventions.

## Input

- **Module name**: What to create (e.g., AKS cluster, Key Vault, networking)
- **Environment**: Target environment (dev, staging, prod)

## Expected Output

- Terraform files (`main.tf`, `variables.tf`, `outputs.tf`)
- Validated with `terraform validate` and `tfsec`
- Tagged with: environment, project, owner, cost-center
