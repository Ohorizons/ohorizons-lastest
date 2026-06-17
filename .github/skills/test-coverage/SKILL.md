---
name: test-coverage
description: "Test coverage and quality gate analysis — CI check runs, PR review status, coverage reports, and test improvement recommendations. USE FOR: check runs analysis, test coverage, PR checks, quality gate, test failures, coverage diff, failing checks, test quality. DO NOT USE FOR: pipeline diagnostics (use pipeline-diagnostics), writing tests (use @test agent), code review (use @reviewer)."
---

# Test Coverage Skill

Domain knowledge for the **@sentinel** agent — test and coverage analysis via GitHub Checks and PRs API.

## GitHub Checks API Reference

### Check Runs

```bash
# Get check runs for a branch
gh api repos/{owner}/{repo}/commits/{ref}/check-runs --jq '.check_runs[] | {name, status, conclusion}'

# Get check runs for a PR
gh pr checks {pr_number} --repo {owner}/{repo}

# Get specific check run details
gh api repos/{owner}/{repo}/check-runs/{check_run_id}
```

### REST API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/repos/{owner}/{repo}/commits/{ref}/check-runs` | GET | List check runs for a ref |
| `/repos/{owner}/{repo}/check-runs/{id}` | GET | Get specific check run |
| `/repos/{owner}/{repo}/check-suites/{id}/check-runs` | GET | List check runs in a suite |

### Check Run Status Values

| Status | Meaning |
|--------|---------|
| `queued` | Check is waiting to start |
| `in_progress` | Check is running |
| `completed` | Check finished (see conclusion) |

### Check Run Conclusion Values

| Conclusion | Meaning | Severity |
|-----------|---------|----------|
| `success` | All checks passed | OK |
| `failure` | Check failed | Critical |
| `neutral` | Check ran but has no pass/fail | Info |
| `cancelled` | Check was cancelled | Warning |
| `skipped` | Check was skipped | Info |
| `timed_out` | Check exceeded time limit | Critical |
| `action_required` | Manual action needed | Warning |

## Pull Request Analysis

### PR API

```bash
# List open PRs
gh pr list --repo {owner}/{repo} --state open

# Get PR details with checks
gh pr view {pr_number} --repo {owner}/{repo}

# Get PR review status
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --jq '.[].state'
```

### PR Review States

| State | Meaning |
|-------|---------|
| `APPROVED` | Reviewer approved |
| `CHANGES_REQUESTED` | Reviewer wants changes |
| `COMMENTED` | Reviewer left comments only |
| `PENDING` | Review not submitted |

## Common Test Failure Patterns

### 1. Flaky Tests
**Indicators:** Same test passes/fails intermittently, timing-dependent assertions
**Recommendations:**
- Add retry logic for network-dependent tests
- Use deterministic test data
- Isolate tests from shared state

### 2. Environment Mismatches
**Indicators:** Tests pass locally but fail in CI
**Recommendations:**
- Use the same Node/Python/Go version in CI as locally
- Check for CI-specific env vars
- Use Docker-based CI for consistency

### 3. Coverage Regressions
**Indicators:** Coverage percentage dropped below threshold
**Recommendations:**
- Identify uncovered lines/branches added in the PR
- Add tests for new code paths
- Review coverage thresholds in CI config

### 4. Required Check Failures
**Indicators:** PR merge blocked by failing required checks
**Recommendations:**
- Fix the failing check (don't bypass)
- If check is flawed, update the check configuration
- Contact admin if check is incorrectly required

## Output Templates

### Check Run Analysis

```markdown
## 🧪 Check Run Analysis

**Repository:** {owner}/{repo}
**Ref:** {branch/commit}

### Summary
- ✅ **Passing:** {pass_count}
- ❌ **Failing:** {fail_count}
- ⏭️ **Skipped:** {skip_count}

### Failed Checks

| Check | Conclusion | Output |
|-------|-----------|--------|
| {name} | ❌ {conclusion} | {output_title} |

### Recommendations
1. {recommendation_1}
2. {recommendation_2}
```

### PR Quality Report

```markdown
## 📋 PR Quality Report

**PR:** #{number} — {title}
**Author:** {author} | **Base:** {base} ← **Head:** {head}

### Checks
| Check | Status |
|-------|--------|
| {check_name} | {status_emoji} {conclusion} |

### Reviews
| Reviewer | State |
|----------|-------|
| {reviewer} | {state} |

### Merge Readiness
- {readiness_assessment}
```

## Quality Checklist

- [ ] Fetched real check run data before analyzing
- [ ] Showed conclusion status for each check (success/failure/neutral/skipped)
- [ ] Flagged failing required checks prominently
- [ ] Provided specific improvement recommendations
- [ ] Suggested handoff when appropriate (@pipeline for workflow issues, @test for new tests)
- [ ] Used output template format
