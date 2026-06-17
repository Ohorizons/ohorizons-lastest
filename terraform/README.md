# Terraform Infrastructure

> **A solution created in partnership with Microsoft and GitHub**

This directory contains the Terraform configuration for the Open Horizons Platform infrastructure.

## Directory Structure

```
terraform/
├── main.tf                    # Root module - orchestrates all modules
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider versions
├── terraform.tfvars.example   # Example configuration
├── backend.tf.example         # Backend configuration example
├── modules/                   # Reusable modules
│   ├── aks-cluster/          # Azure Kubernetes Service
│   ├── ai-foundry/           # Azure AI services
│   ├── argocd/               # GitOps configuration
│   ├── backstage/            # Backstage Developer Portal
│   ├── container-registry/   # Azure Container Registry
│   ├── cost-management/      # Cost optimization
│   ├── databases/            # PostgreSQL, Redis, Cosmos DB
│   ├── defender/             # Microsoft Defender
│   ├── disaster-recovery/    # Backup and DR
│   ├── external-secrets/     # External Secrets Operator
│   ├── github-runners/       # Self-hosted runners
│   ├── naming/               # Naming conventions
│   ├── networking/           # VNet, subnets, NSGs
│   ├── observability/        # Monitoring stack
│   ├── purview/              # Data governance
│   └── security/             # Key Vault, identities
└── examples/                  # Example configurations
```

## Quick Start

### 1. Prerequisites

```bash
# Verify tools
terraform --version  # >= 1.6.0
az --version         # >= 2.50.0
```

### 2. Configure Backend

```bash
cp backend.tf.example backend.tf
# Edit backend.tf with your storage account details
```

### 3. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

### 4. Initialize

```bash
terraform init
```

### 5. Plan and Apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Module Overview (16 modules)

| Module | Horizon | Description |
|--------|---------|-------------|
| **naming** | - | Azure naming conventions (CAF compliant) |
| **networking** | H1 | VNet, subnets, NSGs, private DNS |
| **security** | H1 | Key Vault, managed identities, RBAC |
| **aks-cluster** | H1 | AKS with workload identity |
| **backstage** | H2 | Backstage Developer Portal on AKS |
| **container-registry** | H1 | ACR with geo-replication |
| **databases** | H1 | PostgreSQL, Redis, Cosmos DB |
| **defender** | H1 | Microsoft Defender for Cloud |
| **argocd** | H2 | GitOps controller |
| **observability** | H2 | Prometheus, Grafana, Loki |
| **github-runners** | H2 | Self-hosted CI/CD runners |
| **external-secrets** | H2 | External Secrets Operator |
| **ai-foundry** | H3 | Azure OpenAI, AI Search |
| **purview** | H3 | Microsoft Purview governance |
| **cost-management** | - | Cost analysis and budgets |
| **disaster-recovery** | - | Velero backup configuration |

## Configuration Reference

### Required Variables

| Variable | Description |
|----------|-------------|
| `project_name` | Project identifier |
| `environment` | Environment (dev/staging/prod) |
| `location` | Azure region |
| `github_org` | GitHub organization |

### Optional Features

```hcl
# Enable/disable features
enable_ai_foundry     = true   # Azure OpenAI
enable_defender       = true   # Microsoft Defender
enable_purview        = false  # Data governance
enable_github_runners = true   # Self-hosted runners
```

## State Management

- Backend: Azure Storage Account
- Locking: Azure Blob lease
- Versioning: Enabled for rollback

## Deployment Order

1. **Foundation** (H1): networking → security → aks-cluster → databases
2. **Enhancement** (H2): argocd → observability → backstage
3. **Innovation** (H3): ai-foundry → purview

## Related Documentation

- [Deployment Guide](../docs/guides/DEPLOYMENT_GUIDE.md)
- [Module Reference](../docs/guides/MODULE_REFERENCE.md)
- [Sizing Profiles](../config/sizing-profiles.yaml)
