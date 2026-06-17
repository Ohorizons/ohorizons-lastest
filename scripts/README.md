# Automation Scripts

> **A solution created in partnership with Microsoft and GitHub**

This directory contains automation scripts for the Open Horizons Platform.

## Script Inventory

### Deployment Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `deploy-full.sh` | **Full automated deployment (recommended)** | `./deploy-full.sh --environment dev` |
| `platform-bootstrap.sh` | Full platform deployment | `./platform-bootstrap.sh --environment dev` |
| `bootstrap.sh` | H1 infrastructure setup | `./bootstrap.sh` |

### Validation Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `validate-prerequisites.sh` | CLI tools verification | `./validate-prerequisites.sh` |
| `validate-config.sh` | Configuration validation | `./validate-config.sh --config terraform.tfvars` |
| `validate-deployment.sh` | Post-deployment health check | `./validate-deployment.sh --environment prod` |
| `validate-agents.sh` | Agent specifications validation | `./validate-agents.sh` |
| `validate-docs.sh` | Documentation validation | `./validate-docs.sh` |

### Setup Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `setup-github-app.sh` | GitHub App configuration | `./setup-github-app.sh` |
| `setup-identity-federation.sh` | OIDC workload identity | `./setup-identity-federation.sh` |
| `setup-pre-commit.sh` | Pre-commit hooks | `./setup-pre-commit.sh` |
| `setup-branch-protection.sh` | GitHub branch rules | `./setup-branch-protection.sh` |
| `setup-terraform-backend.sh` | Terraform state backend setup | `./setup-terraform-backend.sh` |

### Operations Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `onboard-team.sh` | Team onboarding | `./onboard-team.sh --team-name myteam` |

### Migration Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `migration/ado-to-github-migration.sh` | Azure DevOps migration | `./migration/ado-to-github-migration.sh` |

## Quick Reference

### First-Time Setup

```bash
# 1. Check prerequisites
./validate-prerequisites.sh

# 2. Configure GitHub App
./setup-github-app.sh

# 3. Set up identity federation
./setup-identity-federation.sh

# 4. Validate configuration
./validate-config.sh --config ../terraform/terraform.tfvars
```

### Deploy Platform

```bash
# Recommended: Full automated deployment (3 options)
# Option A — Agent-guided:
#   @deploy Deploy the platform to dev environment

# Option B — Automated script:
./deploy-full.sh --environment dev --dry-run
./deploy-full.sh --environment dev

# Option C — Manual:
./platform-bootstrap.sh --environment dev --horizon all

# Deploy specific horizon
./platform-bootstrap.sh --environment dev --horizon h1

# Dry run (preview only)
./platform-bootstrap.sh --environment dev --dry-run
```

### Validate Deployment

```bash
# Quick health check
./validate-deployment.sh --environment prod --quick

# Full validation
./validate-deployment.sh --environment prod --verbose
```

## Script Development

### Standards

- All scripts use `#!/bin/bash`
- Use `set -euo pipefail` for safety
- Include help documentation
- Follow ShellCheck recommendations
- Include exit codes documentation

### Testing

```bash
# Run ShellCheck on all scripts
shellcheck *.sh

# Test script in dry-run mode (where available)
./script.sh --dry-run
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Prerequisites not met |
| 3 | Configuration error |
| 4 | Network error |
| 5 | Authentication error |

## Related Documentation

- [Deployment Guide](../docs/guides/DEPLOYMENT_GUIDE.md)
- [Deployment Runbook](../docs/runbooks/deployment-runbook.md)
