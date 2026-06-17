---
description: "Analyze CI check runs and PR quality — shows passing/failing checks, coverage status, and merge readiness."
mode: "agent"
agent: "sentinel"
---

# Analyze Test Coverage & Checks

Analyze CI check runs and pull request quality for the specified repository.

## Input
- **Repository:** {{repo_name}}
- **Branch or PR number:** {{ref_or_pr}}

## Instructions

1. Read the [Test Coverage Skill](../skills/test-coverage/SKILL.md)
2. If a PR number is provided:
   - Use `gh pr checks {{ref_or_pr}} --repo Ohorizons/{{repo_name}}` to get check status
   - Use `gh pr view {{ref_or_pr}} --repo Ohorizons/{{repo_name}}` for PR details
3. If a branch is provided:
   - Use `gh api repos/Ohorizons/{{repo_name}}/commits/{{ref_or_pr}}/check-runs` for checks
4. Analyze passing/failing checks and provide recommendations

## Output Format

Provide results using templates from the Test Coverage skill:
- Check Run Analysis (summary, failed checks table, recommendations)
- PR Quality Report (checks, reviews, merge readiness) — if analyzing a PR
