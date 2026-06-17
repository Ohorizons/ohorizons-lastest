# ${{values.name}}

${{values.description}}

## Overview

GitOps deployment configuration for Kubernetes applications using ArgoCD.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Deployment Tool | ArgoCD |

## Features

- Multi-environment deployment (dev, staging, prod)
- Kustomize overlays for environment-specific configs
- Automated sync with Git repository
- Rollback capabilities
- Sync waves for ordered deployments
- Health checks and status monitoring

## Directory Structure

```
apps/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    ├── staging/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

## Environments

| Environment | Namespace | Auto-Sync | Pruning |
|-------------|-----------|-----------|---------|
| Development | ${{values.name}}-dev | Enabled | Enabled |
| Staging | ${{values.name}}-staging | Enabled | Enabled |
| Production | ${{values.name}}-prod | Disabled | Disabled |

## Deployment

```bash
# View application status
argocd app get ${{values.name}}-dev

# Sync application
argocd app sync ${{values.name}}-dev

# View diff before sync
argocd app diff ${{values.name}}-dev

# Rollback to previous version
argocd app rollback ${{values.name}}-dev
```

## Configuration

### Kustomize Patches

Each environment overlay can customize:
- Replica count
- Resource limits
- Environment variables
- ConfigMap values
- Ingress settings

## Monitoring

- ArgoCD sync status in Backstage
- Deployment health checks
- Git commit tracking

## Links

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Guide](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
