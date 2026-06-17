/**
 * CopilotMetricsPage — Developer Productivity & Copilot Intelligence
 *
 * Shows GitHub developer activity and Copilot billing/usage metrics
 * using real data from the GitHub API.
 */

import { useState, useEffect } from 'react';
import {
  Grid,
  makeStyles,
  Typography,
  LinearProgress,
  Chip,
  Box,
  CircularProgress,
} from '@material-ui/core';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import CodeIcon from '@material-ui/icons/Code';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import PeopleIcon from '@material-ui/icons/People';
import GitHubIcon from '@material-ui/icons/GitHub';
import MergeTypeIcon from '@material-ui/icons/MergeType';
import RateReviewIcon from '@material-ui/icons/RateReview';
import SpeedIcon from '@material-ui/icons/Speed';
import MemoryIcon from '@material-ui/icons/Memory';
import { useApi, githubAuthApiRef, identityApiRef } from '@backstage/core-plugin-api';
import { Page, Content } from '@backstage/core-components';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';

import copilotLogo from '../../assets/logo-github-copilot.png';

const API_BASE = '/api/proxy/ai-impact';

const useStyles = makeStyles(() => ({
  pageRoot: {
    minHeight: '100%',
    backgroundColor: '#f7f9ff',
    position: 'relative',
  },
  content: {
    padding: '24px 32px',
  },
  space: {
    height: 48,
  },
  spaceSm: {
    height: 24,
  },
  // Metric Cards
  metricGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 24,
  },
  metricValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '2rem',
    fontWeight: 800,
    color: '#171c21',
    letterSpacing: '-0.02em',
    lineHeight: 1.2,
  },
  metricLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
    marginTop: 4,
  },
  metricIcon: {
    opacity: 0.15,
    color: '#0078D4',
  },
  metricChange: {
    display: 'flex',
    alignItems: 'center',
    gap: 4,
    marginTop: 8,
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 700,
    color: '#7FBA00',
  },
  // Section labels
  sectionLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 900,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.2em',
    marginBottom: 20,
    display: 'flex',
    alignItems: 'center',
    gap: 10,
  },
  sectionIcon: {
    fontSize: 18,
    verticalAlign: 'middle',
  },
  // Activity feed
  activityRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '10px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': { borderBottom: 'none' },
  },
  activityType: {
    fontSize: 10,
    height: 22,
    fontWeight: 800,
    fontFamily: '"Inter", sans-serif',
    letterSpacing: '0.05em',
    textTransform: 'uppercase' as const,
    minWidth: 90,
  },
  activityRepo: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#171c21',
    minWidth: 140,
  },
  activityDetail: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    color: '#717783',
    flex: 1,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap' as const,
  },
  activityDate: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    color: '#a0a7b4',
    fontWeight: 500,
  },
  // Language bars
  progressBar: {
    borderRadius: 4,
    height: 8,
    marginTop: 6,
  },
  langName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#171c21',
  },
  langPct: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 800,
    color: '#404752',
  },
  // Copilot features
  featureRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '10px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': { borderBottom: 'none' },
  },
  featureLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 500,
    color: '#404752',
  },
  featureChip: {
    fontWeight: 700,
    fontSize: 11,
    fontFamily: '"Inter", sans-serif',
  },
  // Bar chart
  barChart: {
    display: 'flex',
    alignItems: 'flex-end',
    gap: 6,
    height: 140,
    padding: '16px 0',
  },
  bar: {
    width: 24,
    borderRadius: '6px 6px 0 0',
    background: 'linear-gradient(180deg, #0078D4 0%, #00B7C3 100%)',
    transition: 'height 0.3s ease',
  },
  barLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 9,
    color: '#a0a7b4',
    fontWeight: 600,
    textAlign: 'center' as const,
    marginTop: 6,
  },
  // Tags
  liveTag: {
    backgroundColor: '#7FBA00',
    color: '#fff',
    fontWeight: 800,
    fontSize: 10,
    fontFamily: '"Inter", sans-serif',
    letterSpacing: '0.1em',
    textTransform: 'uppercase' as const,
  },
  demoTag: {
    backgroundColor: '#F25022',
    color: '#fff',
    fontWeight: 800,
    fontSize: 10,
    fontFamily: '"Inter", sans-serif',
    letterSpacing: '0.1em',
    textTransform: 'uppercase' as const,
  },
  // Repo chips
  repoChip: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 600,
    margin: 3,
  },
  // Copilot logo
  copilotLogoSmall: {
    height: 18,
    verticalAlign: 'middle',
    marginRight: 8,
    opacity: 0.7,
  },
  // Seat value
  seatValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 800,
    color: '#0078D4',
  },
  // Loading container
  loadingContainer: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: 400,
  },
}));

