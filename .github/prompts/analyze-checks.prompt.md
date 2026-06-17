---
description: "Analyze CI check runs and PR quality — shows passing/failing checks, coverage status, and merge readiness."
agent: "sentinel"
---

# Analyze Test Coverage & Checks

Analyze CI check runs and pull request quality for the specified repository.

## Input
- **Repository:** ${input:repo_name:Repository name}
- **Branch or PR number:** ${input:ref_or_pr:Branch, commit, or PR number}

## Instructions

1. Read the [Test Coverage Skill](../skills/test-coverage/SKILL.md)
2. If a PR number is provided:
   - Use `gh pr checks ${input:ref_or_pr} --repo Ohorizons/${input:repo_name}` to get check status
   - Use `gh pr view ${input:ref_or_pr} --repo Ohorizons/${input:repo_name}` for PR details
3. If a branch is provided:
   - Use `gh api repos/Ohorizons/${input:repo_name}/commits/${input:ref_or_pr}/check-runs` for checks
4. Analyze passing/failing checks and provide recommendations

## Output Format

Provide results using templates from the Test Coverage skill:
- Check Run Analysis (summary, failed checks table, recommendations)
- PR Quality Report (checks, reviews, merge readiness) — if analyzing a PR
