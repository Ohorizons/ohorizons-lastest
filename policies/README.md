# Policy as Code

This directory contains policy definitions for enforcing security and compliance standards across the Open Horizons Platform.

## Overview

Policies are implemented using:

- **OPA Gatekeeper** - For Kubernetes admission control
- **Conftest** - For Terraform and YAML validation in CI/CD

## Directory Structure

```
policies/
├── README.md                    # This file
├── kubernetes/                  # Kubernetes/Gatekeeper policies
│   ├── constraint-templates/    # Gatekeeper ConstraintTemplates
│   └── constraints/             # Gatekeeper Constraints
└── terraform/                   # Terraform policies (Conftest/OPA)
    └── *.rego                   # Rego policy files
```

## Kubernetes Policies (Gatekeeper)

### Installation

Gatekeeper is deployed via ArgoCD:

```bash
# Check Gatekeeper status
kubectl get pods -n gatekeeper-system

# View constraints
kubectl get constraints
```

### Available Policies

| Policy | Description | Enforcement |
|--------|-------------|-------------|
| `require-labels` | Require standard Kubernetes labels | deny |
| `require-resource-limits` | Require CPU/memory limits | deny |
| `deny-privileged` | Block privileged containers | deny |
| `require-non-root` | Require non-root user | deny |
| `deny-host-namespace` | Block host namespace access | deny |
| `allowed-repos` | Restrict container registries | deny |
| `require-probes` | Require readiness/liveness probes | warn |

### Testing Policies Locally

```bash
# Install Gatekeeper CLI
brew install gator

# Test policies against manifests
gator test -f policies/kubernetes/constraint-templates/ \
           -f policies/kubernetes/constraints/ \
           -f deploy/

# Verify template syntax
gator verify policies/kubernetes/constraint-templates/
```

## Terraform Policies (Conftest)

### Running Conftest

```bash
# Install conftest
brew install conftest

# Test Terraform plans
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json -p policies/terraform/

# Test HCL files directly
conftest test terraform/ -p policies/terraform/ --all-namespaces
```

### Available Terraform Policies

| Policy | Description |
|--------|-------------|
| `require-tags` | Require mandatory resource tags |
| `deny-public-access` | Block public endpoints |
| `require-encryption` | Enforce encryption at rest |
| `require-https` | Enforce HTTPS-only |

## Writing New Policies

### Gatekeeper ConstraintTemplate

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Missing required labels: %v", [missing])
        }
```

### Rego Policy for Terraform

```rego
package terraform.azure

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  not resource.change.after.min_tls_version == "TLS1_2"
  msg := sprintf("Storage account %s must use TLS 1.2", [resource.address])
}
```

## CI/CD Integration

Policies are automatically enforced in CI:

1. **Pull Request** - Policies run as warnings
2. **Merge to Main** - Policies block deployment on violations

See `.github/workflows/ci.yml` for integration details.

## Exceptions

To exempt a resource from a policy:

### Kubernetes

```yaml
metadata:
  annotations:
    policies.open-horizons.io/exempt: "require-labels"
```

### Terraform

```hcl
# conftest:ignore:require-tags
resource "azurerm_resource_group" "legacy" {
  # ...
}
```

## References

- [OPA Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/)
- [Conftest Documentation](https://www.conftest.dev/)
- [Rego Language Reference](https://www.openpolicyagent.org/docs/latest/policy-language/)
