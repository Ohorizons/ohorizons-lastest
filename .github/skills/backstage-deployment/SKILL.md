---
name: backstage-deployment
description: "Deploys the upstream open-source Backstage developer portal on Azure AKS or locally via Docker Desktop. USE FOR: deploy Backstage, Backstage on AKS, Backstage local Docker, Backstage Helm chart, Backstage PostgreSQL, Backstage ACR image, Backstage GitHub OAuth. DO NOT USE FOR: Backstage plugin development (use @platform), Golden Path template creation (use @platform), Azure infrastructure provisioning (use @azure-portal-deploy)."
---

# Backstage Deployment Skill

Deploys the upstream open-source Backstage developer portal on Azure AKS or locally via Docker Desktop.

> **Official Docs via MCP:** Use `backstagedocs_*` tools from the mcp-ecosystem for live official documentation:
> - `backstagedocs_get_page slug=deployment/docker` — Docker deployment guide
> - `backstagedocs_get_page slug=deployment/k8s` — Kubernetes deployment guide
> - `backstagedocs_get_page slug=auth/github/provider` — GitHub auth provider docs
> - `backstagedocs_search query="app-config"` — search configuration docs

---

## Scope

| Aspect | Detail |
|--------|--------|
| **Platform** | Azure AKS (production) or Docker Desktop + kind (local) |
| **Region** | East US 2 (`eastus2`) — PostgreSQL in Central US (`centralus`) |
| **Image** | Custom-built from `backstage/` directory, stored in ACR |
| **Auth** | GitHub OAuth + Guest (dev only) |
| **Catalog** | H1 Foundation + H2 Enhancement Golden Paths pre-loaded |
| **Used by** | `@backstage-expert`, `@deploy`, `@platform` |

---

## Azure MVP Deployment (`rg-backstage-demo`)

### Resources

| Resource | Name | Type | Location |
|----------|------|------|----------|
| AKS | `aks-backstage-demo` | 2x Standard_B2s | eastus2 |
| ACR | `acrbackstagedemo` | Basic | eastus2 |
| Key Vault | `kv-backstage-demo` | RBAC-enabled | eastus2 |
| PostgreSQL | `pgbackstagedemo` | Flexible B1ms v16 | centralus |
| Redis | `redis-backstage-demo` | Azure Managed B0 | eastus2 |
| AI Services | `ai-backstage-demo` | S0 (GPT-4o + Embeddings) | eastus2 |
| Log Analytics | `law-backstage-demo` | PerGB2018 | eastus2 |
| App Insights | `appi-backstage-demo` | Application Insights | eastus2 |
| Managed Prometheus | `prometheus-backstage-demo` | Azure Monitor Workspace | eastus2 |
| Managed Grafana | `grafana-backstage-demo` | Standard tier | eastus2 |
| Monitor | Container Insights + Metrics | Enabled on AKS | eastus2 |
| Defender | Containers + KV + OSS DB | Standard tier | subscription |
| Action Group | `ag-backstage-sre` | Webhook → GitHub | eastus2 |
| Metric Alerts | CPU > 85%, Memory > 85% | Severity 2 | global |

### Service Principal

| Name | Roles |
|------|-------|
| `sp-backstage-demo` | Contributor (RG), KV Secrets User, AI OpenAI User |

### Kubernetes Components

| Horizon | Namespace | Component |
|---------|-----------|-----------|
| H1 | `ingress-nginx` | NGINX Ingress + Azure LB |
| H1 | `cert-manager` | cert-manager v1.14 |
| H1 | `gatekeeper-system` | OPA Gatekeeper v3.14 |
| H1 | `external-secrets` | ESO v2.0 → Key Vault |
| H2 | `argocd` | ArgoCD v2.10 |
| H2 | `monitoring` | Prometheus + Grafana + Alertmanager |
| H2 | `backstage` | Backstage (custom ACR image v1.0.0) |

### External URLs

| Service | URL |
|---------|-----|
| Backstage | `http://backstage.<LB-IP>.sslip.io` |
| ArgoCD | `http://argocd.<LB-IP>.sslip.io` |
| Grafana | `http://grafana.<LB-IP>.sslip.io` |
| Prometheus | `http://prometheus.<LB-IP>.sslip.io` |
| Alertmanager | `http://alertmanager.<LB-IP>.sslip.io` |

---

## 1. Prerequisites

### CLI Tools
```bash
# Required
az --version        # >= 2.55
terraform --version # >= 1.5
kubectl version     # >= 1.28
helm version        # >= 3.13
docker --version    # >= 24.0
node --version      # >= 20.0
yarn --version      # >= 4.0
gh auth status      # GitHub CLI authenticated
```

