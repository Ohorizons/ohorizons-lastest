# ${{values.name}}

${{values.description}}

## Overview

Reusable GitHub Actions workflows library for standardized CI/CD patterns.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |

## Features

- Reusable workflow templates
- Composite actions for common tasks
- Organization-wide CI/CD standards
- Security scanning integration
- Multi-language support
- Versioned releases

## Directory Structure

```
.github/
├── workflows/
│   ├── ci-build.yaml         # Reusable CI workflow
│   ├── cd-deploy.yaml        # Reusable CD workflow
│   ├── security-scan.yaml    # Security scanning
│   └── release.yaml          # Release automation
└── actions/
    ├── setup-environment/    # Composite action
    ├── run-tests/            # Test runner action
    └── deploy-to-aks/        # AKS deployment action
```

## Available Workflows

| Workflow | Description | Trigger |
|----------|-------------|---------|
| `ci-build.yaml` | Build and test | `workflow_call` |
| `cd-deploy.yaml` | Deploy to environment | `workflow_call` |
| `security-scan.yaml` | Security analysis | `workflow_call` |
| `release.yaml` | Create release | `workflow_call` |

## Usage

### Calling a Reusable Workflow

```yaml
name: CI
on:
  push:
    branches: [main]

jobs:
  build:
    uses: ${{values.org}}/${{values.name}}/.github/workflows/ci-build.yaml@v1
    with:
      language: python
      test-command: pytest
    secrets: inherit
```

### Using a Composite Action

```yaml
steps:
  - uses: ${{values.org}}/${{values.name}}/.github/actions/setup-environment@v1
    with:
      python-version: '3.11'
```

## Workflow Inputs

### ci-build.yaml

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `language` | Yes | - | Programming language |
| `test-command` | No | `make test` | Test command |
| `coverage-threshold` | No | `80` | Minimum coverage |

## Versioning

This library follows semantic versioning:
- `@v1` - Latest v1.x release
- `@v1.2.3` - Specific version
- `@main` - Latest development

## Contributing

1. Create feature branch
2. Add/modify workflows
3. Test in sample repository
4. Create pull request

## Links

- [GitHub Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
