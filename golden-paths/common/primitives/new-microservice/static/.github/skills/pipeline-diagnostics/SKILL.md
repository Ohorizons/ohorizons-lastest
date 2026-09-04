---
name: pipeline-diagnostics
description: Diagnose GitHub Actions workflow failures and recommend focused CI/CD fixes.
---

# Pipeline Diagnostics Skill

## Checklist
- Identify the failing workflow, job, and step before changing files.
- Check required secrets, permissions, runner image, and tool versions.
- Prefer the smallest workflow or configuration change that fixes the failure.
- Re-run the relevant workflow or local equivalent when possible.

## Output
Report the failed step, root cause, remediation, and validation result.
