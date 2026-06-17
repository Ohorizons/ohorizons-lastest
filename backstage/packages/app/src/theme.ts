import {
  createUnifiedTheme,
  palettes,
  genPageTheme,
  shapes,
} from '@backstage/theme';

// Open Horizons Design System — based on UX prototype
// Colors from Material 3 Light Theme spec
export const ohColors = {
  primary: '#005faa',
  primaryContainer: '#0078d4',
  secondary: '#006970',
  tertiary: '#b12c00',
  error: '#ba1a1a',
  background: '#f7f9ff',
  surface: '#f7f9ff',
  surfaceContainerLowest: '#ffffff',
  surfaceContainerLow: '#f0f4fb',
  surfaceContainer: '#eaeef5',
  surfaceContainerHigh: '#e4e8ef',
  surfaceContainerHighest: '#dee3e9',
  onSurface: '#171c21',
  onSurfaceVariant: '#404752',
  outline: '#717783',
  outlineVariant: '#c0c7d4',
  inverseSurface: '#2c3136',
  inverseOnSurface: '#edf1f8',
  // Microsoft brand
  msBlue: '#00A4EF',
  msRed: '#F25022',
  msGreen: '#7FBA00',
  msYellow: '#FFB900',
};

const pageHeaderTheme = () => ({
  colors: [ohColors.inverseSurface, ohColors.primaryContainer],
  shape: shapes.wave2,
});

export const microsoftLightTheme = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: {
      main: ohColors.primaryContainer,
      light: ohColors.msBlue,
      dark: ohColors.primary,
    },
    secondary: {
      main: ohColors.secondary,
    },
    error: {
      main: ohColors.error,
    },
    background: {
      default: ohColors.background,
      paper: ohColors.surfaceContainerLowest,
    },
    navigation: {
      background: ohColors.inverseSurface,
      indicator: ohColors.primaryContainer,
      color: '#9da4b0',
      selectedColor: '#ffffff',
      navItem: {
        hoverBackground: 'rgba(255,255,255,0.05)',
      },
    },
  },
  fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
  defaultPageTheme: 'home',
  pageTheme: {
    home: genPageTheme(pageHeaderTheme()),
    documentation: genPageTheme(pageHeaderTheme()),
    tool: genPageTheme(pageHeaderTheme()),
    service: genPageTheme(pageHeaderTheme()),
    website: genPageTheme(pageHeaderTheme()),
    library: genPageTheme(pageHeaderTheme()),
    other: genPageTheme(pageHeaderTheme()),
    app: genPageTheme(pageHeaderTheme()),
    apis: genPageTheme(pageHeaderTheme()),
  },
});

export const microsoftDarkTheme = createUnifiedTheme({
  palette: {
    ...palettes.dark,
    primary: {
      main: '#50E6FF',
      light: '#7CF3FF',
      dark: ohColors.primaryContainer,
    },
    secondary: {
      main: ohColors.secondary,
    },
    navigation: {
      background: ohColors.inverseSurface,
      indicator: ohColors.primaryContainer,
      color: '#9da4b0',
      selectedColor: '#ffffff',
      navItem: {
        hoverBackground: 'rgba(255,255,255,0.05)',
      },
    },
  },
  fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
  defaultPageTheme: 'home',
  pageTheme: {
    home: genPageTheme(pageHeaderTheme()),
    documentation: genPageTheme(pageHeaderTheme()),
    tool: genPageTheme(pageHeaderTheme()),
    service: genPageTheme(pageHeaderTheme()),
    website: genPageTheme(pageHeaderTheme()),
    library: genPageTheme(pageHeaderTheme()),
    other: genPageTheme(pageHeaderTheme()),
    app: genPageTheme(pageHeaderTheme()),
    apis: genPageTheme(pageHeaderTheme()),
  },
});
