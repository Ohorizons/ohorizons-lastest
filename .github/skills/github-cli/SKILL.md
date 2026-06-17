---
name: github-cli
description: "GitHub CLI operations for repository and workflow management. USE FOR: gh repo, gh pr, gh issue, gh workflow, GitHub API, repository management, pull request automation. DO NOT USE FOR: Azure DevOps (use @ado-integration), Terraform (use terraform-cli), Kubernetes (use kubectl-cli)."
---

## When to Use
- GitHub API operations
- Pull request management
- Workflow triggering
- Issue management

## Prerequisites
- GitHub CLI installed and authenticated
- Appropriate repository permissions

## Commands

### Authentication
```bash
# Check auth status
gh auth status

# Login
gh auth login
```

### Repository Operations
```bash
# Clone repository
gh repo clone <owner/repo>

# View repository
gh repo view

# Create repository
gh repo create <name> --public --description "Description"
```

### Pull Request Operations
```bash
# Create PR
gh pr create --title "Title" --body "Description"

# List PRs
gh pr list

# View PR
gh pr view <number>

# Merge PR
gh pr merge <number> --merge
```

### Workflow Operations
```bash
# List workflows
gh workflow list

# Run workflow
gh workflow run <workflow-name>

# View workflow run
gh run view <run-id>

# Watch workflow run
gh run watch <run-id>
```

### Issue Operations
```bash
# Create issue
gh issue create --title "Title" --body "Description"

# List issues
gh issue list

# Close issue
gh issue close <number>
```

## Best Practices
1. Use gh api for advanced operations
2. Set default repository with gh repo set-default
3. Use --json flag for scripting
4. Authenticate with tokens for CI/CD

## Output Format
1. Command executed
2. Operation result
3. URLs for created resources
4. Next steps

## Integration with Agents
Used by: @devops, @reviewer
