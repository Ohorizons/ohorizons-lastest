# Deployment Runbook

Use this runbook for planned Open Horizons platform deployments.

## Pre-Deployment

1. Confirm the target environment and branch.
2. Run prerequisite and configuration validation scripts.
3. Review Terraform, Kubernetes, Backstage, and Golden Path changes.
4. Confirm rollback options for each changed component.

## Deployment

1. Apply infrastructure changes through the approved Terraform workflow.
2. Sync platform applications through GitOps.
3. Deploy Backstage and agent API images using explicit version tags.
4. Register or refresh catalog locations after Golden Path changes.

## Validation

1. Validate Backstage login and catalog visibility.
2. Create a test component from at least one changed Golden Path.
3. Confirm TechDocs renders for generated catalog entities.
4. Check ArgoCD, Prometheus, and Grafana health views.

## References

- [Open Horizons Deployment Guide](../guides/DEPLOYMENT_GUIDE.md)
- [Backstage deployment documentation](https://backstage.io/docs/deployment/)
- [Terraform CLI documentation](https://developer.hashicorp.com/terraform/cli)