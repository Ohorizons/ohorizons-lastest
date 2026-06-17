/**
 * SecurityPage — GitHub Advanced Security (GHAS) Dashboard
 *
 * Shows security overview with Dependabot alerts, Code Scanning,
 * and Secret Scanning status fetched from GitHub API.
 *
 * Redesigned with Open Horizons UX prototype pattern:
 * HeroBanner + StyledCard + Recharts visualizations.
 */

import { useState, useEffect } from 'react';
import {
  Chip,
  Box,
  CircularProgress,
  Link as MuiLink,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
} from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { Page, Content } from '@backstage/core-components';
import SecurityIcon from '@material-ui/icons/Security';
import WarningIcon from '@material-ui/icons/Warning';
import ErrorIcon from '@material-ui/icons/Error';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import BugReportIcon from '@material-ui/icons/BugReport';
import VpnKeyIcon from '@material-ui/icons/VpnKey';
import UpdateIcon from '@material-ui/icons/Update';
import VerifiedUserIcon from '@material-ui/icons/VerifiedUser';
import ShieldIcon from '@material-ui/icons/Security';
import { configApiRef, useApi } from '@backstage/core-plugin-api';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';
import {
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';

const API_BASE = '/api/proxy/ai-impact';

/* ------------------------------------------------------------------ */
/*  Styles                                                             */
/* ------------------------------------------------------------------ */

const useStyles = makeStyles({
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

  /* Stat cards grid */
  statGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 24,
  },
  statLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 700,
    color: '#404752',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.05em',
    marginBottom: 4,
  },
  statValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '2rem',
    fontWeight: 800,
    color: '#171c21',
    letterSpacing: '-0.02em',
  },
  statBar: {
    height: 4,
    borderRadius: 2,
    marginTop: 12,
  },

  /* Section label */
  sectionLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 900,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.2em',
    marginBottom: 16,
  },
  sectionTitle: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '1.25rem',
    fontWeight: 800,
    color: '#171c21',
    letterSpacing: '-0.02em',
    marginBottom: 8,
  },

  /* Two-column layout */
  twoCol: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 24,
  },
  threeCol: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr 1fr',
    gap: 24,
  },

  /* Breakdown rows */
  breakdownRow: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '10px 0',
    borderBottom: '1px solid #eef1f6',
    '&:last-child': { borderBottom: 'none' },
  },
  breakdownLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#171c21',
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  breakdownValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 800,
    color: '#171c21',
  },

  /* Severity chips */
  sevChip: {
    fontSize: 10,
    height: 22,
    fontWeight: 800,
    letterSpacing: '0.05em',
    borderRadius: 6,
  },

  /* Feature status rows */
  featureRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    padding: '10px 0',
    borderBottom: '1px solid #eef1f6',
    '&:last-child': { borderBottom: 'none' },
  },
  featureLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#171c21',
    flex: 1,
  },
  enabledChip: {
    fontSize: 10,
    height: 22,
    fontWeight: 800,
    borderRadius: 6,
    letterSpacing: '0.05em',
  },

  /* Quick links */
  linkItem: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#00A4EF',
    textDecoration: 'none',
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    padding: '8px 0',
    '&:hover': { textDecoration: 'underline' },
  },

  /* Findings table */
  tableHead: {
    '& th': {
      fontFamily: '"Inter", sans-serif',
      fontSize: 10,
      fontWeight: 900,
      color: '#717783',
      textTransform: 'uppercase' as const,
      letterSpacing: '0.15em',
      borderBottom: '2px solid #eef1f6',
      padding: '12px 16px',
    },
  },
  tableRow: {
    '&:hover': { backgroundColor: '#f7f9ff' },
    '& td': {
      fontFamily: '"Inter", sans-serif',
      fontSize: 13,
      fontWeight: 500,
      color: '#171c21',
      padding: '12px 16px',
      borderBottom: '1px solid #eef1f6',
    },
  },

  /* Error banner */
  errorBanner: {
    backgroundColor: '#FFF3E0',
    border: '1px solid #FFB74D',
    borderRadius: 12,
    padding: '16px 20px',
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#E65100',
  },

  /* Loading */
  loadingWrap: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: 400,
    gap: 16,
  },
  loadingText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 600,
    color: '#717783',
  },

  /* Clean status indicator */
  cleanStatus: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '12px 0',
  },
  cleanText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#7FBA00',
  },

  /* Chart tooltip */
  chartTooltip: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 600,
    backgroundColor: '#2c3136',
    color: '#fff',
    padding: '8px 12px',
    borderRadius: 8,
    border: 'none',
    boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
  },
});

