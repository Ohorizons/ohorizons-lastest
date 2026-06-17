# Custom Sign-In Page

Full-screen landing and authentication page for the Open Horizons platform. Features a cinematic scrolling experience with platform overview, architecture layers, and multiple sign-in options (GitHub OAuth, Microsoft Entra ID, Guest).

## Features

- **Video Background** — Auto-playing demo video (`/Open-Horizons-Demo.mp4`) in the hero section
- **Platform Stats** — 22 Golden Paths, 17 AI Agents, 16 Terraform Modules, 15 MCP Servers, 120+ Platform Files
- **Evolution Timeline** — DevOps → DevSecOps → Agentic DevOps progression
- **Three Horizons** — H1 Foundation, H2 Enhancement, H3 Innovation with tag badges
- **6 Differentiators** — Open Source Portal, Complete Automation, Azure Native, AI-Powered, Open Horizons Journey, Security by Default
- **Architecture Layers** — 8-layer stack visualization (Application Platform → Security & Compliance)
- **AI Maturity Model** — 3 pillars × 5 levels (L0 Traditional → L4 Agentic) with capability breakdowns
- **Team Personas** — Developer Teams, Platform Engineers, Business Leaders value propositions
- **FAQ Section** — 8 expandable Q&A items about the platform
- **Tech Logo Strip** — Azure, GitHub, Backstage, Terraform, ArgoCD, Prometheus, Grafana, Kubernetes
- **Sign-In Options**:
  - GitHub OAuth (primary)
  - Microsoft Entra ID (enterprise)
  - Guest access (demo mode)
- **Scroll Reveal Animations** — Sections animate in via IntersectionObserver
- **Microsoft 4-Color Bar** — Top border with Red, Green, Blue, Yellow gradient

## Screenshot Path

`/docs/assets/screenshots/sign-in-page.png` (placeholder)

## Configuration

Requires GitHub OAuth to be configured in `app-config.yaml`:

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

## Dependencies

- `@backstage/core-plugin-api` — SignInPageProps, githubAuthApiRef, useApi
- `@backstage/core-components` — UserIdentity
- `@material-ui/core` — Box, Button, CircularProgress, Typography

## Usage

**Route:** Configured as `SignInPage` in `createApp()` — renders before the app shell when unauthenticated.

```tsx
// App.tsx
SignInPage: props => <CustomSignInPage {...props} />,
```