### Azure
```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az provider register -n Microsoft.ContainerService
az provider register -n Microsoft.KeyVault
az provider register -n Microsoft.Storage
```

---

### Configuration Files
| File | Purpose |
|------|---------|
| `backstage/app-config.yaml` | Development config |
| `backstage/app-config.production.yaml` | Production config (baked into image) |

---

## 2. Azure AKS Deployment

### Terraform
```bash
cd terraform

# Initialize
terraform init -backend-config=environments/dev-backend.hcl

# Plan
terraform plan \
  -var-file=environments/dev.tfvars \
  -var="portal_name=<client-portal-name>" \
  -var="location=centralus"

# Apply
terraform apply \
  -var-file=environments/dev.tfvars \
  -var="portal_name=<client-portal-name>" \
  -var="location=centralus"
```

### Module: `terraform/modules/backstage/`
Provisions:
- Helm release for `backstage/backstage` chart
- Custom image from ACR
- PostgreSQL Flexible Server integration
- GitHub App secret in Key Vault
- Ingress with TLS (cert-manager)

### Region Validation
```hcl
variable "location" {
  type    = string
  validation {
    condition     = contains(["centralus", "eastus"], var.location)
    error_message = "Only Central US and East US are supported."
  }
}
```

---

## 4. GitHub App Setup

### Create GitHub App
```bash
./scripts/setup-github-app.sh --target backstage --org <GITHUB_ORG>
```

### Manual Creation
1. Go to `https://github.com/organizations/<ORG>/settings/apps/new`
2. Set:
   - **Homepage URL:** `https://<portal-url>`
   - **Callback URL:** `https://<portal-url>/api/auth/github/handler/frame`
   - **Webhook:** Disable (not needed for auth)
3. Permissions:
   - `contents: read`
   - `metadata: read`
   - `pull_requests: write`
   - `members: read`
4. Generate Private Key (.pem file)
5. Note: App ID, Client ID, Client Secret

### Configure in Backstage
Environment variables:
```
GITHUB_APP_ID=<numeric-app-id>
GITHUB_APP_CLIENT_ID=<client-id>
GITHUB_APP_CLIENT_SECRET=<client-secret>
GITHUB_APP_PRIVATE_KEY=<contents-of-pem-file>
```

---

## 5. Golden Path Templates

### Valid Templates (YAML-compatible with Backstage parser)
| Template | Horizon | Description |
|----------|---------|-------------|
| `api-microservice` | H2 | FastAPI microservice with PostgreSQL |
| `ado-to-github-migration` | H2 | Azure DevOps to GitHub migration |
| `copilot-extension` | H3 | GitHub Copilot Extension |
| `rag-application` | H3 | RAG application with Azure AI |

### Registration
Templates are registered via `catalog.locations` in `app-config.production.yaml`:
```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/<org>/<repo>/blob/main/golden-paths/<horizon>/<template>/template.yaml
      rules:
        - allow: [Template]
```

---

## 6. Codespaces Integration

Each Golden Path template skeleton includes a `.devcontainer/devcontainer.json` that configures:
- Base image with required SDKs
- VS Code extensions for the template type
- Port forwarding for development servers
- Post-create setup scripts

### Example: Python Microservice
```json
{
  "name": "Python Microservice",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",
  "features": {
    "ghcr.io/devcontainers/features/azure-cli:1": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python", "ms-python.pylint", "redhat.vscode-yaml"]
    }
  },
  "postCreateCommand": "pip install -r requirements.txt",
  "forwardPorts": [8000]
}
```

---

## 7. Troubleshooting

### Backstage pod not starting
```bash
kubectl logs -n backstage -l app.kubernetes.io/name=backstage --tail=50
kubectl describe pod -n backstage -l app.kubernetes.io/name=backstage
```

### Templates not loading
```bash
# Check for YAML parse errors
kubectl logs -n backstage -l app.kubernetes.io/name=backstage | grep 'YAML error'

# Verify catalog locations
kubectl exec -n backstage deploy/backstage -- cat /app/app-config.production.yaml | grep -A 2 'locations'
```

### GitHub auth not working
```bash
# Test auth endpoint
kubectl exec -n backstage deploy/backstage -- \
  node -e "fetch('http://localhost:7007/api/auth/github/start?env=development',{redirect:'manual'}).then(r=>console.log(r.status))"
# Expected: 302
```

### Database connection
```bash
kubectl exec -n backstage deploy/backstage -- \
  node -e "fetch('http://localhost:7007/.backstage/health/v1/readiness').then(r=>console.log(r.status))"
# Expected: 200
```