/* ------------------------------------------------------------------ */
/*  Interfaces                                                         */
/* ------------------------------------------------------------------ */

interface AlertSummary {
  critical: number;
  high: number;
  medium: number;
  low: number;
  total: number;
}

interface CodeQualitySummary {
  maintainability: number;
  reliability: number;
  correctness: number;
  total: number;
  autofixAvailable: number;
}

interface SecurityState {
  loading: boolean;
  error: string | null;
  dependabot: AlertSummary;
  codeScanning: AlertSummary;
  secretScanning: { count: number };
  codeQuality: CodeQualitySummary;
  features: {
    dependabot: 'enabled' | 'disabled' | 'unknown';
    codeScanning: 'enabled' | 'disabled' | 'unknown';
    secretScanning: 'enabled' | 'disabled' | 'unknown';
  };
}

const EMPTY_SUMMARY: AlertSummary = { critical: 0, high: 0, medium: 0, low: 0, total: 0 };

/* ------------------------------------------------------------------ */
/*  Demo data for charts (no historical API available)                 */
/* ------------------------------------------------------------------ */

const vulnerabilityTrendData = [
  { week: 'W1', critical: 3, high: 7, medium: 12, low: 5 },
  { week: 'W2', critical: 2, high: 6, medium: 14, low: 4 },
  { week: 'W3', critical: 4, high: 8, medium: 11, low: 6 },
  { week: 'W4', critical: 1, high: 5, medium: 10, low: 3 },
  { week: 'W5', critical: 2, high: 4, medium: 9, low: 5 },
  { week: 'W6', critical: 1, high: 3, medium: 8, low: 4 },
  { week: 'W7', critical: 0, high: 3, medium: 7, low: 3 },
  { week: 'W8', critical: 1, high: 2, medium: 6, low: 2 },
];

const complianceData = [
  { name: 'Passing', value: 78, color: '#7FBA00' },
  { name: 'Warning', value: 15, color: '#FFB900' },
  { name: 'Failing', value: 7, color: '#F25022' },
];

/* ------------------------------------------------------------------ */
/*  Component                                                          */
/* ------------------------------------------------------------------ */

