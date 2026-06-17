---
name: deploy-orchestration
description: "End-to-end platform deployment orchestration — prerequisites, Terraform, Kubernetes verification, and troubleshooting. USE FOR: full platform deployment, deployment sequence, prerequisite validation, post-deploy verification, deployment troubleshooting. DO NOT USE FOR: Terraform modules (use terraform-cli), Kubernetes operations (use kubectl-cli), CI/CD pipelines (use @devops)."
---

## When to Use
- Full platform deployment (new environment)
- Adding horizons to an existing deployment (e.g., enabling H3)
- Post-deployment verification
- Deployment troubleshooting

## Prerequisites
- Azure CLI authenticated (`az login`)
- GitHub CLI authenticated (`gh auth login`)
- All tools installed (run `./scripts/validate-prerequisites.sh`)
- Environment `.tfvars` configured

## Deployment Phases

### Phase 0: Initial Setup (Wizard)
```bash
# Interactive setup — collects org, domain, auth, Azure, AI config
scripts/install-wizard.sh

# This writes .env and optionally renders K8s manifests.
# For CI/CD (non-interactive):
scripts/install-wizard.sh --auto --selection-file .openhorizons-selection.yaml
```

### Phase 0b: Render K8s Manifests
```bash
# Generate manifests from templates using .env values
scripts/render-k8s.sh

# Dry-run to preview without writing:
scripts/render-k8s.sh --dry-run
```

### Phase 1: Prerequisites
```bash
./scripts/validate-prerequisites.sh
```

### Phase 2: Azure Setup
```bash
# Login
az login
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Register providers
for provider in Microsoft.ContainerService Microsoft.ContainerRegistry \
  Microsoft.KeyVault Microsoft.Network Microsoft.ManagedIdentity \
  Microsoft.Security Microsoft.CognitiveServices Microsoft.Monitor; do
  az provider register --namespace "$provider"
done
```

### Phase 2: Terraform Backend (first time only)
```bash
./scripts/setup-terraform-backend.sh \
  --customer-name contoso \
  --environment dev \
  --location brazilsouth
```

### Phase 3: Configuration
```bash
# Copy template and edit
cp terraform/terraform.tfvars.example terraform/environments/dev.tfvars
# Edit with your values

# Set sensitive vars
export TF_VAR_azure_subscription_id="..."
export TF_VAR_azure_tenant_id="..."
export TF_VAR_admin_group_id="..."
export TF_VAR_github_org="..."
export TF_VAR_github_token="..."

# Validate
./scripts/validate-config.sh --environment dev
```

### Phase 4: Deploy
```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars -out=deploy.tfplan
terraform apply deploy.tfplan
```

### Phase 5: Verify
```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name "$(terraform output -raw aks_cluster_name)"

# Run validation
./scripts/validate-deployment.sh --environment dev
```

### Phase 6: Post-Deployment
```bash
# Access ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit https://localhost:8080

# Access Grafana
kubectl port-forward svc/prometheus-grafana -n observability 3000:80
# Visit http://localhost:3000
```

## Automated Deployment
```bash
# Full deployment
./scripts/deploy-full.sh --environment dev

# Dry run (plan only)
./scripts/deploy-full.sh --environment dev --dry-run

# Deploy specific horizon
./scripts/deploy-full.sh --environment dev --horizon h1

# CI/CD mode (no prompts)
./scripts/deploy-full.sh --environment prod --auto-approve

# Resume after failure
./scripts/deploy-full.sh --environment dev --resume

# Destroy
./scripts/deploy-full.sh --environment dev --destroy
```

## Environment Configurations

| Environment | Mode | Estimated Cost | Features |
|-------------|------|----------------|----------|
| dev | express | $50-100/month | Minimal: AKS + ACR + ArgoCD + Observability |
| staging | standard | $500-1000/month | Production-like: + Databases + ESO + Defender + AI |
| prod | enterprise | $3000+/month | Full HA: + DR + Purview + Runners + Backstage + Cost Mgmt |

## Deployment Modes

| Mode | Nodes | HA | GPU | Best For |
|------|-------|----|-----|----------|
| express | 3 × D4s | No | No | Development, testing |
| standard | 5 × D4s | Yes | No | Production workloads |
| enterprise | 10 × D8s + workload pool | Yes (3 zones) | Optional | Enterprise, multi-tenant |

## Troubleshooting

### Terraform init fails
```bash
# Clear cache and retry
rm -rf terraform/.terraform terraform/.terraform.lock.hcl
terraform init -upgrade
```

### Terraform plan fails with variable errors
```bash
# Verify all required vars are set
./scripts/validate-config.sh --environment <env>
```

### AKS cluster unreachable
```bash
# Refresh credentials
az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing
kubectl get nodes
```

### ArgoCD not starting
```bash
kubectl get pods -n argocd
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

## Rollback

### Rollback H3 only
```bash
# Disable AI Foundry
# Set enable_ai_foundry = false in tfvars
terraform plan -var-file=environments/<env>.tfvars -out=rollback.tfplan
terraform apply rollback.tfplan
```

### Complete teardown
```bash
./scripts/deploy-full.sh --environment <env> --destroy
```
