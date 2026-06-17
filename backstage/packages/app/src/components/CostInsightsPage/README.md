# Cost Insights Page

Cloud cost monitoring dashboard that wraps the `@backstage-community/plugin-cost-insights` with an Open Horizons hero banner for consistent portal UX.

## Features

- Hero banner with cost summary (Monthly Spend, Savings, Resources, Efficiency)
- Full Cost Insights plugin interface for detailed cost analysis
- Cloud spending monitoring and anomaly detection
- Resource allocation visibility across services
- Cost optimization recommendations

## Screenshot Path

`/docs/assets/screenshots/cost-insights-page.png` (placeholder)

## Configuration

Requires the `@backstage-community/plugin-cost-insights` plugin to be configured with a cost data provider in `app-config.yaml`:

```yaml
costInsights:
  engineerCost: 200000
  products:
    computeEngine:
      name: Compute Engine
    cloudStorage:
      name: Cloud Storage
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage-community/plugin-cost-insights` | `CostInsightsPage` component |
| `@material-ui/core` | Styling and icons |
| `../shared/HeroBanner` | Shared hero banner component |

## Usage

**Route:** `/cost-insights`

```text
Navigate to: Backstage → Cost Insights
```
