# Validation Page

Entity schema validation page that wraps the `@backstage-community/plugin-entity-validation` plugin with a custom HeroBanner displaying governance compliance metrics.

## Features

- **HeroBanner** — Governance stats: Pass Rate (98%), Entities (142), Violations (3), Policies (18)
- **Entity Validation Plugin** — Embeds the full `EntityValidationPage` from the Backstage community plugin for schema validation, ownership rules, and catalog integrity checks
- **Consistent Styling** — Applies the Open Horizons design system background and spacing

## Screenshot Path

`/docs/assets/screenshots/validation-page.png` (placeholder)

## Configuration

The entity validation plugin requires the `@backstage-community/plugin-entity-validation` package to be installed and configured in the Backstage backend.

No additional `app-config.yaml` entries are needed for the frontend wrapper.

## Dependencies

- `@backstage-community/plugin-entity-validation` — Core validation plugin (EntityValidationPage)
- `@material-ui/core` — makeStyles
- `@material-ui/icons` — VerifiedUserIcon, CheckCircleIcon, ErrorIcon, AssessmentIcon, SecurityIcon
- `../shared/HeroBanner` — Hero banner component

## Usage

**Route:** `/entity-validation`

Access via the Engineering Hub or navigate directly to `/entity-validation`.

> **Note:** The route in `App.tsx` is `/entity-validation`, not `/validation`.
