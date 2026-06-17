# Copilot Analytics Page

Deep analytics view for GitHub Copilot adoption, code acceptance rates, and AI-assisted developer velocity. Wraps the `@backstage-community/plugin-copilot` with an Open Horizons hero banner.

## Features

- Hero banner with Copilot analytics summary (Active Users, Acceptance Rate, Suggestions, Efficiency)
- Full `CopilotIndexPage` from the Backstage community plugin
- Detailed Copilot usage charts and breakdowns provided by the plugin
- Consistent Open Horizons UX styling via wrapper

## Screenshot Path

`/docs/assets/screenshots/copilot-analytics-page.png` (placeholder)

## Configuration

Requires the `@backstage-community/plugin-copilot` plugin to be installed and configured. See the plugin documentation for GitHub App setup and required permissions.

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage-community/plugin-copilot` | `CopilotIndexPage` component |
| `@material-ui/core` | Styling |
| `../shared/HeroBanner` | Shared hero banner component |

## Usage

**Route:** Not currently routed in `App.tsx`. Available as an importable component for integration.

```typescript
import CopilotAnalyticsPage from './components/CopilotAnalyticsPage/CopilotAnalyticsPage';
```
