# ArgoCD Module

ArgoCD GitOps deployment on AKS with HA support, GitHub SSO, and notifications.

## Features

- ArgoCD HA deployment (3 replicas)
- GitHub SSO integration via Dex
- RBAC with Azure AD groups
- ApplicationSet controller
- Slack/Teams notifications
- Prometheus metrics
- Ingress with TLS
- Redis HA for state

## Usage

```hcl
module "argocd" {
  source = "./modules/argocd"

  customer_name = "threehorizons"
  environment   = "prod"
  namespace     = "argocd"
  domain_name   = "example.com"

  ha_enabled    = true
  chart_version = "5.51.6"

  # GitHub SSO
  github_org                = "my-org"
  github_app_client_id      = var.github_client_id
  github_app_client_secret  = var.github_client_secret

  # Admin password (bcrypt hash)
  admin_password_hash = var.argocd_admin_password_hash

  # Notifications
  slack_webhook_url = var.slack_webhook_url
  teams_webhook_url = var.teams_webhook_url

  # Ingress
  ingress_class   = "nginx"
  cluster_issuer  = "letsencrypt-prod"

  tags = module.naming.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |
| kubectl | ~> 1.14 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| customer_name | Customer name | `string` | n/a | yes |
| environment | Environment | `string` | n/a | yes |
| namespace | Kubernetes namespace | `string` | `"argocd"` | no |
| domain_name | Base domain for ArgoCD | `string` | n/a | yes |
| ha_enabled | Enable HA mode | `bool` | `true` | no |
| chart_version | ArgoCD Helm chart version | `string` | `"5.51.6"` | no |
| github_org | GitHub organization | `string` | n/a | yes |
| github_app_client_id | GitHub App client ID | `string` | n/a | yes |
| github_app_client_secret | GitHub App client secret | `string` | n/a | yes |
| admin_password_hash | Admin password bcrypt hash | `string` | n/a | yes |
| slack_webhook_url | Slack webhook URL | `string` | `""` | no |
| teams_webhook_url | Teams webhook URL | `string` | `""` | no |
| ingress_class | Ingress class name | `string` | `"nginx"` | no |
| cluster_issuer | Cert-manager cluster issuer | `string` | `"letsencrypt-prod"` | no |

## Outputs

| Name | Description |
|------|-------------|
| argocd_url | ArgoCD web UI URL |
| argocd_namespace | ArgoCD namespace |
| platform_project_name | Platform AppProject name |

## RBAC Configuration

Default RBAC policy:
- `platform-admins` group: Full admin access
- All org members: Read-only access
- Team members: Sync and manage their applications

## Notification Templates

Pre-configured notifications:
- `app-deployed`: Successful deployment notification
- `app-sync-failed`: Failed sync notification
- Custom templates can be added via Helm values