interface GitHubEvent {
  type: string;
  repo: { name: string };
  created_at: string;
  payload: { action?: string; pull_request?: { title: string; merged: boolean }; commits?: { message: string }[]; review?: { state: string } };
}

interface DevStats {
  totalCommits: number;
  totalPRs: number;
  mergedPRs: number;
  reviewsDone: number;
  reposContributed: string[];
  recentActivity: { type: string; repo: string; detail: string; date: string }[];
  languageBreakdown: { name: string; pct: number; color: string }[];
  isLive: boolean;
}

function useGitHubProductivity(): { data: DevStats; loading: boolean } {
  const githubAuth = useApi(githubAuthApiRef);
  const identityApi = useApi(identityApiRef);
  const [data, setData] = useState<DevStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const { userEntityRef } = await identityApi.getBackstageIdentity();
        const username = userEntityRef.split('/').pop() || 'guest';
        const accessToken = await githubAuth.getAccessToken(['read:user']);
        const headers = {
          Authorization: `Bearer ${accessToken}`,
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        };

        // Fetch user events (last 100)
        const eventsRes = await fetch(`https://api.github.com/users/${username}/events?per_page=100`, { headers });
        if (!eventsRes.ok) throw new Error('GitHub API unavailable');
        const events: GitHubEvent[] = await eventsRes.json();

        // Fetch user repos
        const reposRes = await fetch(`https://api.github.com/users/${username}/repos?per_page=100&sort=pushed`, { headers });
        if (!reposRes.ok) throw new Error('GitHub repositories unavailable');
        const repos = await reposRes.json();

        // Calculate stats from events
        const pushEvents = events.filter(e => e.type === 'PushEvent');
        const prEvents = events.filter(e => e.type === 'PullRequestEvent');
        const reviewEvents = events.filter(e => e.type === 'PullRequestReviewEvent');
        const totalCommits = pushEvents.reduce((sum, e) => sum + (e.payload.commits?.length || 0), 0);
        const totalPRs = prEvents.filter(e => e.payload.action === 'opened').length;
        const mergedPRs = prEvents.filter(e => e.payload.pull_request?.merged).length;
        const reviewsDone = reviewEvents.length;
        const repoSet = new Set(events.map(e => e.repo.name));

        // Language breakdown from repos
        const langCount: Record<string, number> = {};
        for (const r of repos) {
          if (r.language) langCount[r.language] = (langCount[r.language] || 0) + 1;
        }
        const langTotal = Object.values(langCount).reduce((a: number, b: number) => a + b, 0) || 1;
        const langColors: Record<string, string> = {
          TypeScript: '#3178c6', JavaScript: '#f1e05a', Python: '#3572A5', Go: '#00ADD8',
          HCL: '#5C4EE5', Shell: '#89e051', Java: '#b07219', 'C#': '#178600', Dockerfile: '#384d54',
        };
        const languageBreakdown = Object.entries(langCount)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 6)
          .map(([name, count]) => ({
            name, pct: Math.round((count / langTotal) * 100),
            color: langColors[name] || '#888',
          }));

        // Recent activity (last 15)
        const recentActivity = events.slice(0, 15).map(e => {
          let type = e.type.replace('Event', '');
          let detail = '';
          if (e.type === 'PushEvent') detail = e.payload.commits?.[0]?.message || 'push';
          if (e.type === 'PullRequestEvent') detail = `${e.payload.action}: ${e.payload.pull_request?.title || ''}`;
          if (e.type === 'PullRequestReviewEvent') detail = `review: ${e.payload.review?.state || ''}`;
          if (e.type === 'CreateEvent') detail = 'branch/tag created';
          if (e.type === 'IssuesEvent') detail = `issue ${e.payload.action}`;
          return { type, repo: e.repo.name.split('/').pop() || e.repo.name, detail: detail.slice(0, 80), date: new Date(e.created_at).toLocaleDateString() };
        });

        setData({ totalCommits, totalPRs, mergedPRs, reviewsDone, reposContributed: [...repoSet], recentActivity, languageBreakdown, isLive: true });
      } catch (err) {
        // Show error state — no mock data
        setData({
          totalCommits: 0, totalPRs: 0, mergedPRs: 0, reviewsDone: 0,
          reposContributed: [],
          recentActivity: [],
          languageBreakdown: [],
          isLive: false,
        });
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [githubAuth, identityApi]);

  return { data: data!, loading };
}

