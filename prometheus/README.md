# Open Horizons Platform - Prometheus Rules

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** SRE, Platform Engineers

## Overview

This directory contains Prometheus alerting and recording rules for platform observability.

## Files

| File | Description |
|------|-------------|
| `alerting-rules.yaml` | Alert definitions for infrastructure and application health |
| `recording-rules.yaml` | Pre-computed recording rules for dashboard performance |

## Usage

Rules are loaded by Prometheus via the monitoring Helm chart. They are applied automatically during deployment:

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f deploy/helm/monitoring/values.yaml
```

## 📚 Related Documentation

| Document | Description |
|----------|-------------|
| [Grafana Dashboards](../grafana/README.md) | Dashboard definitions consuming these rules |
| [Performance Tuning Guide](../docs/guides/PERFORMANCE_TUNING_GUIDE.md) | Monitoring baselines and tuning |
| [Incident Response Runbook](../docs/runbooks/incident-response.md) | How to respond to fired alerts |

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
