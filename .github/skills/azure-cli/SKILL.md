---
name: azure-cli
description: "Azure CLI operations for cloud resource management. USE FOR: az login, az aks, az acr, az keyvault, Azure resource provisioning, Azure resource group, Azure subscription management. DO NOT USE FOR: Terraform IaC (use terraform-cli), Kubernetes operations (use kubectl-cli), Helm charts (use helm-cli)."
---

## When to Use
- Azure resource queries
- AKS cluster management
- Key Vault operations
- ACR management
- RBAC configuration

## Prerequisites
- Azure CLI installed
- Authenticated: az login or managed identity
- Subscription selected
- Appropriate RBAC roles

## Commands

### Context
```bash
# Show current account
az account show -o table

# List subscriptions
az account list -o table --query "[].{Name:name, ID:id, State:state}"

# Set subscription
az account set --subscription "<subscription-id>"
```

### Resource Queries
```bash
# List resources in RG
az resource list -g <resource-group> -o table

# Show resource
az resource show --ids <resource-id>

# Query with JMESPath
az resource list -g <rg> --query "[?type=='Microsoft.ContainerService/managedClusters']"
```

### AKS Operations
```bash
# Get credentials
az aks get-credentials -g <rg> -n <cluster> --overwrite-existing

# Show cluster
az aks show -g <rg> -n <cluster> -o table

# Node pools
az aks nodepool list -g <rg> --cluster-name <cluster> -o table

# Scale cluster
az aks scale -g <rg> -n <cluster> --node-count 5
```

### Key Vault
```bash
# List secrets (names only)
az keyvault secret list --vault-name <kv> -o table --query "[].{Name:name}"

# Get secret
az keyvault secret show --vault-name <kv> -n <secret> --query value -o tsv
```

### ACR
```bash
# List repositories
az acr repository list -n <acr> -o table

# Show tags
az acr repository show-tags -n <acr> --repository <repo> --orderby time_desc
```

## Best Practices
1. Use -o table for readable output
2. Use -o json for parsing with jq
3. Use --query for filtering
4. Never expose secrets in output
5. Verify subscription before operations

## Output Format
1. Command executed
2. Results in table format
3. Warnings or issues
4. Next steps

## Integration with Agents
Used by: @terraform, @security, @sre, @test
