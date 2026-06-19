import { useCallback, useMemo, useState } from 'react';
import {
  SignInPageProps,
  configApiRef,
  githubAuthApiRef,
  microsoftAuthApiRef,
  useApi,
} from '@backstage/core-plugin-api';
import { UserIdentity } from '@backstage/core-components';
import { Box, Button, CircularProgress, Typography, makeStyles } from '@material-ui/core';

const VALUE_PROPS = [
  'Enterprise SSO',
  'Developer portal',
  'Software catalog',
  'Golden Paths',
] as const;

const PLATFORM_SIGNALS = [
  { id: 'catalog', label: 'Catalog', value: 'Services and ownership' },
  { id: 'delivery', label: 'Delivery', value: 'Templates and workflows' },
  { id: 'insights', label: 'Insights', value: 'Platform signals' },
] as const;

const TECHNOLOGY_BADGES = ['Azure', 'GitHub', 'Backstage OSS'] as const;

const useStyles = makeStyles({
  root: {
    minHeight: '100vh',
    width: '100%',
    overflow: 'hidden',
    background:
      'linear-gradient(135deg, #f8fbff 0%, #f5f7fb 44%, #eef6fb 100%)',
    color: '#1B1B1F',
    fontFamily: 'Segoe UI, Inter, -apple-system, BlinkMacSystemFont, sans-serif',
    position: 'relative',
    '&::before': {
      content: '""',
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      height: 4,
      background:
        'linear-gradient(90deg, #F25022 0 25%, #7FBA00 25% 50%, #00A4EF 50% 75%, #FFB900 75% 100%)',
      zIndex: 10,
    },
  },
  shell: {
    minHeight: '100vh',
    display: 'grid',
    gridTemplateColumns: 'minmax(0, 1fr) minmax(420px, 520px)',
    '@media (max-width: 960px)': {
      gridTemplateColumns: '1fr',
    },
  },
  brandPanel: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'space-between',
    padding: '56px clamp(28px, 6vw, 88px)',
    minHeight: '100vh',
    '@media (max-width: 960px)': {
      minHeight: 'auto',
      padding: '40px 24px 24px',
    },
  },
  topBrand: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
  },
  clientLogoWrap: {
    width: 52,
    height: 52,
    borderRadius: 14,
    background: '#ffffff',
    border: '1px solid rgba(0, 0, 0, 0.08)',
    boxShadow: '0 14px 40px rgba(0, 32, 80, 0.10)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
    flexShrink: 0,
  },
  clientLogo: {
    maxWidth: 38,
    maxHeight: 38,
    display: 'block',
  },
  clientName: {
    fontSize: 18,
    fontWeight: 700,
    lineHeight: 1.2,
    color: '#1B1B1F',
  },
  platformLabel: {
    fontSize: 12,
    fontWeight: 600,
    color: '#5f6b7a',
    marginTop: 4,
    letterSpacing: 0,
  },
  hero: {
    maxWidth: 760,
    padding: '80px 0',
    '@media (max-width: 960px)': {
      padding: '48px 0 32px',
    },
  },
  eyebrow: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 10,
    color: '#0078D4',
    fontSize: 13,
    fontWeight: 700,
    marginBottom: 22,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: '50%',
    background: '#7FBA00',
    boxShadow: '0 0 0 6px rgba(127, 186, 0, 0.12)',
  },
  title: {
    maxWidth: 680,
    fontSize: 'clamp(42px, 6vw, 72px)',
    lineHeight: 0.96,
    fontWeight: 800,
    letterSpacing: 0,
    color: '#171717',
    marginBottom: 24,
  },
  accent: {
    color: '#0078D4',
  },
  subtitle: {
    maxWidth: 620,
    fontSize: 18,
    lineHeight: 1.7,
    color: '#4f5c6b',
    marginBottom: 34,
  },
  valueGrid: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 10,
    maxWidth: 640,
  },
  valuePill: {
    display: 'inline-flex',
    alignItems: 'center',
    minHeight: 34,
    padding: '0 14px',
    borderRadius: 999,
    background: 'rgba(255, 255, 255, 0.72)',
    border: '1px solid rgba(0, 120, 212, 0.14)',
    color: '#30445c',
    fontSize: 13,
    fontWeight: 650,
    boxShadow: '0 8px 24px rgba(0, 32, 80, 0.06)',
  },
  footerBrand: {
    display: 'flex',
    alignItems: 'center',
    gap: 18,
    color: '#6a7480',
    fontSize: 12,
    fontWeight: 600,
    '@media (max-width: 960px)': {
      display: 'none',
    },
  },
  partnerLogo: {
    height: 26,
    width: 'auto',
    opacity: 0.78,
  },
  badgeRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    flexWrap: 'wrap',
  },
  techBadge: {
    padding: '6px 10px',
    borderRadius: 8,
    background: 'rgba(255, 255, 255, 0.74)',
    border: '1px solid rgba(27, 27, 31, 0.08)',
    color: '#4f5c6b',
    fontSize: 11,
    fontWeight: 700,
  },
  signInPanel: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '56px clamp(24px, 4vw, 56px)',
    background: 'rgba(255, 255, 255, 0.74)',
    borderLeft: '1px solid rgba(0, 0, 0, 0.06)',
    backdropFilter: 'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    '@media (max-width: 960px)': {
      borderLeft: 'none',
      padding: '24px',
      background: 'transparent',
    },
  },
  card: {
    width: '100%',
    maxWidth: 420,
    borderRadius: 8,
    background: '#ffffff',
    border: '1px solid rgba(27, 27, 31, 0.08)',
    boxShadow: '0 28px 80px rgba(0, 32, 80, 0.14)',
    padding: 32,
    '@media (max-width: 480px)': {
      padding: 24,
    },
  },
  cardHeader: {
    marginBottom: 28,
  },
  cardKicker: {
    fontSize: 12,
    fontWeight: 750,
    color: '#0078D4',
    textTransform: 'uppercase',
    letterSpacing: 0,
    marginBottom: 12,
  },
  cardTitle: {
    color: '#1B1B1F',
    fontSize: 28,
    lineHeight: 1.16,
    fontWeight: 800,
    letterSpacing: 0,
    marginBottom: 10,
  },
  cardCopy: {
    color: '#5f6b7a',
    fontSize: 14,
    lineHeight: 1.65,
  },
  signInButton: {
    width: '100%',
    minHeight: 52,
    borderRadius: 8,
    background: '#24292F',
    color: '#ffffff',
    fontSize: 15,
    fontWeight: 750,
    textTransform: 'none',
    boxShadow: '0 14px 34px rgba(36, 41, 47, 0.22)',
    '&:hover': {
      background: '#1B1F24',
      boxShadow: '0 18px 44px rgba(36, 41, 47, 0.26)',
    },
    '&:disabled': {
      color: '#ffffff',
      background: '#6b7280',
    },
  },
  errorText: {
    marginTop: 14,
    color: '#ba1a1a',
    fontSize: 13,
    lineHeight: 1.5,
  },
  securityStrip: {
    display: 'grid',
    gridTemplateColumns: 'repeat(3, 1fr)',
    gap: 10,
    marginTop: 28,
    '@media (max-width: 480px)': {
      gridTemplateColumns: '1fr',
    },
  },
  signal: {
    minHeight: 76,
    borderRadius: 8,
    background: '#F8FAFC',
    border: '1px solid rgba(0, 0, 0, 0.06)',
    padding: 12,
  },
  signalLabel: {
    color: '#0078D4',
    fontSize: 11,
    fontWeight: 800,
    textTransform: 'uppercase',
    letterSpacing: 0,
    marginBottom: 6,
  },
  signalValue: {
    color: '#374151',
    fontSize: 12,
    lineHeight: 1.35,
    fontWeight: 650,
  },
  cardFooter: {
    marginTop: 28,
    paddingTop: 20,
    borderTop: '1px solid rgba(0, 0, 0, 0.08)',
    color: '#6a7480',
    fontSize: 12,
    lineHeight: 1.6,
  },
  miniLogoRow: {
    display: 'none',
    alignItems: 'center',
    gap: 12,
    marginTop: 18,
    '@media (max-width: 960px)': {
      display: 'flex',
    },
  },
  miniLogo: {
    height: 22,
    width: 'auto',
    opacity: 0.76,
  },
});

