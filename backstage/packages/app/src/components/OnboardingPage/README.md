# Onboarding Page

Personalized developer onboarding hub with an interactive checklist, best-practice cards, resource links, and an AI Chat call-to-action. Progress is persisted in browser `localStorage`.

## Features

- **Interactive Checklist** — Tracks onboarding steps (GitHub SSO, explore catalog, review APIs, configure dev env, scaffold service, enable GHAS, connect AI Chat) with toggleable completion state
- **Progress Persistence** — Stores checklist state in `localStorage` under key `oh-onboarding-progress`
- **Best Practices Cards** — 6 practice areas: Agent Architecture, Security-First Development, CI/CD Pipeline Standards, Golden Path Templates, MCP Tool Development, Team Ownership Model
- **Resource Links** — Quick access to platform documentation, API catalog, AI agent guides, learning paths, software catalog guide, and Codespaces setup
- **AI Chat CTA** — Prominent call-to-action to connect with the AI assistant
- **HeroBanner + StyledCard** — Uses shared design-system components for consistent UX
- **Progress Bar** — Visual completion percentage with linear progress indicator

## Screenshot Path

`/docs/assets/screenshots/onboarding-page.png` (placeholder)

## Configuration

No backend configuration required. Checklist progress is stored client-side in `localStorage`.

| Storage Key | Purpose |
|---|---|
| `oh-onboarding-progress` | JSON map of completed checklist item IDs |

## Dependencies

- `@backstage/core-components` — Page, Content, Link
- `@material-ui/core` — Chip, Box, Button, LinearProgress
- `@material-ui/icons` — Various icons for practice cards and resources
- `../shared/HeroBanner` — Hero banner component
- `../shared/StyledCard` — Styled card component

## Usage

**Route:** `/onboarding`

Access via the Backstage sidebar or navigate directly to `/onboarding`.
