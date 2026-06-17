# ${{values.name}}

${{values.description}}

## Overview

Security baseline configuration including policies, RBAC, and compliance controls.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |

## Features

- Azure Policy definitions
- Kubernetes network policies
- RBAC configurations
- OPA/Gatekeeper constraints
- Security scanning configurations

## Components

### Azure Policies
- Resource tagging requirements
- Allowed resource types
- Allowed regions
- Encryption requirements

### Kubernetes Policies
- Pod security standards
- Network isolation
- Resource limits
- Image policies

### Compliance
- CIS benchmarks
- NIST frameworks
- LGPD compliance

## Getting Started

### Prerequisites

- Azure subscription with Policy permissions
- Kubernetes cluster with Gatekeeper

### Deployment

```bash
# Deploy Azure policies
az policy definition create --name ${{values.name}} --rules policies/azure/

# Deploy Kubernetes policies
kubectl apply -f policies/kubernetes/
```

## Structure

```
policies/
├── azure/
│   ├── tagging.json
│   ├── encryption.json
│   └── network.json
├── kubernetes/
│   ├── pod-security.yaml
│   ├── network-policy.yaml
│   └── resource-limits.yaml
└── gatekeeper/
    ├── templates/
    └── constraints/
```

## Validation

```bash
# Test Azure policies
az policy state list --policy-set-definition ${{values.name}}

# Test Kubernetes policies
kubectl get constraints
```

## Links

- [Azure Policy](https://docs.microsoft.com/azure/governance/policy/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
