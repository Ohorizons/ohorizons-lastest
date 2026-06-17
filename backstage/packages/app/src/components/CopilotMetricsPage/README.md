# Copilot Metrics Page

Developer productivity dashboard showing GitHub developer activity and Copilot billing/usage metrics using real data from the GitHub API and AI Impact backend.

## Features

- Hero banner with Copilot productivity summary
- Developer activity metrics from GitHub API (commits, PRs, reviews)
- Copilot seat and billing information
- Acceptance rate and suggestion volume tracking
- Per-language breakdown of Copilot usage
- GitHub Auth integration for authenticated API calls
- Proxy-based data fetching via AI Impact backend

## Screenshot Path

`/docs/assets/screenshots/copilot-metrics-page.png` (placeholder)

## Configuration

Requires the AI Impact proxy in `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/ai-impact':
      target: http://127.0.0.1:8011
```

GitHub authentication must be configured for the GitHub API calls.

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage/core-components` | `Page`, `Content` layout |
| `@backstage/core-plugin-api` | `githubAuthApiRef`, `identityApiRef` |
| `@material-ui/core` | UI components and icons |
| `../shared/HeroBanner` | Shared hero banner component |
| `../shared/StyledCard` | Shared card component |

## Usage

**Route:** `/copilot-metrics`

```text
Navigate to: Backstage → Copilot Metrics
```