// Copilot metrics — fetched from GitHub Copilot Billing API (real data)
interface CopilotBilling {
  seat_breakdown: { total: number; active_this_cycle: number; inactive_this_cycle: number; pending_invitation: number; added_this_cycle: number };
  seat_management_setting: string;
  plan_type: string;
  ide_chat: string;
  cli: string;
  platform_chat: string;
  public_code_suggestions: string;
}

interface CopilotMetricsData {
  billing: CopilotBilling | null;
  metricsAvailable: boolean;
  totalAcceptances: number;
  totalSuggestions: number;
  totalLines: number;
  dailyData: { date: string; acceptances: number }[];
  loading: boolean;
  error: string | null;
  notice: string | null;
}

interface CopilotBackendBilling {
  total_seats?: number;
  active_this_cycle?: number;
  inactive_this_cycle?: number;
  pending_invitation?: number;
  added_this_cycle?: number;
  plan_type?: string;
  ide_chat?: string;
  cli?: string;
  platform_chat?: string;
  public_code_suggestions?: string;
  error?: string;
}

interface CopilotBackendMetrics {
  available?: boolean;
  total_acceptances?: number;
  total_suggestions?: number;
  total_lines_accepted?: number;
  daily?: { date: string; acceptances: number }[];
  error?: string;
}

function useCopilotMetrics(): CopilotMetricsData {
  const [state, setState] = useState<CopilotMetricsData>({
    billing: null, metricsAvailable: false,
    totalAcceptances: 0, totalSuggestions: 0, totalLines: 0, dailyData: [],
    loading: true, error: null, notice: null,
  });

  useEffect(() => {
    const fetchCopilot = async () => {
      try {
        const res = await fetch(`${API_BASE}/api/impact/copilot`);
        if (!res.ok) {
          throw new Error(`Copilot backend returned ${res.status}`);
        }

        const payload = await res.json() as {
          billing?: CopilotBackendBilling;
          metrics?: CopilotBackendMetrics;
        };

        const billingPayload = payload.billing;
        const metricsPayload = payload.metrics;
        const billing = billingPayload && !billingPayload.error ? {
          seat_breakdown: {
            total: billingPayload.total_seats ?? 0,
            active_this_cycle: billingPayload.active_this_cycle ?? 0,
            inactive_this_cycle: billingPayload.inactive_this_cycle ?? 0,
            pending_invitation: billingPayload.pending_invitation ?? 0,
            added_this_cycle: billingPayload.added_this_cycle ?? 0,
          },
          seat_management_setting: 'organization',
          plan_type: billingPayload.plan_type ?? 'unknown',
          ide_chat: billingPayload.ide_chat ?? 'unknown',
          cli: billingPayload.cli ?? 'unknown',
          platform_chat: billingPayload.platform_chat ?? 'unknown',
          public_code_suggestions: billingPayload.public_code_suggestions ?? 'unknown',
        } : null;

        const dailyData = Array.isArray(metricsPayload?.daily)
          ? metricsPayload.daily.map(day => ({
              date: day.date,
              acceptances: day.acceptances,
            }))
          : [];
        const metricsAvailable = Boolean(metricsPayload?.available && dailyData.length > 0);
        const notice = billingPayload?.error || metricsPayload?.error
          ? 'Organization-level Copilot telemetry is unavailable or not enabled for this environment.'
          : null;

        setState({
          billing,
          metricsAvailable,
          totalAcceptances: metricsPayload?.total_acceptances ?? 0,
          totalSuggestions: metricsPayload?.total_suggestions ?? 0,
          totalLines: metricsPayload?.total_lines_accepted ?? 0,
          dailyData,
          loading: false,
          error: null,
          notice,
        });
      } catch (err) {
        setState(prev => ({
          ...prev,
          loading: false,
          error: err instanceof Error ? err.message : 'Failed to fetch Copilot data',
          notice: null,
        }));
      }
    };
    fetchCopilot();
  }, []);

  return state;
}