const SecurityPage = () => {
  const classes = useStyles();
  const config = useApi(configApiRef);
  const [state, setState] = useState<SecurityState>({
    loading: true,
    error: null,
    dependabot: { ...EMPTY_SUMMARY },
    codeScanning: { ...EMPTY_SUMMARY },
    secretScanning: { count: 0 },
    codeQuality: { maintainability: 0, reliability: 0, correctness: 0, total: 0, autofixAvailable: 0 },
    features: { dependabot: 'unknown', codeScanning: 'unknown', secretScanning: 'unknown' },
  });

  useEffect(() => {
    const fetchSecurityData = async () => {
      try {
        const baseUrl = config.getString('backend.baseUrl');
        const res = await fetch(`${baseUrl}${API_BASE}/api/impact/quality`);
        if (!res.ok) {
          throw new Error(`Security backend returned ${res.status}`);
        }

        const payload = await res.json() as {
          security?: {
            error?: string;
            dependabot?: AlertSummary;
            code_scanning?: AlertSummary;
            code_quality?: {
              maintainability?: number;
              reliability?: number;
              correctness?: number;
              total?: number;
              autofix_available?: number;
            };
            secret_scanning?: { count?: number };
            features?: {
              dependabot?: 'enabled' | 'disabled' | 'unknown';
              code_scanning?: 'enabled' | 'disabled' | 'unknown';
              secret_scanning?: 'enabled' | 'disabled' | 'unknown';
            };
          };
        };

        const security = payload.security;
        const features = security?.features;

        setState({
          loading: false,
          error: security?.error ?? null,
          dependabot: security?.dependabot ?? { ...EMPTY_SUMMARY },
          codeScanning: security?.code_scanning ?? { ...EMPTY_SUMMARY },
          secretScanning: { count: security?.secret_scanning?.count ?? 0 },
          codeQuality: {
            maintainability: security?.code_quality?.maintainability ?? 0,
            reliability: security?.code_quality?.reliability ?? 0,
            correctness: security?.code_quality?.correctness ?? 0,
            total: security?.code_quality?.total ?? 0,
            autofixAvailable: security?.code_quality?.autofix_available ?? 0,
          },
          features: {
            dependabot: features?.dependabot ?? 'unknown',
            codeScanning: features?.code_scanning ?? 'unknown',
            secretScanning: features?.secret_scanning ?? 'unknown',
          },
        });
      } catch (err) {
        setState(prev => ({
          ...prev,
          loading: false,
          error: err instanceof Error ? err.message : 'Failed to fetch security data',
        }));
      }
    };

    fetchSecurityData();
  }, [config]);

  const totalAlerts =
    state.dependabot.total + state.codeScanning.total + state.secretScanning.count;
  const totalCritical = state.dependabot.critical + state.codeScanning.critical;

  const sevColor = (severity: string) => {
    switch (severity) {
      case 'critical': return '#F25022';
      case 'high': return '#E65100';
      case 'medium': return '#FFB900';
      case 'low': return '#7FBA00';
      default: return '#717783';
    }
  };

  const sevBg = (severity: string) => {
    switch (severity) {
      case 'critical': return '#FDE8E4';
      case 'high': return '#FFF3E0';
      case 'medium': return '#FFF8E1';
      case 'low': return '#F0F7E0';
      default: return '#F5F5F5';
    }
  };

  return (
    <Page themeId="tool">
      <Content className={classes.pageRoot}>
        <div className={classes.content}>
          {/* Hero Banner */}
          <HeroBanner
            icon={<SecurityIcon style={{ fontSize: 24, color: '#F25022' }} />}
            label="Security & Compliance Hub"
            title={<>Zero Trust <span style={{ color: '#F25022' }}>Operations</span></>}
            subtitle="Monitor and enforce security policies across your software supply chain with agentic governance and real-time threat detection."
            accentColor="#F25022"
            stats={[
              {
                label: 'Total Alerts',
                value: String(totalAlerts),
                icon: <WarningIcon style={{ fontSize: 20 }} />,
                color: '#FFB900',
              },
              {
                label: 'Critical',
                value: String(totalCritical),
                icon: <ErrorIcon style={{ fontSize: 20 }} />,
                color: '#F25022',
              },
              {
                label: 'Dependabot',
                value: String(state.dependabot.total),
                icon: <UpdateIcon style={{ fontSize: 20 }} />,
                color: '#00A4EF',
              },
              {
                label: 'Secrets Exposed',
                value: String(state.secretScanning.count),
                icon: <VpnKeyIcon style={{ fontSize: 20 }} />,
                color: state.secretScanning.count > 0 ? '#F25022' : '#7FBA00',
              },
            ]}
          />

          <div className={classes.space} />

          {state.loading ? (
            <div className={classes.loadingWrap}>
              <CircularProgress style={{ color: '#F25022' }} />
              <span className={classes.loadingText}>Loading security data...</span>
            </div>
          ) : (
            <>
              {/* Metric Cards Row */}
              <div className={classes.sectionLabel}>Security Overview</div>
              <div className={classes.statGrid}>
                <StyledCard>
                  <div className={classes.statLabel}>Total Open Alerts</div>
                  <div className={classes.statValue} style={{ color: totalAlerts === 0 ? '#7FBA00' : '#F25022' }}>
                    {totalAlerts}
                  </div>
                  <div className={classes.statBar} style={{ background: `linear-gradient(90deg, ${totalAlerts === 0 ? '#7FBA00' : '#F25022'} ${Math.min(totalAlerts * 5, 100)}%, #eef1f6 0%)` }} />
                </StyledCard>

                <StyledCard>
                  <div className={classes.statLabel}>Critical / High</div>
                  <div className={classes.statValue} style={{ color: totalCritical > 0 ? '#F25022' : '#7FBA00' }}>
                    {totalCritical}
                  </div>
                  <div className={classes.statBar} style={{ background: `linear-gradient(90deg, ${totalCritical > 0 ? '#F25022' : '#7FBA00'} ${Math.min(totalCritical * 10, 100)}%, #eef1f6 0%)` }} />
                </StyledCard>

                <StyledCard>
                  <div className={classes.statLabel}>Code Quality Alerts</div>
                  <div className={classes.statValue} style={{ color: state.codeQuality.total > 0 ? '#FFB900' : '#7FBA00' }}>
                    {state.codeQuality.total}
                  </div>
                  <div className={classes.statBar} style={{ background: `linear-gradient(90deg, ${state.codeQuality.total > 0 ? '#FFB900' : '#7FBA00'} ${Math.min(state.codeQuality.total * 10, 100)}%, #eef1f6 0%)` }} />
                </StyledCard>

                <StyledCard>
                  <div className={classes.statLabel}>Copilot Autofix</div>
                  <div className={classes.statValue} style={{ color: '#00A4EF' }}>
                    {state.codeQuality.autofixAvailable}
                  </div>
                  <div className={classes.statBar} style={{ background: `linear-gradient(90deg, #00A4EF ${Math.min(state.codeQuality.autofixAvailable * 20, 100)}%, #eef1f6 0%)` }} />
                </StyledCard>
              </div>

              <div className={classes.space} />

              {/* Charts Row: Vulnerability Trend + Compliance */}
              <div className={classes.sectionLabel}>Analytics & Compliance</div>
              <div className={classes.twoCol}>
                <StyledCard title="Vulnerability Trend" subtitle="8-week rolling window (demo)">
                  <ResponsiveContainer width="100%" height={260}>
                    <LineChart data={vulnerabilityTrendData} margin={{ top: 8, right: 16, bottom: 0, left: -16 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#eef1f6" />
                      <XAxis
                        dataKey="week"
                        tick={{ fontFamily: '"Inter", sans-serif', fontSize: 11, fill: '#717783' }}
                        axisLine={{ stroke: '#eef1f6' }}
                        tickLine={false}
                      />
                      <YAxis
                        tick={{ fontFamily: '"Inter", sans-serif', fontSize: 11, fill: '#717783' }}
                        axisLine={{ stroke: '#eef1f6' }}
                        tickLine={false}
                      />
                      <Tooltip
                        contentStyle={{
                          fontFamily: '"Inter", sans-serif',
                          fontSize: 12,
                          fontWeight: 600,
                          backgroundColor: '#2c3136',
                          color: '#fff',
                          borderRadius: 8,
                          border: 'none',
                          boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
                        }}
                        itemStyle={{ color: '#fff' }}
                        labelStyle={{ color: 'rgba(255,255,255,0.6)', fontWeight: 700 }}
                      />
                      <Legend
                        wrapperStyle={{ fontFamily: '"Inter", sans-serif', fontSize: 11, fontWeight: 600 }}
                      />
                      <Line type="monotone" dataKey="critical" stroke="#F25022" strokeWidth={2} dot={{ r: 4 }} />
                      <Line type="monotone" dataKey="high" stroke="#E65100" strokeWidth={2} dot={{ r: 3 }} />
                      <Line type="monotone" dataKey="medium" stroke="#FFB900" strokeWidth={2} dot={{ r: 3 }} />
                      <Line type="monotone" dataKey="low" stroke="#7FBA00" strokeWidth={2} dot={{ r: 3 }} />
                    </LineChart>
                  </ResponsiveContainer>
                </StyledCard>

                <StyledCard title="Compliance Posture" subtitle="Policy checks summary">
                  <Box display="flex" alignItems="center" justifyContent="center" style={{ gap: 32 }}>
                    <ResponsiveContainer width={200} height={220}>
                      <PieChart>
                        <Pie
                          data={complianceData}
                          cx="50%"
                          cy="50%"
                          innerRadius={55}
                          outerRadius={85}
                          paddingAngle={3}
                          dataKey="value"
                          stroke="none"
                        >
                          {complianceData.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                          ))}
                        </Pie>
                        <Tooltip
                          contentStyle={{
                            fontFamily: '"Inter", sans-serif',
                            fontSize: 12,
                            fontWeight: 600,
                            backgroundColor: '#2c3136',
                            color: '#fff',
                            borderRadius: 8,
                            border: 'none',
                          }}
                          itemStyle={{ color: '#fff' }}
                        />
                      </PieChart>
                    </ResponsiveContainer>
                    <div>
                      {complianceData.map(item => (
                        <div key={item.name} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
                          <div style={{ width: 12, height: 12, borderRadius: 3, backgroundColor: item.color, flexShrink: 0 }} />
                          <div>
                            <div style={{ fontFamily: '"Inter", sans-serif', fontSize: 13, fontWeight: 700, color: '#171c21' }}>
                              {item.value}%
                            </div>
                            <div style={{ fontFamily: '"Inter", sans-serif', fontSize: 10, fontWeight: 700, color: '#717783', textTransform: 'uppercase', letterSpacing: '0.1em' }}>
                              {item.name}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </Box>
                </StyledCard>
              </div>

              <div className={classes.space} />

              {/* Breakdown Cards: Dependabot / Code Scanning / Secret Scanning */}
              <div className={classes.sectionLabel}>Alert Breakdown</div>
              <div className={classes.threeCol}>
                {/* Dependabot */}
                <StyledCard title="Dependabot" subtitle="Dependency Alerts">
                  {state.dependabot.total === 0 ? (
                    <div className={classes.cleanStatus}>
                      <CheckCircleIcon style={{ color: '#7FBA00', fontSize: 20 }} />
                      <span className={classes.cleanText}>No open alerts</span>
                    </div>
                  ) : (
                    <>
                      {(['critical', 'high', 'medium', 'low'] as const).map(sev => (
                        state.dependabot[sev] > 0 && (
                          <div key={sev} className={classes.breakdownRow}>
                            <Chip
                              label={sev.toUpperCase()}
                              size="small"
                              className={classes.sevChip}
                              style={{ background: sevBg(sev), color: sevColor(sev) }}
                            />
                            <span className={classes.breakdownValue}>{state.dependabot[sev]}</span>
                          </div>
                        )
                      ))}
                      <div className={classes.breakdownRow} style={{ borderTop: '2px solid #eef1f6', marginTop: 4, paddingTop: 12 }}>
                        <span className={classes.breakdownLabel}>Total</span>
                        <span className={classes.breakdownValue}>{state.dependabot.total}</span>
                      </div>
                    </>
                  )}
                </StyledCard>

                {/* Code Scanning */}
                <StyledCard title="Code Scanning" subtitle="CodeQL Analysis">
                  {state.codeScanning.total === 0 ? (
                    <div className={classes.cleanStatus}>
                      <CheckCircleIcon style={{ color: '#7FBA00', fontSize: 20 }} />
                      <span className={classes.cleanText}>No open alerts</span>
                    </div>
                  ) : (
                    <>
                      {(['critical', 'high', 'medium', 'low'] as const).map(sev => (
                        state.codeScanning[sev] > 0 && (
                          <div key={sev} className={classes.breakdownRow}>
                            <Chip
                              label={sev.toUpperCase()}
                              size="small"
                              className={classes.sevChip}
                              style={{ background: sevBg(sev), color: sevColor(sev) }}
                            />
                            <span className={classes.breakdownValue}>{state.codeScanning[sev]}</span>
                          </div>
                        )
                      ))}
                      <div className={classes.breakdownRow} style={{ borderTop: '2px solid #eef1f6', marginTop: 4, paddingTop: 12 }}>
                        <span className={classes.breakdownLabel}>Total</span>
                        <span className={classes.breakdownValue}>{state.codeScanning.total}</span>
                      </div>
                    </>
                  )}
                </StyledCard>

                {/* Secret Scanning */}
                <StyledCard title="Secret Scanning" subtitle="Exposed Credentials">
                  {state.secretScanning.count === 0 ? (
                    <div className={classes.cleanStatus}>
                      <CheckCircleIcon style={{ color: '#7FBA00', fontSize: 20 }} />
                      <span className={classes.cleanText}>No exposed secrets detected</span>
                    </div>
                  ) : (
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 0' }}>
                      <WarningIcon style={{ color: '#F25022', fontSize: 22 }} />
                      <span style={{ fontFamily: '"Inter", sans-serif', fontSize: 14, fontWeight: 800, color: '#F25022' }}>
                        {state.secretScanning.count} exposed secret{state.secretScanning.count !== 1 ? 's' : ''} detected
                      </span>
                    </div>
                  )}
                </StyledCard>
              </div>

              <div className={classes.space} />

              {/* Code Quality + GHAS Features */}
              <div className={classes.sectionLabel}>Code Quality & Features</div>
              <div className={classes.twoCol}>
                {/* Code Quality */}
                <StyledCard title="Code Quality" subtitle="GitHub CodeQL">
                  <div className={classes.breakdownRow}>
                    <span className={classes.breakdownLabel}>
                      <BugReportIcon style={{ fontSize: 16, color: '#FFB900' }} />
                      Quality Alerts
                    </span>
                    <span className={classes.breakdownValue}>{state.codeQuality.total}</span>
                  </div>
                  <div className={classes.breakdownRow}>
                    <span className={classes.breakdownLabel}>
                      <BugReportIcon style={{ fontSize: 16, color: '#E65100' }} />
                      Maintainability
                    </span>
                    <span className={classes.breakdownValue}>{state.codeQuality.maintainability}</span>
                  </div>
                  <div className={classes.breakdownRow}>
                    <span className={classes.breakdownLabel}>
                      <WarningIcon style={{ fontSize: 16, color: '#F25022' }} />
                      Reliability
                    </span>
                    <span className={classes.breakdownValue}>{state.codeQuality.reliability}</span>
                  </div>
                  <div className={classes.breakdownRow}>
                    <span className={classes.breakdownLabel}>
                      <ErrorIcon style={{ fontSize: 16, color: '#00A4EF' }} />
                      Correctness
                    </span>
                    <span className={classes.breakdownValue}>{state.codeQuality.correctness}</span>
                  </div>
                  <div className={classes.breakdownRow}>
                    <span className={classes.breakdownLabel}>
                      <CheckCircleIcon style={{ fontSize: 16, color: '#7FBA00' }} />
                      Copilot Autofix Available
                    </span>
                    <span className={classes.breakdownValue}>{state.codeQuality.autofixAvailable}</span>
                  </div>
                </StyledCard>

                {/* GHAS Features + Quick Links */}
                <StyledCard title="GHAS Features" subtitle="Feature Status">
                  {[
                    { name: 'Dependabot Alerts', icon: <UpdateIcon style={{ fontSize: 18, color: '#FFB900' }} />, status: state.features.dependabot },
                    { name: 'Code Scanning (CodeQL)', icon: <BugReportIcon style={{ fontSize: 18, color: '#E65100' }} />, status: state.features.codeScanning },
                    { name: 'Secret Scanning', icon: <VpnKeyIcon style={{ fontSize: 18, color: '#F25022' }} />, status: state.features.secretScanning },
                  ].map(f => (
                    <div key={f.name} className={classes.featureRow}>
                      {f.icon}
                      <span className={classes.featureLabel}>{f.name}</span>
                      <Chip
                        label={f.status === 'enabled' ? 'ENABLED' : f.status === 'disabled' ? 'DISABLED' : 'UNKNOWN'}
                        size="small"
                        className={classes.enabledChip}
                        style={{
                          background: f.status === 'enabled' ? '#F0F7E0' : f.status === 'disabled' ? '#FDE8E4' : '#F5F5F5',
                          color: f.status === 'enabled' ? '#7FBA00' : f.status === 'disabled' ? '#F25022' : '#717783',
                        }}
                      />
                    </div>
                  ))}

                  <div style={{ marginTop: 16, borderTop: '2px solid #eef1f6', paddingTop: 16 }}>
                    <div style={{ fontFamily: '"Inter", sans-serif', fontSize: 10, fontWeight: 900, color: '#717783', textTransform: 'uppercase', letterSpacing: '0.15em', marginBottom: 8 }}>
                      Quick Links
                    </div>
                    <MuiLink
                      href="https://github.com/Ohorizons/ohorizons-demo/security"
                      target="_blank"
                      rel="noopener noreferrer"
                      className={classes.linkItem}
                    >
                      <ShieldIcon style={{ fontSize: 14 }} /> GitHub Security Tab
                    </MuiLink>
                    <MuiLink
                      href="https://github.com/Ohorizons/ohorizons-demo/security/dependabot"
                      target="_blank"
                      rel="noopener noreferrer"
                      className={classes.linkItem}
                    >
                      <UpdateIcon style={{ fontSize: 14 }} /> Dependabot Alerts
                    </MuiLink>
                    <MuiLink
                      href="https://github.com/Ohorizons/ohorizons-demo/security/code-scanning"
                      target="_blank"
                      rel="noopener noreferrer"
                      className={classes.linkItem}
                    >
                      <BugReportIcon style={{ fontSize: 14 }} /> Code Scanning Alerts
                    </MuiLink>
                    <MuiLink
                      href="https://github.com/Ohorizons/ohorizons-demo/security/secret-scanning"
                      target="_blank"
                      rel="noopener noreferrer"
                      className={classes.linkItem}
                    >
                      <VpnKeyIcon style={{ fontSize: 14 }} /> Secret Scanning Alerts
                    </MuiLink>
                  </div>
                </StyledCard>
              </div>

              <div className={classes.space} />

              {/* Findings Table */}
              <div className={classes.sectionLabel}>Recent Findings</div>
              <StyledCard title="Security Findings" subtitle="Aggregated alert details">
                <Table size="small">
                  <TableHead className={classes.tableHead}>
                    <TableRow>
                      <TableCell>Source</TableCell>
                      <TableCell>Severity</TableCell>
                      <TableCell align="center">Count</TableCell>
                      <TableCell>Status</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    <TableRow className={classes.tableRow}>
                      <td style={{ padding: '12px 16px', fontFamily: '"Inter", sans-serif', fontSize: 13, fontWeight: 600, color: '#171c21', borderBottom: '1px solid #eef1f6', display: 'flex', alignItems: 'center', gap: 8 }}>
                        <UpdateIcon style={{ fontSize: 16, color: '#FFB900' }} /> Dependabot
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6' }}>
                        {state.dependabot.critical > 0 && <Chip label="CRITICAL" size="small" className={classes.sevChip} style={{ background: '#FDE8E4', color: '#F25022', marginRight: 4 }} />}
                        {state.dependabot.high > 0 && <Chip label="HIGH" size="small" className={classes.sevChip} style={{ background: '#FFF3E0', color: '#E65100', marginRight: 4 }} />}
                        {state.dependabot.medium > 0 && <Chip label="MEDIUM" size="small" className={classes.sevChip} style={{ background: '#FFF8E1', color: '#FFB900', marginRight: 4 }} />}
                        {state.dependabot.low > 0 && <Chip label="LOW" size="small" className={classes.sevChip} style={{ background: '#F0F7E0', color: '#7FBA00' }} />}
                        {state.dependabot.total === 0 && <Chip label="CLEAN" size="small" className={classes.sevChip} style={{ background: '#F0F7E0', color: '#7FBA00' }} />}
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6', textAlign: 'center', fontFamily: '"Inter", sans-serif', fontSize: 14, fontWeight: 800, color: '#171c21' }}>
                        {state.dependabot.total}
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6' }}>
                        <Chip
                          label={state.features.dependabot === 'enabled' ? 'ACTIVE' : 'INACTIVE'}
                          size="small"
                          className={classes.enabledChip}
                          style={{
                            background: state.features.dependabot === 'enabled' ? '#F0F7E0' : '#FDE8E4',
                            color: state.features.dependabot === 'enabled' ? '#7FBA00' : '#F25022',
                          }}
                        />
                      </td>
                    </TableRow>
                    <TableRow className={classes.tableRow}>
                      <td style={{ padding: '12px 16px', fontFamily: '"Inter", sans-serif', fontSize: 13, fontWeight: 600, color: '#171c21', borderBottom: '1px solid #eef1f6', display: 'flex', alignItems: 'center', gap: 8 }}>
                        <BugReportIcon style={{ fontSize: 16, color: '#E65100' }} /> Code Scanning
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6' }}>
                        {state.codeScanning.critical > 0 && <Chip label="CRITICAL" size="small" className={classes.sevChip} style={{ background: '#FDE8E4', color: '#F25022', marginRight: 4 }} />}
                        {state.codeScanning.high > 0 && <Chip label="HIGH" size="small" className={classes.sevChip} style={{ background: '#FFF3E0', color: '#E65100', marginRight: 4 }} />}
                        {state.codeScanning.medium > 0 && <Chip label="MEDIUM" size="small" className={classes.sevChip} style={{ background: '#FFF8E1', color: '#FFB900', marginRight: 4 }} />}
                        {state.codeScanning.low > 0 && <Chip label="LOW" size="small" className={classes.sevChip} style={{ background: '#F0F7E0', color: '#7FBA00' }} />}
                        {state.codeScanning.total === 0 && <Chip label="CLEAN" size="small" className={classes.sevChip} style={{ background: '#F0F7E0', color: '#7FBA00' }} />}
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6', textAlign: 'center', fontFamily: '"Inter", sans-serif', fontSize: 14, fontWeight: 800, color: '#171c21' }}>
                        {state.codeScanning.total}
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6' }}>
                        <Chip
                          label={state.features.codeScanning === 'enabled' ? 'ACTIVE' : 'INACTIVE'}
                          size="small"
                          className={classes.enabledChip}
                          style={{
                            background: state.features.codeScanning === 'enabled' ? '#F0F7E0' : '#FDE8E4',
                            color: state.features.codeScanning === 'enabled' ? '#7FBA00' : '#F25022',
                          }}
                        />
                      </td>
                    </TableRow>
                    <TableRow className={classes.tableRow}>
                      <td style={{ padding: '12px 16px', fontFamily: '"Inter", sans-serif', fontSize: 13, fontWeight: 600, color: '#171c21', borderBottom: '1px solid #eef1f6', display: 'flex', alignItems: 'center', gap: 8 }}>
                        <VpnKeyIcon style={{ fontSize: 16, color: '#F25022' }} /> Secret Scanning
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6' }}>
                        {state.secretScanning.count > 0
                          ? <Chip label="CRITICAL" size="small" className={classes.sevChip} style={{ background: '#FDE8E4', color: '#F25022' }} />
                          : <Chip label="CLEAN" size="small" className={classes.sevChip} style={{ background: '#F0F7E0', color: '#7FBA00' }} />
                        }
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6', textAlign: 'center', fontFamily: '"Inter", sans-serif', fontSize: 14, fontWeight: 800, color: '#171c21' }}>
                        {state.secretScanning.count}
                      </td>
                      <td style={{ padding: '12px 16px', borderBottom: '1px solid #eef1f6' }}>
                        <Chip
                          label={state.features.secretScanning === 'enabled' ? 'ACTIVE' : 'INACTIVE'}
                          size="small"
                          className={classes.enabledChip}
                          style={{
                            background: state.features.secretScanning === 'enabled' ? '#F0F7E0' : '#FDE8E4',
                            color: state.features.secretScanning === 'enabled' ? '#7FBA00' : '#F25022',
                          }}
                        />
                      </td>
                    </TableRow>
                    <TableRow className={classes.tableRow}>
                      <td style={{ padding: '12px 16px', fontFamily: '"Inter", sans-serif', fontSize: 13, fontWeight: 600, color: '#171c21', display: 'flex', alignItems: 'center', gap: 8 }}>
                        <VerifiedUserIcon style={{ fontSize: 16, color: '#00A4EF' }} /> Code Quality
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        {state.codeQuality.total > 0
                          ? <Chip label="WARNING" size="small" className={classes.sevChip} style={{ background: '#FFF8E1', color: '#FFB900' }} />
                          : <Chip label="CLEAN" size="small" className={classes.sevChip} style={{ background: '#F0F7E0', color: '#7FBA00' }} />
                        }
                      </td>
                      <td style={{ padding: '12px 16px', textAlign: 'center', fontFamily: '"Inter", sans-serif', fontSize: 14, fontWeight: 800, color: '#171c21' }}>
                        {state.codeQuality.total}
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <Chip
                          label={state.features.codeScanning === 'enabled' ? 'ACTIVE' : 'INACTIVE'}
                          size="small"
                          className={classes.enabledChip}
                          style={{
                            background: state.features.codeScanning === 'enabled' ? '#F0F7E0' : '#FDE8E4',
                            color: state.features.codeScanning === 'enabled' ? '#7FBA00' : '#F25022',
                          }}
                        />
                      </td>
                    </TableRow>
                  </TableBody>
                </Table>

                <Box mt={2} style={{ fontFamily: '"Inter", sans-serif', fontSize: 11, fontWeight: 600, color: '#717783', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <VerifiedUserIcon style={{ fontSize: 14 }} />
                  Per-component security details available in Catalog &gt; Entity &gt; Security tab
                </Box>
              </StyledCard>

              {/* Error banner */}
              {state.error && (
                <>
                  <div className={classes.spaceSm} />
                  <div className={classes.errorBanner}>
                    Note: {state.error}. Some data may be incomplete.
                  </div>
                </>
              )}
            </>
          )}
        </div>
      </Content>
    </Page>
  );
};

export default SecurityPage;
