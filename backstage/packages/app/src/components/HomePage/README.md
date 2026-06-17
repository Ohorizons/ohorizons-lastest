# HomePage

Landing page and central command hub for the Open Horizons Agentic DevOps platform. Displays platform-wide KPIs, deployment velocity, system health, recent activity, and quick navigation links.

## Features

- Hero banner with platform overview stats (active projects, deployments, team members, health score)
- KPI stat cards: Active Deployments, Success Rate, Avg. Lead Time, Open Incidents
- Deployment Velocity area chart (weekly trend via Recharts)
- System Health panel showing environment status and uptime (Production, Staging, Dev, QA)
- Recent Activity feed with user actions and pipeline events
- Quick Links grid (Documentation, Cloud Console, Service Catalog, Support Desk)

## Screenshot Path

`/docs/assets/screenshots/home-page.png` (placeholder)

## Configuration

No additional configuration required. Uses static demo data for KPIs and charts.

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage/core-components` | `Page`, `Content` layout |
| `@material-ui/core` | Styling and icons |
| `recharts` | Area chart for deployment velocity |
| `react-router-dom` | Quick link navigation |
| `../shared/HeroBanner` | Shared hero banner component |
| `../shared/StyledCard` | Shared card component |

## Usage

**Route:** `/home` (also redirected from `/`)

```text
Navigate to: Backstage → Home
```
