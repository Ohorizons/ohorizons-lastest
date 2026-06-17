# Backstage App Package

The main Backstage frontend application for the Open Horizons Agentic DevOps Platform. Contains all custom pages, themes, shared components, and route configuration.

## Architecture

```
packages/app/src/
├── App.tsx                 # Route definitions and app bootstrap
├── apis.ts                 # API factory registrations
├── theme.ts                # Microsoft light/dark themes
├── assets/                 # Logo images and static assets
└── components/
    ├── Root/               # App shell (sidebar, navigation)
    ├── catalog/            # Entity page tabs (EntityPage.tsx)
    ├── search/             # Search page configuration
    ├── layout/             # StandardPage layout wrapper
    ├── shared/             # HeroBanner, StyledCard (design system)
    ├── HomePage/           # Dashboard landing page
    ├── SignInPage/         # Custom sign-in (GitHub/Entra/Guest)
    ├── LearningPage/       # Learning resources and onboarding checklist
    ├── OnboardingPage/     # Interactive developer onboarding hub
    ├── EngineeringPage/    # Engineering tools and deployment dashboard
    ├── IntelligencePage/   # Agentic operations and AI agent status
    ├── PlatformStatusPage/ # Service health and ArgoCD sync status
    ├── ValidationPage/     # Entity schema validation (community plugin)
    ├── TechInsightsPage/   # Tech health scorecards with live catalog data
    ├── SecurityPage/       # Security posture dashboard
    ├── CopilotMetricsPage/ # GitHub Copilot usage analytics
    ├── CopilotAnalyticsPage/ # Copilot analytics details
    ├── DoraMetricsPage/    # DORA performance metrics
    ├── TechRadarPage/      # Technology radar
    ├── TechDebtPage/       # Technical debt tracking
    ├── CostInsightsPage/   # Cloud cost insights
    └── AiImpactPage/       # AI impact assessment
```

## Routes

| Path | Component | Description |
|------|-----------|-------------|
| `/` | Redirect → `/home` | Default redirect |
| `/home` | HomePage | Platform dashboard |
| `/catalog` | CatalogIndexPage | Software catalog |
| `/catalog/:ns/:kind/:name` | CatalogEntityPage | Entity details |
| `/docs` | TechDocsIndexPage | Documentation index |
| `/create` | ScaffolderPage | Golden Path templates |
| `/api-docs` | ApiExplorerPage | API explorer |
| `/search` | SearchPage | Global search |
| `/settings` | UserSettingsPage | User preferences |
| `/catalog-graph` | CatalogGraphPage | Entity relationship graph |
| `/catalog-import` | CatalogImportPage | Import entities |
| `/learning` | LearningPage | Learning center |
| `/onboarding` | OnboardingPage | Developer onboarding |
| `/engineering` | EngineeringPage | Engineering hub |
| `/intelligence` | IntelligencePage | Agentic operations |
| `/platform-status` | PlatformStatusPage | System health |
| `/entity-validation` | ValidationPage | Entity validation |
| `/tech-insights` | TechInsightsPage | Tech health scorecards |
| `/security` | SecurityPage | Security dashboard |
| `/copilot-metrics` | CopilotMetricsPage | Copilot metrics |
| `/dora-metrics` | DoraMetricsPage | DORA metrics |
| `/tech-radar` | TechRadarPage | Tech radar |
| `/tech-debt` | TechDebtPage | Tech debt tracker |
| `/cost-insights` | CostInsightsPage | Cost insights |
| `/ai-chat` | AiChatPage | AI assistant |
| `/ai-impact` | AiImpactPage | AI impact assessment |
| `/notifications` | NotificationsPage | Platform notifications |
| `/github-codespaces` | GithubCodespacesPage | Codespaces management |

## Shared Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `HeroBanner` | `components/shared/` | Reusable hero section with stats |
| `StyledCard` | `components/shared/` | Design-system card with title/subtitle |
| `StandardPage` | `components/layout/` | Page wrapper with consistent layout |

## Adding a New Page

1. Create a directory under `src/components/YourPage/`
2. Add your page component (e.g., `YourPage.tsx`)
3. Import it in `src/App.tsx`
4. Add a `<Route>` inside `<FlatRoutes>`
5. Optionally add a sidebar link in `components/Root/Root.tsx`

```tsx
// App.tsx
import YourPage from './components/YourPage/YourPage';

// Inside <FlatRoutes>
<Route path="/your-page" element={<YourPage />} />
```

## Theming

Custom Microsoft-branded themes are defined in `src/theme.ts`:
- `microsoftLightTheme` — Light mode with Microsoft color palette
- `microsoftDarkTheme` — Dark mode variant

## Dependencies

### Backstage Core
- `@backstage/core-components`
- `@backstage/core-plugin-api`
- `@backstage/core-app-api`
- `@backstage/app-defaults`
- `@backstage/theme`

### Backstage Plugins
- `@backstage/plugin-catalog`
- `@backstage/plugin-scaffolder`
- `@backstage/plugin-techdocs`
- `@backstage/plugin-search`
- `@backstage/plugin-api-docs`
- `@backstage/plugin-catalog-graph`
- `@backstage/plugin-notifications`
- `@backstage/plugin-user-settings`

### Community Plugins
- `@backstage-community/plugin-cost-insights`
- `@backstage-community/plugin-entity-validation`
- `@open-horizons/plugin-ai-chat`
- `@adityasinghal26/plugin-github-codespaces`
