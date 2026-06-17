# Engineering Page

Central command hub for all engineering operations. Provides quick access to platform tools (Tech Insights, Cost Insights, Copilot Analytics, Validation) and displays recent deployment history and active CI/CD pipelines.

## Features

- **HeroBanner** — Displays key stats: Services (142), Uptime (99.9%), Efficiency (92.4%), Security (Elite)
- **Engineering Tools Grid** — 4 tool cards with status badges, metrics, and launch buttons linking to respective pages
  - Tech Insights → `/tech-insights`
  - Cost Insights → `/cost-insights`
  - Copilot Analytics → `/copilot`
  - Validation → `/entity-validation`
- **Recent Deployments** — 5 latest deployments with environment, status, and timestamp
- **Active Pipelines** — 4 in-progress CI/CD pipelines with stage name and progress bar
- **Hover animations** — Cards lift on hover with enhanced shadow effects

## Screenshot Path

`/docs/assets/screenshots/engineering-page.png` (placeholder)

## Configuration

No additional configuration required. Deployment and pipeline data is currently static/demo data defined in the component.

## Dependencies

- `@backstage/core-components` — Page, Content
- `@material-ui/core` — Chip
- `@material-ui/icons` — BuildIcon, ScoreIcon, AttachMoneyIcon, and others
- `react-router-dom` — RouterLink for tool navigation
- `../shared/HeroBanner` — Hero banner component
- `../shared/StyledCard` — Styled card component

## Usage

**Route:** `/engineering`

Access via the Backstage sidebar or navigate directly to `/engineering`.
