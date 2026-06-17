# Tech Insights Page

Custom tech health scorecards page that fetches real catalog entities from the Backstage backend and evaluates them against 8 quality checks. Replaces the native `@backstage-community/plugin-tech-insights` with a purpose-built implementation.

## Features

- **Live Catalog Evaluation** — Fetches components from `/api/catalog/entities?filter=kind=component` and runs checks in real time
- **8 Quality Checks**:
  - Has Description, Has Owner, Has Tags, Has Lifecycle
  - Has TechDocs, Has System, Has Type, Has Source
- **HeroBanner** — Dynamic stats: Health Score (%), Components count, Checks count, Passing ratio
- **Overview Cards** — Top 4 checks with percentage bars and pass/fail counts
- **All Checks Detail** — 2-column grid with per-entity pass/fail breakdown for each check
- **Entity Scorecard Matrix** — Cross-reference table: all components vs. all checks with letter grades (A–F)
- **Re-evaluate Button** — Manual refresh to re-run all checks
- **Loading State** — Circular progress spinner during data fetch
- **Color-coded Grades** — Green (≥80%), Blue (≥60%), Yellow (≥40%), Red (<40%)

## Screenshot Path

`/docs/assets/screenshots/tech-insights-page.png` (placeholder)

## Configuration

Requires the Backstage backend catalog API to be accessible:

```yaml
# app-config.yaml
backend:
  baseUrl: http://localhost:7007  # Used to call /api/catalog/entities
```

The component reads `backend.baseUrl` from the Backstage config API.

## Dependencies

- `@backstage/core-components` — Page, Content
- `@backstage/core-plugin-api` — configApiRef, useApi
- `@material-ui/core` — CircularProgress, Chip, LinearProgress, Tooltip, IconButton, Typography
- `@material-ui/icons` — ScoreIcon, CheckCircleIcon, CancelIcon, RefreshIcon, and others
- `../shared/HeroBanner` — Hero banner component
- `../shared/StyledCard` — Styled card component

## Usage

**Route:** `/tech-insights`

Access via the Engineering Hub or navigate directly to `/tech-insights`.
