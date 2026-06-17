---
name: azure-infrastructure
description: "Azure infrastructure patterns and best practices. USE FOR: Azure architecture patterns, hub-spoke networking, private endpoints, Workload Identity, resource naming, tagging strategy. DO NOT USE FOR: Terraform CLI commands (use terraform-cli), Azure CLI commands (use azure-cli), Kubernetes operations (use kubectl-cli)."
---

## When to Use
- Infrastructure planning and design
- Azure Verified Modules reference
- CAF naming convention guidance
- Resource provisioning patterns

## Prerequisites
- Azure subscription access
- Terraform knowledge
- Understanding of Azure services

## Reference Patterns

### Resource Group Naming
```
rg-<project>-<environment>-<region>
Example: rg-3horizons-prod-eastus2
```

### AKS Cluster Naming
```
aks-<project>-<environment>-<region>
Example: aks-3horizons-prod-eastus2
```

### Key Vault Naming
```
kv-<project>-<environment>-<region>
Example: kv-3horizons-prod-eus2
```

### Storage Account Naming
```
st<project><environment><region>
Example: st3horizonsprodeus2
```

## Required Tags
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
  }
}
```

## Security Patterns
- Use Workload Identity (not service principals)
- Enable private endpoints for PaaS services
- Configure NSGs with deny-all default
- Enable Azure Defender for Cloud

## Best Practices
1. Use Azure Verified Modules when available
2. Follow CAF naming conventions
3. Enable diagnostic settings
4. Configure resource locks for production
5. Use managed identities

## Integration with Agents
Used by: @terraform, @security, @devops
