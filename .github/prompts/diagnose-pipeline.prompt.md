---
description: "Diagnose a GitHub Actions pipeline failure — fetches real workflow run data and identifies failed steps with remediation."
mode: "agent"
agent: "pipeline"
---

# Diagnose Pipeline Failure

Analyze the most recent GitHub Actions workflow failures for the specified repository.

## Input
- **Repository:** {{repo_name}}
- **Branch (optional):** {{branch}}
- **Run ID (optional):** {{run_id}}

## Instructions

1. Read the [Pipeline Diagnostics Skill](../skills/pipeline-diagnostics/SKILL.md)
2. Use `gh run list --repo Ohorizons/{{repo_name}} --status failure --limit 5` to find recent failures
3. For each failed run, use `gh run view {run_id} --repo Ohorizons/{{repo_name}}` to get details
4. Use `gh run view {run_id} --repo Ohorizons/{{repo_name}} --log-failed` for failed job logs
5. Provide structured diagnosis with root cause and remediation steps

## Output Format

Provide results using the diagnosis template from the Pipeline Diagnostics skill:
- Summary → Failed Jobs → Root Cause → Remediation Steps → Handoff recommendation
