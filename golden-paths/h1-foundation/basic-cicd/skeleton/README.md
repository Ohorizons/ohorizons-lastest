# ${{values.name}}

${{values.description}}

## Overview

This project includes a basic CI/CD pipeline using GitHub Actions.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |

## Pipeline Features

- Automated builds on push/PR
- Unit test execution
- Code linting
- Security scanning
- Docker image building
- Artifact publishing

## Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| CI | Push, PR | Build, test, lint |
| Release | Tag | Build and publish release |
| Security | Schedule | Security scanning |

## Getting Started

1. Clone the repository
2. Configure secrets in GitHub repository settings
3. Push code to trigger the pipeline

## Required Secrets

| Secret | Description |
|--------|-------------|
| REGISTRY_PASSWORD | Container registry password |
| SONAR_TOKEN | SonarQube token (optional) |

## Links

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Open Horizons Platform](https://github.com/${{values.repoUrl | parseRepoUrl | pick('owner') }}/agentic-devops-platform)
