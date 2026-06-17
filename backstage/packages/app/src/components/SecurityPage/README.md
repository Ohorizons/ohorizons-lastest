# Security Page

GitHub Advanced Security (GHAS) dashboard showing Dependabot alerts, Code Scanning results, and Secret Scanning status. Fetches live data from the GitHub API and AI Impact backend.

## Features

- Hero banner with security posture summary
- Dependabot vulnerability alerts by severity (critical, high, medium, low)
- Code Scanning (CodeQL) alert aggregation with trend charts
- Secret Scanning status and leaked secret tracking
- Severity distribution pie chart (Recharts)
- Alert trend line chart over time
- Detailed alert table with links to GitHub
- `EntityCodeQualityContent` component for entity page integration
- Copilot Autofix availability indicators

## Screenshot Path

`/docs/assets/screenshots/security-page.png` (placeholder)

## Configuration

Requires the GitHub API and AI Impact proxies in `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/github-api':
      target: https://api.github.com
    '/ai-impact':
      target: http://127.0.0.1:8011
```

GitHub Advanced Security must be enabled on the target repositories.

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage/core-components` | `Page`, `Content` layout |
| `@backstage/core-plugin-api` | `configApiRef` for backend URL |
| `@backstage/plugin-catalog-react` | `useEntity` (EntityCodeQualityContent) |
| `@material-ui/core` | UI components and icons |
| `recharts` | Pie and line charts |
| `../shared/HeroBanner` | Shared hero banner component |
| `../shared/StyledCard` | Shared card component |

## Usage

**Route:** `/security`

```text
Navigate to: Backstage → Security
```

Entity tab: Add `<EntityCodeQualityContent />` to entity page layouts.
