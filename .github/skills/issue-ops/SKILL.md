---
name: issue-ops
description: "GitHub Issue-driven operations dispatcher — maps slash commands in issue comments to automation scripts. USE FOR: slash command dispatch, issue ops automation, /onboard command, /validate command, /check-agents command, IssueOps workflow. DO NOT USE FOR: GitHub Actions workflows (use @devops), manual script execution (use validation-scripts), Backstage deployment (use backstage-deployment)."
---

# Issue Ops Dispatcher

Maps slash commands posted in GitHub issue comments to automation scripts, enabling ChatOps-style workflows directly from GitHub Issues.

## Supported Commands

| Command | Script | Description |
|---------|--------|-------------|
| `/onboard <team_name>` | `backstage-deployment/scripts/onboard-team.sh` | Onboard a new team |
| `/validate` | `validation-scripts/scripts/validate-deployment.sh` | Validate deployment status |
| `/check-agents` | `validation-scripts/scripts/validate-agents.py` | Validate agent definitions |

## How It Works

1. A GitHub Actions workflow triggers on `issue_comment` events
2. The `dispatcher.py` script parses the first line for a slash command
3. If matched, it runs the corresponding script with provided arguments
4. Output is posted back as a comment on the issue

## Usage

```bash
# In a GitHub issue comment:
/onboard platform-team
/validate --environment dev
/check-agents
```

## Security

- Only commands in the `COMMAND_MAP` are allowed — no arbitrary execution
- Arguments are validated and sanitized via `shlex` before passing to subprocess
- Scripts must exist at the mapped path or execution fails safely

## Quality Checklist

- [ ] All slash commands map to existing scripts
- [ ] Arguments are sanitized (no shell injection)
- [ ] Unknown commands return helpful error messages
- [ ] Output is posted back to the issue comment thread
- [ ] GitHub Actions workflow triggers on `issue_comment` created events