const MetricCard = ({ value, label, icon, change }: { value: string; label: string; icon: React.ReactNode; change?: string }) => {
  const classes = useStyles();
  return (
    <StyledCard>
      <Box display="flex" justifyContent="space-between" alignItems="flex-start">
        <div>
          <Typography className={classes.metricValue}>{value}</Typography>
          <Typography className={classes.metricLabel}>{label}</Typography>
          {change && (
            <div className={classes.metricChange}>
              <TrendingUpIcon style={{ fontSize: 14 }} /> {change}
            </div>
          )}
        </div>
        <Box className={classes.metricIcon}>{icon}</Box>
      </Box>
    </StyledCard>
  );
};

const CopilotMetricsPage = () => {
  const classes = useStyles();
  const { data: dev, loading } = useGitHubProductivity();
  const copilot = useCopilotMetrics();
  const acceptanceRate = copilot.totalSuggestions > 0 ? Math.round((copilot.totalAcceptances / copilot.totalSuggestions) * 100 * 10) / 10 : 0;
  const maxTrend = copilot.dailyData.length > 0 ? Math.max(...copilot.dailyData.map(d => d.acceptances), 1) : 1;

  if (loading) {
    return (
      <Page themeId="home" className={classes.pageRoot}>
        <Content className={classes.content}>
          <Box className={classes.loadingContainer}>
            <CircularProgress style={{ color: '#0078D4' }} />
          </Box>
        </Content>
      </Page>
    );
  }

  return (
    <Page themeId="home" className={classes.pageRoot}>
      <Content className={classes.content}>
        {/* Hero Banner */}
        <HeroBanner
          icon={<CodeIcon style={{ fontSize: 24, color: '#0078D4' }} />}
          label="Copilot Hub"
          title={<>Agentic <span style={{ color: '#0078D4' }}>Intelligence</span></>}
          subtitle="Real-time intelligence from your agentic pair-programmer. Monitoring code quality, acceptance rates, and developer velocity across the enterprise."
          accentColor="#0078D4"
          stats={[
            {
              label: 'Total Seats',
              value: copilot.billing ? String(copilot.billing.seat_breakdown.total) : '--',
              icon: <PeopleIcon style={{ fontSize: 20 }} />,
              color: '#0078D4',
            },
            {
              label: 'Acceptance Rate',
              value: copilot.metricsAvailable ? `${acceptanceRate}%` : '--',
              icon: <SpeedIcon style={{ fontSize: 20 }} />,
              color: '#7FBA00',
            },
            {
              label: 'Active Seats',
              value: copilot.billing ? String(copilot.billing.seat_breakdown.active_this_cycle) : '--',
              icon: <MemoryIcon style={{ fontSize: 20 }} />,
              color: '#00B7C3',
            },
            {
              label: 'Suggestions',
              value: copilot.metricsAvailable ? copilot.totalSuggestions.toLocaleString() : '--',
              icon: <CodeIcon style={{ fontSize: 20 }} />,
              color: '#5C2D91',
            },
          ]}
        />

        <div className={classes.space} />

        {/* Developer Productivity Section */}
        <div className={classes.sectionLabel}>
          <GitHubIcon className={classes.sectionIcon} />
          Your GitHub Activity (last 90 days)
          <Chip
            size="small"
            label={dev?.isLive ? 'LIVE' : 'DEMO'}
            className={dev?.isLive ? classes.liveTag : classes.demoTag}
            style={{ marginLeft: 8, height: 20 }}
          />
        </div>

        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.totalCommits || 0)} label="Commits" icon={<CodeIcon style={{ fontSize: 40 }} />} />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.totalPRs || 0)} label="PRs Opened" icon={<MergeTypeIcon style={{ fontSize: 40 }} />} />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.mergedPRs || 0)} label="PRs Merged" icon={<CheckCircleIcon style={{ fontSize: 40 }} />} />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.reviewsDone || 0)} label="Code Reviews" icon={<RateReviewIcon style={{ fontSize: 40 }} />} />
          </Grid>
        </Grid>

        <div className={classes.space} />

        <Grid container spacing={3}>
          {/* Recent Activity Feed */}
          <Grid item xs={12} md={8}>
            <StyledCard title="Recent Activity" subtitle={`Last ${dev?.recentActivity.length || 0} events`}>
              {dev?.recentActivity.map((a, i) => (
                <div key={i} className={classes.activityRow}>
                  <Chip
                    size="small"
                    label={a.type}
                    className={classes.activityType}
                    style={{
                      backgroundColor: a.type === 'Push' ? '#0078D4' : a.type.includes('Review') ? '#5C2D91' : '#7FBA00',
                      color: '#fff',
                    }}
                  />
                  <span className={classes.activityRepo}>{a.repo}</span>
                  <span className={classes.activityDetail}>{a.detail}</span>
                  <span className={classes.activityDate}>{a.date}</span>
                </div>
              ))}
              {(!dev?.recentActivity || dev.recentActivity.length === 0) && (
                <Typography style={{ fontFamily: '"Inter", sans-serif', fontSize: 13, color: '#717783', padding: '16px 0' }}>
                  No recent activity available.
                </Typography>
              )}
            </StyledCard>
          </Grid>

          {/* Language Breakdown */}
          <Grid item xs={12} md={4}>
            <StyledCard title="Your Languages" subtitle="By repository count">
              {dev?.languageBreakdown.map(l => (
                <Box key={l.name} mb={1.5}>
                  <Box display="flex" justifyContent="space-between">
                    <span className={classes.langName}>{l.name}</span>
                    <span className={classes.langPct}>{l.pct}%</span>
                  </Box>
                  <LinearProgress
                    className={classes.progressBar}
                    variant="determinate"
                    value={l.pct}
                    style={{ backgroundColor: `${l.color}20` }}
                  />
                </Box>
              ))}
              {(!dev?.languageBreakdown || dev.languageBreakdown.length === 0) && (
                <Typography style={{ fontFamily: '"Inter", sans-serif', fontSize: 13, color: '#717783', padding: '16px 0' }}>
                  No language data available.
                </Typography>
              )}
            </StyledCard>

            <div className={classes.spaceSm} />

            <StyledCard title="Repos Contributed" subtitle={`${dev?.reposContributed.length || 0} repositories`}>
              <Box display="flex" flexWrap="wrap" style={{ gap: 4 }}>
                {dev?.reposContributed.slice(0, 12).map(r => (
                  <Chip key={r} size="small" label={r.split('/').pop()} variant="outlined" className={classes.repoChip} />
                ))}
                {(!dev?.reposContributed || dev.reposContributed.length === 0) && (
                  <Typography style={{ fontFamily: '"Inter", sans-serif', fontSize: 13, color: '#717783' }}>
                    No repository data available.
                  </Typography>
                )}
              </Box>
            </StyledCard>
          </Grid>
        </Grid>

        <div className={classes.space} />

        {/* Copilot Metrics Section */}
        <div className={classes.sectionLabel}>
          <img src={copilotLogo} alt="" className={classes.copilotLogoSmall} />
          GitHub Copilot -- Organization Metrics
          <Chip size="small" label="LIVE" className={classes.liveTag} style={{ marginLeft: 8, height: 20 }} />
        </div>

        {copilot.loading ? (
          <Box className={classes.loadingContainer} style={{ minHeight: 200 }}>
            <CircularProgress style={{ color: '#0078D4' }} />
          </Box>
        ) : copilot.error ? (
          <StyledCard title="Copilot Data Unavailable">
            <Typography style={{ fontFamily: '"Inter", sans-serif', fontSize: 13, color: '#F25022' }}>
              {copilot.error}
            </Typography>
          </StyledCard>
        ) : (
          <>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6} md={3}>
                <MetricCard
                  value={copilot.billing ? String(copilot.billing.seat_breakdown.total) : '--'}
                  label="Total Seats"
                  icon={<PeopleIcon style={{ fontSize: 40 }} />}
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <MetricCard
                  value={copilot.billing ? String(copilot.billing.seat_breakdown.active_this_cycle) : '--'}
                  label="Active This Cycle"
                  icon={<CheckCircleIcon style={{ fontSize: 40 }} />}
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <MetricCard
                  value={copilot.metricsAvailable ? `${acceptanceRate}%` : '--'}
                  label="Acceptance Rate"
                  icon={<TrendingUpIcon style={{ fontSize: 40 }} />}
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <MetricCard
                  value={copilot.metricsAvailable ? copilot.totalSuggestions.toLocaleString() : '--'}
                  label="Total Suggestions"
                  icon={<CodeIcon style={{ fontSize: 40 }} />}
                />
              </Grid>
            </Grid>

            <div className={classes.space} />

            <Grid container spacing={3}>
              {/* Copilot Features from Billing API */}
              <Grid item xs={12} md={6}>
                <StyledCard title="Copilot Plan & Features" subtitle={`Plan: ${copilot.billing?.plan_type || 'unknown'}`}>
                  {[
                    { label: 'Plan Type', value: copilot.billing?.plan_type || '--' },
                    { label: 'IDE Chat', value: copilot.billing?.ide_chat || '--' },
                    { label: 'CLI', value: copilot.billing?.cli || '--' },
                    { label: 'Platform Chat', value: copilot.billing?.platform_chat || '--' },
                    { label: 'Public Code Suggestions', value: copilot.billing?.public_code_suggestions || '--' },
                    { label: 'Seat Management', value: copilot.billing?.seat_management_setting || '--' },
                  ].map(item => (
                    <div key={item.label} className={classes.featureRow}>
                      <span className={classes.featureLabel}>{item.label}</span>
                      <Chip
                        size="small"
                        label={item.value}
                        className={classes.featureChip}
                        style={{
                          backgroundColor: item.value === 'enabled' ? '#E8F5E9' : item.value === 'disabled' ? '#FFEBEE' : '#f0f2f5',
                          color: item.value === 'enabled' ? '#2E7D32' : item.value === 'disabled' ? '#D32F2F' : '#404752',
                        }}
                      />
                    </div>
                  ))}
                </StyledCard>
              </Grid>

              {/* Seat Breakdown */}
              <Grid item xs={12} md={6}>
                <StyledCard title="Seat Breakdown" subtitle="Current billing cycle">
                  {copilot.billing ? [
                    { label: 'Total Seats', value: copilot.billing.seat_breakdown.total },
                    { label: 'Active This Cycle', value: copilot.billing.seat_breakdown.active_this_cycle },
                    { label: 'Inactive This Cycle', value: copilot.billing.seat_breakdown.inactive_this_cycle },
                    { label: 'Pending Invitation', value: copilot.billing.seat_breakdown.pending_invitation },
                    { label: 'Added This Cycle', value: copilot.billing.seat_breakdown.added_this_cycle },
                  ].map(item => (
                    <div key={item.label} className={classes.featureRow}>
                      <span className={classes.featureLabel}>{item.label}</span>
                      <span className={classes.seatValue}>{item.value}</span>
                    </div>
                  )) : (
                    <Typography style={{ fontFamily: '"Inter", sans-serif', fontSize: 13, color: '#717783' }}>
                      Billing data unavailable
                    </Typography>
                  )}
                </StyledCard>
              </Grid>

              {/* Usage Trend (if metrics available) */}
              {copilot.metricsAvailable && copilot.dailyData.length > 0 && (
                <Grid item xs={12}>
                  <StyledCard title="Daily Acceptances" subtitle={`Last ${copilot.dailyData.length} days`}>
                    <div className={classes.barChart}>
                      {copilot.dailyData.map((d, i) => (
                        <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flex: 1 }}>
                          <div className={classes.bar} style={{ height: `${(d.acceptances / maxTrend) * 100}%` }} />
                          <span className={classes.barLabel}>{d.date.slice(5)}</span>
                        </div>
                      ))}
                    </div>
                  </StyledCard>
                </Grid>
              )}

              {!copilot.metricsAvailable && (
                <Grid item xs={12}>
                  <StyledCard title="Usage Metrics">
                    <Box display="flex" alignItems="center" py={2}>
                      <Typography style={{ fontFamily: '"Inter", sans-serif', fontSize: 13, color: '#717783', lineHeight: 1.6 }}>
                        {copilot.notice || 'No Copilot usage data available. This can mean no seats are assigned or no usage has been recorded yet.'}
                        {' '}
                        Metrics appear once developers actively use Copilot with assigned seats.
                      </Typography>
                    </Box>
                  </StyledCard>
                </Grid>
              )}
            </Grid>
          </>
        )}
      </Content>
    </Page>
  );
};

export default CopilotMetricsPage;
