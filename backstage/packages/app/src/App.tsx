import { Navigate, Route } from 'react-router-dom';
import { apiDocsPlugin, ApiExplorerPage } from '@backstage/plugin-api-docs';
import {
  CatalogEntityPage,
  CatalogIndexPage,
  catalogPlugin,
} from '@backstage/plugin-catalog';
import {
  CatalogImportPage,
  catalogImportPlugin,
} from '@backstage/plugin-catalog-import';
import { ScaffolderPage, scaffolderPlugin } from '@backstage/plugin-scaffolder';
import { orgPlugin } from '@backstage/plugin-org';
import { SearchPage } from '@backstage/plugin-search';
import {
  TechDocsIndexPage,
  techdocsPlugin,
  TechDocsReaderPage,
} from '@backstage/plugin-techdocs';
import { TechDocsAddons } from '@backstage/plugin-techdocs-react';
import { ReportIssue } from '@backstage/plugin-techdocs-module-addons-contrib';
import { UserSettingsPage } from '@backstage/plugin-user-settings';
import { apis } from './apis';
import { entityPage } from './components/catalog/EntityPage';
import { searchPage } from './components/search/SearchPage';
import { Root } from './components/Root';
import HomePage from './components/HomePage/HomePage';
import CustomSignInPage from './components/SignInPage/CustomSignInPage';
import LearningPage from './components/LearningPage/LearningPage';
import CopilotMetricsPage from './components/CopilotMetricsPage/CopilotMetricsPage';
import PlatformStatusPage from './components/PlatformStatusPage/PlatformStatusPage';
import SecurityPage from './components/SecurityPage/SecurityPage';
import DoraMetricsPage from './components/DoraMetricsPage/DoraMetricsPage';
import TechRadarPage from './components/TechRadarPage/TechRadarPage';
import TechDebtPage from './components/TechDebtPage/TechDebtPage';
import OnboardingPage from './components/OnboardingPage/OnboardingPage';
import EngineeringPage from './components/EngineeringPage/EngineeringPage';
import IntelligencePage from './components/IntelligencePage/IntelligencePage';
import AiImpactPage from './components/AiImpactPage/AiImpactPage';
import { microsoftLightTheme, microsoftDarkTheme } from './theme';
import { UnifiedThemeProvider } from '@backstage/theme';

import {
  AlertDisplay,
  OAuthRequestDialog,
} from '@backstage/core-components';
import { createApp } from '@backstage/app-defaults';
import { AppRouter, FlatRoutes } from '@backstage/core-app-api';
import { CatalogGraphPage } from '@backstage/plugin-catalog-graph';
import { RequirePermission } from '@backstage/plugin-permission-react';
import { catalogEntityCreatePermission } from '@backstage/plugin-catalog-common/alpha';
import { NotificationsPage } from '@backstage/plugin-notifications';
import { AiChatPage } from '@open-horizons/plugin-ai-chat';
import { GithubCodespacesPage } from '@adityasinghal26/plugin-github-codespaces';

// Community plugins (direct — complex internal routing)
import { CostInsightsPage } from '@backstage-community/plugin-cost-insights';
import TechInsightsPage from './components/TechInsightsPage/TechInsightsPage';
import { EntityValidationPage } from '@backstage-community/plugin-entity-validation';

const app = createApp({
  apis,
  themes: [
    {
      id: 'microsoft-light',
      title: 'Microsoft Light',
      variant: 'light',
      Provider: ({ children }) => (
        <UnifiedThemeProvider theme={microsoftLightTheme}>
          {children}
        </UnifiedThemeProvider>
      ),
    },
    {
      id: 'microsoft-dark',
      title: 'Microsoft Dark',
      variant: 'dark',
      Provider: ({ children }) => (
        <UnifiedThemeProvider theme={microsoftDarkTheme}>
          {children}
        </UnifiedThemeProvider>
      ),
    },
  ],
  bindRoutes({ bind }) {
    bind(catalogPlugin.externalRoutes, {
      createComponent: scaffolderPlugin.routes.root,
      viewTechDoc: techdocsPlugin.routes.docRoot,
      createFromTemplate: scaffolderPlugin.routes.selectedTemplate,
    });
    bind(apiDocsPlugin.externalRoutes, {
      registerApi: catalogImportPlugin.routes.importPage,
    });
    bind(scaffolderPlugin.externalRoutes, {
      registerComponent: catalogImportPlugin.routes.importPage,
      viewTechDoc: techdocsPlugin.routes.docRoot,
    });
    bind(orgPlugin.externalRoutes, {
      catalogIndex: catalogPlugin.routes.catalogIndex,
    });
  },
  components: {
    SignInPage: props => <CustomSignInPage {...props} />,
  },
});

const routes = (
  <FlatRoutes>
    <Route path="/" element={<Navigate to="home" />} />
    <Route path="/home" element={<HomePage />} />
    <Route path="/catalog" element={<CatalogIndexPage />} />
    <Route
      path="/catalog/:namespace/:kind/:name"
      element={<CatalogEntityPage />}
    >
      {entityPage}
    </Route>
    <Route path="/docs" element={<TechDocsIndexPage />} />
    <Route
      path="/docs/:namespace/:kind/:name/*"
      element={<TechDocsReaderPage />}
    >
      <TechDocsAddons>
        <ReportIssue />
      </TechDocsAddons>
    </Route>
    <Route path="/create" element={<ScaffolderPage />} />
    <Route path="/api-docs" element={<ApiExplorerPage />} />
    <Route
      path="/catalog-import"
      element={
        <RequirePermission permission={catalogEntityCreatePermission}>
          <CatalogImportPage />
        </RequirePermission>
      }
    />
    <Route path="/search" element={<SearchPage />}>
      {searchPage}
    </Route>
    <Route path="/settings" element={<UserSettingsPage />} />
    <Route path="/catalog-graph" element={<CatalogGraphPage />} />
    <Route path="/learning" element={<LearningPage />} />
    <Route path="/copilot-metrics" element={<CopilotMetricsPage />} />
    <Route path="/platform-status" element={<PlatformStatusPage />} />
    <Route path="/security" element={<SecurityPage />} />
    <Route path="/dora-metrics" element={<DoraMetricsPage />} />
    <Route path="/tech-radar" element={<TechRadarPage />} />
    <Route path="/tech-debt" element={<TechDebtPage />} />
    <Route path="/cost-insights" element={<CostInsightsPage />} />
    <Route path="/tech-insights" element={<TechInsightsPage />} />
    <Route path="/entity-validation" element={<EntityValidationPage />} />
    <Route path="/onboarding" element={<OnboardingPage />} />
    <Route path="/engineering" element={<EngineeringPage />} />
    <Route path="/intelligence" element={<IntelligencePage />} />
    <Route path="/notifications" element={<NotificationsPage />} />
    <Route path="/ai-chat" element={<AiChatPage />} />
    <Route path="/ai-impact" element={<AiImpactPage />} />
    <Route path="/github-codespaces" element={<GithubCodespacesPage />} />
  </FlatRoutes>
);

export default app.createRoot(
  <>
    <AlertDisplay />
    <OAuthRequestDialog />
    <AppRouter>
      <Root>{routes}</Root>
    </AppRouter>
  </>,
);
