# Azure OIDC Setup

Generated repositories use GitHub Actions OIDC to authenticate to Azure without long-lived credentials.

## One-Time Setup

Run this from the generated repository after `az login` and `gh auth login`:

```bash
./scripts/setup-azure-oidc.sh \
  --resource-group <resource-group> \
  --create-resource-group
```

The script creates or reuses an Entra app registration, adds federated credentials for the `dev`, `staging`, and `prod` GitHub environments, assigns Azure RBAC on the resource group, and writes these repository secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

## Custom Environments

```bash
./scripts/setup-azure-oidc.sh \
  --resource-group <resource-group> \
  --environments dev,prod
```

## Dry Run

```bash
./scripts/setup-azure-oidc.sh \
  --resource-group <resource-group> \
  --dry-run
```

The dry run prints the planned Azure CLI and GitHub CLI commands without modifying anything. Use it to confirm scope before granting permissions.

## Repository-Level Setup

The Open Horizons platform repository ships its own helper at [scripts/setup-identity-federation.sh](../../../../scripts/setup-identity-federation.sh) that supports federation for the `main` branch and pull requests. Use the generated repo helper above only for application repositories created from a Golden Path.

## References

- [GitHub Actions OIDC with Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)
- [GitHub encrypted secrets](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions)
- [Azure role assignments](https://learn.microsoft.com/azure/role-based-access-control/role-assignments-cli)
