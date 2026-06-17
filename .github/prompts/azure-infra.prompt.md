---
description: "Provision Azure infrastructure for developer portal — AKS, Key Vault, PostgreSQL, ACR. USE FOR: provision AKS cluster, create Key Vault, deploy PostgreSQL, create ACR, Azure portal infrastructure."
agent: "azure-portal-deploy"
---

# Provision Azure Infrastructure

Provision the Azure infrastructure required for the Open Horizons developer portal.

## Input

- **Environment**: Target environment (dev, staging, prod)
- **Region**: Azure region (default: eastus2)
- **Components**: Which to provision (AKS, Key Vault, PostgreSQL, ACR, all)

## Expected Output

- Resources provisioned via Azure CLI or Terraform
- Connection strings and endpoints verified
- Ready for Backstage deployment
