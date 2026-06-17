# External Secrets Module

External Secrets Operator with Azure Key Vault integration using Workload Identity.

## Features

- External Secrets Operator via Helm
- Azure Key Vault ClusterSecretStore
- Workload Identity for secure authentication
- Managed identity with federated credentials
- Key Vault access policies or RBAC
- Push secrets support (sync to Key Vault)
- Prometheus metrics

## Usage

```hcl
module "external_secrets" {
  source = "./modules/external-secrets"

  customer_name       = "threehorizons"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  namespace           = "external-secrets"

  aks_cluster_name = module.aks.cluster_name
  key_vault_id     = module.security.key_vault_id
  key_vault_uri    = module.security.key_vault_uri

  eso_chart_version = "0.9.11"

  # Use RBAC instead of access policies
  use_key_vault_rbac = true

  # Enable Prometheus metrics
  enable_prometheus_metrics = true

  # Optional: Create example secret
  create_example_secret = false

  # Optional: Enable push secrets
  enable_push_secrets = false

  # Node placement
  node_selector = {
    "kubernetes.io/os" = "linux"
  }

  tolerations = []

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| namespace | Kubernetes namespace | `string` | `"external-secrets"` | no |
| aks_cluster_name | AKS cluster name | `string` | n/a | yes |
| key_vault_id | Key Vault resource ID | `string` | n/a | yes |
| key_vault_uri | Key Vault URI | `string` | n/a | yes |
| eso_chart_version | ESO Helm chart version | `string` | `"0.9.11"` | no |
| use_key_vault_rbac | Use RBAC instead of access policies | `bool` | `false` | no |
| enable_prometheus_metrics | Enable Prometheus metrics | `bool` | `true` | no |
| create_example_secret | Create example ExternalSecret | `bool` | `false` | no |
| enable_push_secrets | Enable PushSecret support | `bool` | `false` | no |
| node_selector | Node selector for pods | `map(string)` | `{}` | no |
| tolerations | Tolerations for pods | `list(object)` | `[]` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | ESO namespace |
| secret_store_name | ClusterSecretStore name |
| identity_client_id | ESO managed identity client ID |
| identity_principal_id | ESO managed identity principal ID |

## Creating ExternalSecrets

After deployment, create ExternalSecrets in your namespaces:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secret
  namespace: my-app
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: threehorizons-prod-secret-store
  target:
    name: my-secret
    creationPolicy: Owner
  data:
    - secretKey: database-password
      remoteRef:
        key: postgresql-admin-password
```

## Workload Identity

The module configures:
1. User-assigned managed identity for ESO
2. Federated identity credential linked to ESO service account
3. Key Vault access (via access policies or RBAC)

This enables secretless authentication from ESO to Key Vault.
