# Contributing to Open Horizons Platform

Thank you for your interest in contributing to the Open Horizons Platform! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

## Code of Conduct

This project follows a standard code of conduct. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites

- Azure subscription with appropriate permissions
- GitHub account
- Git configured with GPG signing (recommended)
- Tools installed:
  - Terraform >= 1.5.0
  - Azure CLI >= 2.50
  - kubectl >= 1.28
  - Helm >= 3.12
  - Python >= 3.11 (for scripts)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:

   ```bash
   git clone https://github.com/YOUR-USERNAME/agentic-devops-platform.git
   cd agentic-devops-platform
   ```

3. Add upstream remote:

   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/agentic-devops-platform.git
   ```

## Development Setup

### 1. Install Pre-commit Hooks (Required)

Pre-commit hooks ensure code quality and security before commits. This is the most important step for contributing.

```bash
# Quick setup (pre-commit only)
./scripts/setup-pre-commit.sh

# Full setup with all tools
./scripts/setup-pre-commit.sh --install-tools
```

**What the hooks check:**

| Category | Checks |
| :--- | :--- |
| Terraform | Format, validate, TFLint, TFSec, Checkov, Terraform-docs |
| Shell | ShellCheck, shfmt formatting |
| Kubernetes | Kubeconform validation |
| YAML/JSON | Syntax validation, yamllint |
| Markdown | markdownlint |
| Python | Black, isort, Flake8 |
| Secrets | Gitleaks, detect-secrets |
| Commits | Conventional commit format |

**Manual hook commands:**

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run terraform_fmt --all-files

# Update hooks to latest versions
pre-commit autoupdate

# Skip hooks (emergency only - not recommended)
git commit --no-verify -m "message"
```

### 2. Verify Tools

```bash
# Verify Terraform
terraform version

# Verify Azure CLI
az version
```

### 3. Configure Azure Authentication

```bash
az login
az account set --subscription "your-subscription-id"
```

### 4. Initialize Terraform (for local development)

```bash
cd terraform
terraform init -backend=false
```

## Making Changes

### Branch Naming

Use descriptive branch names:

- `feature/add-new-module` - New features
- `fix/networking-issue` - Bug fixes
- `docs/update-readme` - Documentation
- `refactor/improve-aks-module` - Refactoring

### Commit Messages

Follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

Types:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `infra`: Infrastructure changes

Examples:

```
feat(aks): add support for spot node pools

Add configuration for Azure Spot VMs in AKS node pools
to reduce costs for non-critical workloads.

Closes #123
```

## Pull Request Process

### 1. Create Your Branch

```bash
git checkout -b feature/your-feature
```

### 2. Make Your Changes

- Write clean, well-documented code
- Follow coding standards
- Add tests if applicable
- Update documentation

### 3. Test Your Changes

```bash
# Terraform validation
cd terraform
terraform fmt -recursive
terraform validate

# Run scripts
./scripts/validate-deployment.sh --dry-run
```

### 4. Commit and Push

```bash
git add .
git commit -m "feat(scope): your change description"
git push origin feature/your-feature
```

### 5. Create Pull Request

- Use the PR template
- Fill in all sections
- Link related issues
- Request reviews from appropriate teams

### 6. Address Review Feedback

- Respond to all comments
- Make requested changes
- Re-request review when ready

## Coding Standards

### Terraform

```hcl
# Use consistent naming
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = local.common_tags
}

# Document variables
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Kubernetes Manifests

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
  labels:
    app.kubernetes.io/name: my-service
    app.kubernetes.io/instance: my-service-prod
    app.kubernetes.io/version: "1.0.0"
spec:
  # Always set resource limits
  containers:
    - name: my-service
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
```

### Shell Scripts

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script description
# Usage: ./script.sh [options]

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    # Implementation
}

main "$@"
```

## Testing Guidelines

### Terraform

```bash
# Format check
terraform fmt -check -recursive

# Validate
terraform validate

# Plan (with test variables)
terraform plan -var-file=test.tfvars
```

### Scripts

```bash
# ShellCheck
shellcheck scripts/*.sh

# Test execution
./scripts/validate-deployment.sh --dry-run
```

### Documentation

- Verify all links work
- Check markdown formatting
- Ensure examples are accurate

## Documentation

### When to Update Docs

- Adding new features
- Changing existing behavior
- Adding new modules or templates
- Updating configuration options

### Documentation Files

| File | Purpose |
| :--- | :--- |
| `README.md` | Project overview |
| `AGENTS.md` | **Agent System Overview** (17 Copilot Chat Agents) |
| `docs/guides/*.md` | Comprehensive guides |
| `module/README.md` | Module-specific docs |

### Documentation Style

- Use clear, concise language
- Include code examples
- Add diagrams where helpful (Mermaid)
- Keep up to date with code changes

## Getting Help

- **Questions**: Open a Discussion
- **Bugs**: Open an Issue with the bug template
- **Features**: Open an Issue with the feature template
- **Security**: See [SECURITY.md](SECURITY.md)

## Recognition

Contributors will be recognized in:

- Release notes
- CONTRIBUTORS.md (for significant contributions)
- Project documentation

Thank you for contributing to the Open Horizons Platform!
