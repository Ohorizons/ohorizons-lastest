# Platform Status Page

Real-time health telemetry dashboard for the Open Horizons platform. Displays service health across Kubernetes namespaces, ArgoCD sync status, and key infrastructure metrics.

## Features

- **HeroBanner** — Key stats: Global Uptime (99.99%), Active Nodes, Avg Latency (42ms), Incidents (0)
- **Health Metric Cards** — 4 summary cards:
  - Services Healthy (count/total)
  - Degraded Services (with dynamic warning state)
  - Average Latency (42ms, P95: 125ms)
  - Uptime 30-day (99.99%)
- **Platform Services Table** — 8 services with columns: Service, Namespace, Status, Version, Replicas, Latency
  - Covers Backstage Portal, ArgoCD, Prometheus, Grafana, PostgreSQL, Ingress NGINX, Cert Manager, External Secrets
- **ArgoCD Applications Table** — 5 apps with Sync status, Health status, Revision (monospace), and last updated time
  - Color-coded badges: Synced/OutOfSync, Healthy/Degraded
- **StatusOK / StatusWarning** — Uses Backstage built-in status indicator components
- **Live refresh indicator** — Footer notes showing last check time

## Screenshot Path

`/docs/assets/screenshots/platform-status-page.png` (placeholder)

## Configuration

No additional configuration required. Service and ArgoCD data is currently static/demo data defined in the component.

## Dependencies

- `@backstage/core-components` — Page, Content, StatusOK, StatusWarning
- `@material-ui/core` — Grid
- `@material-ui/icons` — SpeedIcon, CheckCircleIcon, ErrorIcon, CloudIcon, and others
- `../shared/HeroBanner` — Hero banner component
- `../shared/StyledCard` — Styled card component

## Usage

**Route:** `/platform-status`

Access via the Backstage sidebar or navigate directly to `/platform-status`.