const GitHubIcon = ({ size = 24 }: { size?: number }) => (
  <svg viewBox="0 0 24 24" fill="currentColor" width={size} height={size} aria-hidden>
    <path d="M12 0C5.373 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.6.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.51 11.51 0 0112 5.8c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.431.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.8 24 17.302 24 12c0-6.627-5.373-12-12-12z" />
  </svg>
);

const MicrosoftIcon = ({ size = 24 }: { size?: number }) => (
  <svg viewBox="0 0 24 24" width={size} height={size} aria-hidden>
    <rect x="2" y="2" width="9.5" height="9.5" fill="#F25022" />
    <rect x="12.5" y="2" width="9.5" height="9.5" fill="#7FBA00" />
    <rect x="2" y="12.5" width="9.5" height="9.5" fill="#00A4EF" />
    <rect x="12.5" y="12.5" width="9.5" height="9.5" fill="#FFB900" />
  </svg>
);

const stripDescriptor = (value: string) =>
  value.replace(/\s+[\u2013\u2014-]\s+.*$/, '').trim();

const CustomSignInPage = ({ onSignInSuccess }: SignInPageProps) => {
  const classes = useStyles();
  const configApi = useApi(configApiRef);
  const githubAuthApi = useApi(githubAuthApiRef);
  const microsoftAuthApi = useApi(microsoftAuthApiRef);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const readConfigString = useCallback((key: string) => {
    const value = configApi.getOptionalString(key);
    return value?.trim() || undefined;
  }, [configApi]);

  const authEnvironment = readConfigString('auth.environment') ?? 'development';
  const hasMicrosoftProvider = Boolean(
    readConfigString(`auth.providers.microsoft.${authEnvironment}.clientId`) ||
    readConfigString('auth.providers.microsoft.development.clientId') ||
    readConfigString('auth.providers.microsoft.production.clientId'),
  );

  const organizationName = readConfigString('organization.name');
  const configuredTitle = readConfigString('app.title');
  const portalTitle = configuredTitle ?? 'Developer Portal';
  const clientName = organizationName ?? stripDescriptor(portalTitle) ?? 'Your organization';
  const brandLogo =
    readConfigString('app.branding.logo') ??
    readConfigString('app.branding.fullLogo.src') ??
    '/logo-msft-github.png';

  const signInAuthApi = hasMicrosoftProvider ? microsoftAuthApi : githubAuthApi;
  const signInProviderLabel = hasMicrosoftProvider ? 'Microsoft Entra ID' : 'GitHub';
  const signInIcon = useMemo(() => {
    if (loading) {
      return <CircularProgress size={20} color="inherit" />;
    }
    if (hasMicrosoftProvider) {
      return <MicrosoftIcon size={20} />;
    }
    return <GitHubIcon size={20} />;
  }, [hasMicrosoftProvider, loading]);

  const handleSignIn = useCallback(async () => {
    try {
      setError(undefined);
      setLoading(true);
      const identityResponse = await signInAuthApi.getBackstageIdentity({ instantPopup: true });
      if (!identityResponse) {
        throw new Error(`Could not resolve Backstage identity from ${signInProviderLabel} sign-in`);
      }
      const profile = await signInAuthApi.getProfile();
      onSignInSuccess(
        UserIdentity.create({
          identity: identityResponse.identity,
          profile,
          authApi: signInAuthApi,
        }),
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : `${signInProviderLabel} sign-in failed`);
    } finally {
      setLoading(false);
    }
  }, [onSignInSuccess, signInAuthApi, signInProviderLabel]);

  return (
    <Box className={classes.root}>
      <div className={classes.shell}>
        <section className={classes.brandPanel} aria-label="Platform overview">
          <div className={classes.topBrand}>
            <div className={classes.clientLogoWrap}>
              <img src={brandLogo} alt={`${clientName} logo`} className={classes.clientLogo} />
            </div>
            <div>
              <Typography className={classes.clientName}>{clientName}</Typography>
              <Typography className={classes.platformLabel}>{portalTitle}</Typography>
            </div>
          </div>

          <div className={classes.hero}>
            <div className={classes.eyebrow}>
              <div className={classes.statusDot} aria-hidden="true" />
              Agentic Platform Engineering
            </div>
            <Typography component="h1" className={classes.title}>
              Secure access to your <span className={classes.accent}>developer portal</span>
            </Typography>
            <Typography className={classes.subtitle}>
              A focused workspace for software catalog, Golden Paths, platform insights, and
              governed engineering workflows across Azure, GitHub, and Backstage OSS.
            </Typography>
            <div className={classes.valueGrid} aria-label="Platform capabilities">
              {VALUE_PROPS.map(value => (
                <span key={value} className={classes.valuePill}>{value}</span>
              ))}
            </div>
          </div>

          <div className={classes.footerBrand}>
            <img src="/logo-msft-github.png" alt="Microsoft and GitHub" className={classes.partnerLogo} />
            <div className={classes.badgeRow}>
              {TECHNOLOGY_BADGES.map(badge => (
                <span key={badge} className={classes.techBadge}>{badge}</span>
              ))}
            </div>
          </div>
        </section>

        <section className={classes.signInPanel} aria-label="Sign in">
          <div className={classes.card}>
            <div className={classes.cardHeader}>
              <Typography className={classes.cardKicker}>Enterprise access</Typography>
              <Typography component="h2" className={classes.cardTitle}>
                Sign in to continue
              </Typography>
              <Typography className={classes.cardCopy}>
                Use your approved enterprise identity to access {clientName}'s platform
                engineering workspace.
              </Typography>
            </div>

            <Button
              className={classes.signInButton}
              onClick={handleSignIn}
              disabled={loading}
              startIcon={signInIcon}
            >
              {loading ? 'Authenticating...' : `Sign in with ${signInProviderLabel}`}
            </Button>
            {error && <Typography className={classes.errorText}>{error}</Typography>}

            <div className={classes.securityStrip}>
              {PLATFORM_SIGNALS.map(signal => (
                <div key={signal.id} className={classes.signal}>
                  <div className={classes.signalLabel}>{signal.label}</div>
                  <div className={classes.signalValue}>{signal.value}</div>
                </div>
              ))}
            </div>

            <div className={classes.cardFooter}>
              Powered by Microsoft Azure, GitHub, and Backstage OSS. Access is protected by
              your configured enterprise identity provider.
              <div className={classes.miniLogoRow}>
                <img src="/logo-msft-github.png" alt="Microsoft and GitHub" className={classes.miniLogo} />
                <div className={classes.badgeRow}>
                  {TECHNOLOGY_BADGES.map(badge => (
                    <span key={badge} className={classes.techBadge}>{badge}</span>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </Box>
  );
};

export default CustomSignInPage;
