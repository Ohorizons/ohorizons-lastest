# Tech Debt Page

Technical debt aggregator that collects TODO/FIXME/HACK annotations from GitHub Code Search and tech-debt labeled GitHub Issues into a unified dashboard.

## Features

- Hero banner with tech debt health summary
- Metric cards: total annotations, open issues, debt health score
- Annotation breakdown by type (TODO, FIXME, HACK) with counts
- Pie chart for annotation type distribution (Recharts)
- Bar chart for debt by repository
- Detailed annotation table with file paths and links to GitHub
- GitHub Issues integration for `tech-debt` labeled issues
- Live data fetching from GitHub API via backend proxy

## Screenshot Path

`/docs/assets/screenshots/tech-debt-page.png` (placeholder)

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
| `@material-ui/core` | UI components and icons |
| `recharts` | Pie and bar charts |
| `../shared/HeroBanner` | Shared hero banner component |
| `../shared/StyledCard` | Shared card component |

## Usage

**Route:** `/tech-debt`

```text
Navigate to: Backstage → Tech Debt
```
