# Open Horizons Platform - Grafana Dashboards

> **Version:** 4.0.0
> **Last Updated:** March 2026
> **Audience:** SRE, Platform Engineers

## Overview

This directory contains Grafana dashboard JSON definitions provisioned via the monitoring stack.

## Dashboards

| Dashboard | File | Description |
|-----------|------|-------------|
| Platform Overview | `dashboards/platform-overview.json` | Cluster health, node metrics, pod status |
| Cost Management | `dashboards/cost-management.json` | Resource cost tracking and optimization |
| Golden Path Application | `dashboards/golden-path-application.json` | Application-level metrics for Golden Path services |

## Usage

Dashboards are automatically provisioned when the monitoring stack is deployed. They can also be imported manually via the Grafana UI.

## 📚 Related Documentation

| Document | Description |
|----------|-------------|
| [Performance Tuning Guide](../docs/guides/PERFORMANCE_TUNING_GUIDE.md) | Monitoring and performance baselines |
| [Prometheus Rules](../prometheus/README.md) | Alerting and recording rules |
| [Deployment Guide](../docs/guides/DEPLOYMENT_GUIDE.md) | Monitoring stack deployment steps |

---

**Document Version:** 2.0.0
**Last Updated:** March 2026
**Maintainer:** Platform Engineering Team
