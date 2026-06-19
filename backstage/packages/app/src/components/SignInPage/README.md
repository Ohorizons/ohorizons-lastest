# Custom Sign-In Page

White-label enterprise sign-in page for the customer developer portal. The page keeps the Microsoft/GitHub/Backstage visual system and Agentic Platform Engineering message while removing demo-only marketing content.

## Features

- **Client-first identity** — Displays `organization.name` and `app.title` from Backstage config.
- **Provider-aware sign-in** — Uses Microsoft Entra ID when the Microsoft auth provider is configured, otherwise falls back to GitHub.
- **Enterprise platform message** — Uses "Agentic Platform Engineering" and secure developer portal language.
- **Microsoft design system colors** — Keeps red, green, blue, yellow, and primary Azure blue accents.
- **Technology signature** — Keeps Microsoft/GitHub logo and Azure, GitHub, Backstage OSS badges.
- **Minimal layout** — Focused sign-in card and concise platform value signals, without demo video, fixed metrics, FAQs, or repository CTAs.
- **No inline styles** — Styling is contained in `makeStyles` for lint cleanliness.

## Screenshot Path

`/docs/assets/screenshots/sign-in-page.png` (placeholder)

## Configuration

Requires the selected provider to be configured in `app-config.yaml`. GitHub OAuth example:

```yaml
auth:
  providers:
    github:
      development:
        clientId: ${GITHUB_CLIENT_ID}
        clientSecret: ${GITHUB_CLIENT_SECRET}
```

| Environment Variable | Purpose |
|---|---|
| `GITHUB_CLIENT_ID` | GitHub OAuth App client ID |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth App client secret |

Microsoft Entra ID example:

```yaml
auth:
  providers:
    microsoft:
      development:
        clientId: ${ENTRA_CLIENT_ID}
        clientSecret: ${ENTRA_CLIENT_SECRET}
        tenantId: ${ENTRA_TENANT_ID}
```

| Environment Variable | Purpose |
|---|---|
| `AUTH_PROVIDER` | Use `entra` for Microsoft Entra ID sign-in |
| `GITHUB_IDENTITY_MODE` | Use `enterprise-managed-users` for GitHub EMU deployments |
| `ENTRA_TENANT_ID` | Microsoft Entra tenant ID |
| `ENTRA_CLIENT_ID` | Backstage App Registration client ID |
| `ENTRA_CLIENT_SECRET` | Backstage App Registration client secret |

GitHub Enterprise Managed Users deployments still require GitHub App or token integration for catalog, scaffolder, Actions, PRs, Codespaces, packages, and AI Impact features.

Branding values:

```yaml
app:
  title: ${PORTAL_NAME:-Developer Portal}
  branding:
    logo: ${PORTAL_LOGO_URL:-/logo-msft-github.png}
organization:
  name: ${ORG_DISPLAY_NAME:-Customer Name}
```

Favicon and PWA metadata are served from `packages/app/public/` and should be replaced by the customer during branding.

## Dependencies

- `@backstage/core-plugin-api` — `SignInPageProps`, `configApiRef`, `githubAuthApiRef`, `microsoftAuthApiRef`, `useApi`
- `@backstage/core-components` — `UserIdentity`
- `@material-ui/core` — `Box`, `Button`, `CircularProgress`, `Typography`, `makeStyles`

## Usage

**Route:** Configured as `SignInPage` in `createApp()` — renders before the app shell when unauthenticated.

```tsx
// App.tsx
SignInPage: props => <CustomSignInPage {...props} />,
```
