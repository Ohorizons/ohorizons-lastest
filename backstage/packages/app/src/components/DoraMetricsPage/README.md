# DORA Metrics Page

Dashboard displaying the four key DORA (DevOps Research and Assessment) metrics using real data from the GitHub Actions API. Includes both a standalone page and an entity-scoped tab component.

## Features

- Hero banner with DORA performance summary
- Deployment Frequency metric with daily/weekly/monthly classification
- Lead Time for Changes (PR merge to deploy) with trend visualization
- Change Failure Rate percentage with elite/high/medium/low classification
- Mean Time to Recovery (MTTR) tracking
- Period toggle (30-day / 90-day views)
- Bar and line charts for trend visualization (Recharts)
- Deployment history table with status details
- `EntityDoraContent` component for entity page integration
- Classification system aligned with DORA research (Elite, High, Medium, Low)

## Screenshot Path

`/docs/assets/screenshots/dora-metrics-page.png` (placeholder)

## Configuration

Requires the GitHub API proxy in `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/github-api':
      target: https://api.github.com
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage/core-components` | `Page`, `Content` layout |
| `@backstage/core-plugin-api` | `configApiRef` for backend URL |
| `@backstage/plugin-catalog-react` | `useEntity` (EntityDoraContent) |
| `@material-ui/core` | UI components and icons |
| `recharts` | Bar and line charts |
| `../shared/HeroBanner` | Shared hero banner component |
| `../shared/StyledCard` | Shared card component |

## Usage

**Route:** `/dora-metrics`

```text
Navigate to: Backstage → DORA Metrics
```

Entity tab: Add `<EntityDoraContent />` to entity page layouts.
