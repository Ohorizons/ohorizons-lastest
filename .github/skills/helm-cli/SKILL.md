---
name: helm-cli
description: "Helm CLI operations for Kubernetes package management. USE FOR: helm install, helm upgrade, helm rollback, Helm chart management, Helm values, Helm repo add. DO NOT USE FOR: kubectl operations (use kubectl-cli), ArgoCD sync (use argocd-cli), Terraform IaC (use terraform-cli)."
---

## When to Use
- Helm chart development and testing
- Chart linting and validation
- Template rendering preview
- Release management

## Prerequisites
- Helm 3.x installed
- Kubernetes context configured
- Access to chart repositories

## Commands

### Chart Development
```bash
# Lint chart
helm lint ./chart

# Template rendering
helm template release-name ./chart -f values.yaml

# Dry-run install
helm install release-name ./chart -f values.yaml --dry-run
```

### Repository Operations
```bash
# Add repository
helm repo add <name> <url>

# Update repositories
helm repo update

# Search charts
helm search repo <keyword>
```

### Release Management
```bash
# List releases
helm list -A

# Install chart
helm install <release> <chart> -f values.yaml -n <namespace>

# Upgrade release
helm upgrade <release> <chart> -f values.yaml -n <namespace>

# Rollback release
helm rollback <release> <revision> -n <namespace>
```

## Best Practices
1. ALWAYS lint charts before deploying
2. Use --dry-run to preview changes
3. Keep values.yaml files in version control
4. Use semantic versioning for charts
5. Document chart dependencies

## Output Format
1. Command executed
2. Validation results
3. Template output (if applicable)
4. Next steps

## Integration with Agents
Used by: @devops, @platform, @sre
