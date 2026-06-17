---
name: kubectl-cli
description: "Kubernetes CLI operations for AKS cluster management. USE FOR: kubectl get, kubectl apply, kubectl describe, pod troubleshooting, service debugging, namespace management. DO NOT USE FOR: Helm charts (use helm-cli), ArgoCD sync (use argocd-cli), Azure resource provisioning (use azure-cli)."
---

## When to Use
- Cluster health verification
- Resource deployment and management
- Troubleshooting pod issues
- Viewing logs and events

## Prerequisites
- kubectl installed and configured
- KUBECONFIG set to valid config
- kubelogin for Azure AD authentication
- Appropriate RBAC permissions

## Commands

### Cluster Health
```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# Unhealthy pods across all namespaces
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
```

### Resource Management
```bash
# Dry-run before apply
kubectl apply -f manifest.yaml --dry-run=client -o yaml

# Diff changes
kubectl diff -f manifest.yaml

# Apply with recording
kubectl apply -f manifest.yaml --record

# Delete with grace
kubectl delete -f manifest.yaml --grace-period=30
```

### Troubleshooting
```bash
# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Pod logs (current)
kubectl logs -f <pod-name> -n <namespace>

# Pod logs (previous crash)
kubectl logs <pod-name> -n <namespace> --previous

# Events by time
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Exec into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

### Resource Queries
```bash
# Get all resources in namespace
kubectl get all -n <namespace> -o wide

# Get resource as YAML
kubectl get deployment <name> -n <namespace> -o yaml

# Resource usage
kubectl top pods -n <namespace>
kubectl top nodes
```

## Best Practices
1. ALWAYS use --dry-run=client before apply
2. ALWAYS specify namespace with -n
3. Use labels for selection: -l app=myapp
4. Check events when pods fail
5. Use kubectl diff for change preview
6. NEVER delete without explicit namespace

## Output Format
1. Command executed
2. Resource status summary
3. Any warnings or errors
4. Recommended actions

## Integration with Agents
Used by: @platform, @devops, @sre, @test
