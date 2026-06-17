# ${{values.name}}

${{values.description}}

## Overview

Project migrated from Azure DevOps to GitHub using the Open Horizons migration template.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Source | Azure DevOps |

## Migration Checklist

- [x] Repository migrated with history
- [x] Pipelines converted to GitHub Actions
- [x] Work items linked
- [x] Branch policies configured
- [x] Secrets migrated to GitHub

## GitHub Actions Workflows

| Workflow | Original ADO Pipeline |
|----------|----------------------|
| ci.yaml | build-pipeline.yml |
| cd.yaml | release-pipeline.yml |

## Links

- [Migration Guide](https://docs.github.com/migrations)
- [ADO to GitHub Actions](https://docs.github.com/actions/migrating-to-github-actions)
