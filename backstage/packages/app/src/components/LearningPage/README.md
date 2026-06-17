# Learning Page

Centralized learning hub that provides curated resources, platform documentation links, and a step-by-step onboarding checklist for developers new to the Open Horizons platform.

## Features

- **AI & Developer Tools** — Resource cards for GitHub Copilot, Azure AI Foundry, and AI Agents & Copilots with external documentation links
- **Platform Resources** — Quick-access cards linking to internal platform pages (Architecture docs, Golden Paths, API Registry, Service Catalog, Catalog Graph, Notifications)
- **Onboarding Checklist** — 5-step getting started guide (Sign in → Explore Catalog → Create Service → Open Codespaces → Read TechDocs)
- Branded logo images for each AI tool card
- Uses the shared `StandardPage` layout component

## Screenshot Path

`/docs/assets/screenshots/learning-page.png` (placeholder)

## Configuration

No additional configuration required. All resource links are hardcoded in the component.

External documentation links point to:
- `docs.github.com` (GitHub Copilot)
- `learn.microsoft.com` (Azure AI Foundry, Agent Framework)

## Dependencies

- `react-router-dom` — Internal navigation links
- `@material-ui/core` — UI components (Grid, Card, Button, Typography)
- `@material-ui/icons` — OpenInNewIcon for external links
- `../layout/StandardPage` — Shared page layout wrapper

## Usage

**Route:** `/learning`

Access via the Backstage sidebar or navigate directly to `/learning`.
