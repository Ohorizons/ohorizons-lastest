---
name: terraform-cli
description: "Terraform CLI operations for Azure infrastructure management. USE FOR: terraform init, terraform plan, terraform apply, terraform destroy, state management, module development, tfsec scanning. DO NOT USE FOR: Azure CLI operations (use azure-cli), Kubernetes operations (use kubectl-cli), Helm charts (use helm-cli)."
---

## When to Use
- Validating Terraform configurations
- Planning infrastructure changes
- Applying infrastructure changes (with approval)
- Security scanning IaC

## Prerequisites
- Terraform >= 1.5.0 installed
- Azure CLI authenticated
- Backend storage account accessible
- Environment variables: ARM_SUBSCRIPTION_ID, ARM_TENANT_ID

## Commands

### Format & Validate
```bash
# Check formatting
terraform fmt -check -recursive -diff

# Apply formatting
terraform fmt -recursive

# Validate configuration
terraform init -backend=false
terraform validate
```

### Planning
```bash
# Initialize with backend
terraform init -reconfigure

# Create plan
terraform plan \
  -var-file=environments/${ENVIRONMENT}.tfvars \
  -out=tfplan \
  -detailed-exitcode

# Show plan in JSON
terraform show -json tfplan | jq '.resource_changes'
```

### Security Scanning
```bash
# TFSec scan
tfsec . --format=json --out=tfsec-results.json

# Checkov scan
checkov -d . --output-file=checkov-results.json --output=json
```

### State Operations (Read-Only)
```bash
# List resources
terraform state list

# Show resource details
terraform state show 'azurerm_kubernetes_cluster.main'
```

## Best Practices
1. ALWAYS run `terraform fmt` before committing
2. ALWAYS run `terraform validate` before planning
3. NEVER commit .tfstate files
4. ALWAYS use -out flag for plans to review
5. Use workspaces for environment separation
6. Enable state locking with Azure blob lease

## Output Format
Provide structured output:
1. Command executed with full parameters
2. Exit code (0=success, 1=error, 2=changes pending)
3. Summary: resources to add/change/destroy
4. Warnings or errors with line references
5. Recommendations for next steps

## Integration with Agents
Used by: @terraform, @security, @test
