# Incident Response Runbook

Use this runbook when Backstage, ArgoCD, observability, or Golden Path scaffolding is degraded.

## Triage

1. Identify the impacted user workflow and environment.
2. Check Backstage availability, catalog ingestion, and scaffolder task failures.
3. Check ArgoCD application health and sync status.
4. Check Kubernetes events, pod status, and ingress health.
5. Record timeline, owner, scope, and mitigation steps in the incident channel.

## Recovery

1. Prefer GitOps fixes for application configuration drift.
2. Roll forward with a small, reviewed change when the root cause is known.
3. Roll back only when the previous version is known to be healthy.
4. Validate recovery from the user workflow, not only from infrastructure health checks.

## Post-Incident

1. Capture root cause, contributing factors, and detection gaps.
2. Add tests, alerts, or documentation updates for the missed failure mode.
3. Link follow-up issues to the affected Golden Path or platform component.

## References

- [Microsoft Learn: Azure Well-Architected Framework reliability](https://learn.microsoft.com/azure/well-architected/reliability/)
- [Microsoft Learn: Azure Monitor overview](https://learn.microsoft.com/azure/azure-monitor/overview)
- [Backstage documentation](https://backstage.io/docs/)