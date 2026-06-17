---
name: pipeline-diagnostics
description: "GitHub Actions CI/CD diagnostics — workflow run analysis, job/step failure identification, and remediation patterns. USE FOR: diagnose pipeline, workflow failure, build error, deploy failure, GitHub Actions troubleshooting, CI/CD debug. DO NOT USE FOR: test analysis (use test-coverage), Kubernetes operations (use kubectl-cli), Helm charts (use helm-cli)."
---

# Pipeline Diagnostics Skill

Domain knowledge for the **@pipeline** agent — CI/CD diagnostics via GitHub Actions API.

## GitHub Actions API Reference

### Workflow Runs

```bash
# List recent runs (all statuses)
gh run list --repo {owner}/{repo} --limit 10

# Filter by status
gh run list --repo {owner}/{repo} --status failure --limit 5

# View specific run details
gh run view {run_id} --repo {owner}/{repo}

# View failed job logs
gh run view {run_id} --repo {owner}/{repo} --log-failed

# Re-run failed jobs
gh run rerun {run_id} --repo {owner}/{repo} --failed
```

### REST API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/repos/{owner}/{repo}/actions/runs` | GET | List workflow runs |
| `/repos/{owner}/{repo}/actions/runs/{id}` | GET | Get specific run |
| `/repos/{owner}/{repo}/actions/runs/{id}/jobs` | GET | Get jobs for a run |
| `/repos/{owner}/{repo}/actions/runs/{id}/logs` | GET | Download run logs |

### Run Status Values

| Status | Meaning |
|--------|---------|
| `queued` | Run is waiting to be picked up |
| `in_progress` | Run is currently executing |
| `completed` | Run has finished (check conclusion) |

### Run Conclusion Values

| Conclusion | Meaning | Action |
|-----------|---------|--------|
| `success` | All jobs passed | No action needed |
| `failure` | One or more jobs failed | Investigate failed steps |
| `cancelled` | Run was cancelled | Check if manual or timeout |
| `skipped` | Run was skipped (path filter, condition) | Review trigger conditions |
| `timed_out` | Run exceeded time limit | Optimize or increase timeout |

## Common Failure Patterns

### 1. Dependency Install Failures
**Symptoms:** `npm ci`, `yarn install`, or `pip install` step fails
**Causes:** Lock file out of sync, registry down, version conflicts
**Remediation:**
1. Check if `package-lock.json` / `yarn.lock` is committed
2. Compare lock file with `package.json` versions
3. Check npm/PyPI registry status
4. Clear caches and re-run

### 2. Build/Compile Errors
**Symptoms:** `tsc`, `go build`, `dotnet build` step fails
**Causes:** Type errors, missing imports, breaking API changes
**Remediation:**
1. Read the error message from the failed step output
2. Identify the file and line number
3. Suggest specific code fix
4. Recommend running build locally first

### 3. Test Failures
**Symptoms:** `jest`, `pytest`, `go test` step fails
**Causes:** Flaky tests, environment differences, assertion failures
**Remediation:**
1. Identify which tests failed
2. **Handoff to @sentinel** for detailed test analysis
3. Check if tests pass locally

### 4. Docker Build Failures
**Symptoms:** `docker build` or `docker push` step fails
**Causes:** Missing base image, COPY source not found, registry auth
**Remediation:**
1. Check Dockerfile COPY paths match repo structure
2. Verify base image exists and tag is valid
3. Check registry credentials in secrets

### 5. Deployment Failures
**Symptoms:** `kubectl apply`, `helm upgrade`, or `az webapp deploy` fails
**Causes:** Cluster unreachable, image pull error, resource limits
**Remediation:**
1. Check cluster connectivity (credentials, RBAC)
2. Verify image exists in registry
3. Check resource quotas and limits

## Output Template

```markdown
## 🔍 Pipeline Diagnosis

**Repository:** {owner}/{repo}
**Workflow:** {workflow_name}
**Run:** #{run_number} ({run_id})
**Branch:** {branch} | **Event:** {event} | **Status:** {conclusion}

### Failed Jobs

| Job | Step | Status | Duration |
|-----|------|--------|----------|
| {job_name} | {step_name} | ❌ {conclusion} | {duration} |

### Root Cause
{analysis}

### Remediation Steps
1. {step_1}
2. {step_2}
3. {step_3}

### Recommended Handoff
- {handoff_recommendation}
```

## Quality Checklist

- [ ] Fetched real workflow run data before diagnosing
- [ ] Identified specific failed job and step
- [ ] Provided root cause analysis
- [ ] Included actionable remediation steps
- [ ] Suggested handoff when appropriate (@sentinel for tests, @terraform for infra)
- [ ] Used output template format
