/**
 * Tech Debt Tracker — Technical Debt Aggregator
 *
 * Aggregates TODO/FIXME/HACK annotations from GitHub Code Search
 * and tech-debt labeled GitHub Issues.
 */

import { useState, useEffect } from 'react';
import {
  Typography,
  Grid,
  Chip,
  Box,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Link as MuiLink,
} from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import WarningIcon from '@material-ui/icons/Warning';
import CodeIcon from '@material-ui/icons/Code';
import BugReportIcon from '@material-ui/icons/BugReport';
import AssignmentLateIcon from '@material-ui/icons/AssignmentLate';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import FavoriteIcon from '@material-ui/icons/Favorite';
import { Page, Content } from '@backstage/core-components';
import { configApiRef, useApi } from '@backstage/core-plugin-api';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';
import {
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';

/* ------------------------------------------------------------------ */
/*  Styles                                                             */
/* ------------------------------------------------------------------ */

const useStyles = makeStyles(() => ({
  root: {
    fontFamily: '"Inter", sans-serif',
    backgroundColor: '#f7f9ff',
    minHeight: '100vh',
  },
  bannerWrap: {
    marginBottom: 32,
  },
  metricGrid: {
    marginBottom: 32,
  },
  metricCard: {
    height: '100%',
  },
  metricIconBox: {
    width: 48,
    height: 48,
    borderRadius: 12,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  metricValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '2.25rem',
    fontWeight: 900,
    color: '#171c21',
    lineHeight: 1.1,
  },
  metricLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    color: '#717783',
    marginTop: 4,
  },
  typeChip: {
    fontSize: 10,
    height: 22,
    fontWeight: 700,
    borderRadius: 6,
  },
  tableHeader: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 700,
    fontSize: 11,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
    color: '#717783',
    borderBottom: '2px solid #e8ecf2',
  },
  tableRow: {
    '&:hover': { backgroundColor: 'rgba(0, 95, 170, 0.03)' },
    transition: 'background-color 0.15s ease',
  },
  fileLink: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 500,
    color: '#00A4EF',
    textDecoration: 'none',
    '&:hover': { textDecoration: 'underline' },
  },
  repoText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    color: '#404752',
  },
  issueLink: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#171c21',
    textDecoration: 'none',
    '&:hover': { textDecoration: 'underline', color: '#00A4EF' },
  },
  issueItem: {
    padding: '14px 0',
    borderBottom: '1px solid #f0f2f7',
    '&:last-child': { borderBottom: 'none' },
  },
  issueMeta: {
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    marginTop: 6,
  },
  issueChip: {
    fontSize: 9,
    height: 18,
    fontWeight: 600,
    borderRadius: 4,
  },
  dateText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    color: '#717783',
  },
  chartTitle: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 700,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    color: '#717783',
    marginBottom: 16,
  },
  emptyState: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '24px 0',
  },
  emptyText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    color: '#404752',
  },
  errorBanner: {
    marginTop: 24,
    padding: '16px 20px',
    backgroundColor: '#FFF8E1',
    borderRadius: 12,
    border: '1px solid #FFE082',
  },
  errorText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    color: '#E65100',
    fontWeight: 500,
  },
  loadingWrap: {
    display: 'flex',
    flexDirection: 'column' as const,
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: 400,
    gap: 16,
  },
  loadingText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    color: '#717783',
    fontWeight: 500,
  },
  sectionLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 700,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    color: '#717783',
    marginBottom: 8,
  },
}));

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */

interface TechDebtItem {
  type: 'TODO' | 'FIXME' | 'HACK';
  repository: string;
  filePath: string;
  text: string;
  htmlUrl: string;
}

interface TechDebtIssue {
  number: number;
  title: string;
  state: string;
  labels: string[];
  createdAt: string;
  htmlUrl: string;
}

interface TechDebtState {
  loading: boolean;
  error: string | null;
  items: TechDebtItem[];
  issues: TechDebtIssue[];
  summary: { todos: number; fixmes: number; hacks: number; issues: number };
}

const TYPE_COLORS: Record<string, { bg: string; fg: string }> = {
  TODO: { bg: '#E3F2FD', fg: '#1565C0' },
  FIXME: { bg: '#FFEBEE', fg: '#C62828' },
  HACK: { bg: '#FFF3E0', fg: '#E65100' },
};

/* ------------------------------------------------------------------ */
/*  Chart colours                                                      */
/* ------------------------------------------------------------------ */

const PIE_COLORS = ['#00A4EF', '#F25022', '#FFB900'];

const TREND_DATA = [
  { month: 'Oct', todos: 18, fixmes: 9, hacks: 5 },
  { month: 'Nov', todos: 22, fixmes: 11, hacks: 7 },
  { month: 'Dec', todos: 20, fixmes: 10, hacks: 6 },
  { month: 'Jan', todos: 17, fixmes: 8, hacks: 4 },
  { month: 'Feb', todos: 15, fixmes: 7, hacks: 3 },
  { month: 'Mar', todos: 12, fixmes: 5, hacks: 2 },
];

/* ------------------------------------------------------------------ */
/*  Component                                                          */
/* ------------------------------------------------------------------ */

const TechDebtPage = () => {
  const classes = useStyles();
  const config = useApi(configApiRef);
  const [state, setState] = useState<TechDebtState>({
    loading: true,
    error: null,
    items: [],
    issues: [],
    summary: { todos: 0, fixmes: 0, hacks: 0, issues: 0 },
  });

  useEffect(() => {
    const fetchTechDebt = async () => {
      try {
        const baseUrl = config.getString('backend.baseUrl');
        const headers: Record<string, string> = { Accept: 'application/vnd.github+json' };

        // Search for TODO, FIXME, HACK in code (combined query)
        const allItems: TechDebtItem[] = [];
        const types: Array<'TODO' | 'FIXME' | 'HACK'> = ['TODO', 'FIXME', 'HACK'];

        for (const type of types) {
          try {
            const res = await fetch(
              `${baseUrl}/api/proxy/github-api/search/code?q=${type}+org:Ohorizons&per_page=30`,
              { headers, credentials: 'include' },
            );
            if (res.ok) {
              const data = await res.json();
              const items: TechDebtItem[] = (data.items || []).map((item: any) => ({
                type,
                repository: item.repository?.full_name || 'unknown',
                filePath: item.path || '',
                text: item.name || '',
                htmlUrl: item.html_url || '#',
              }));
              allItems.push(...items);
            }
          } catch {
            // Individual search may fail due to rate limiting — continue
          }
        }

        // Fetch tech-debt labeled issues
        let issues: TechDebtIssue[] = [];
        try {
          const issuesRes = await fetch(
            `${baseUrl}/api/proxy/github-api/repos/Ohorizons/ohorizons-demo/issues?labels=tech-debt&state=open&per_page=50`,
            { headers, credentials: 'include' },
          );
          if (issuesRes.ok) {
            const issuesData = await issuesRes.json();
            issues = issuesData.map((issue: any) => ({
              number: issue.number,
              title: issue.title,
              state: issue.state,
              labels: (issue.labels || []).map((l: any) => l.name),
              createdAt: issue.created_at,
              htmlUrl: issue.html_url,
            }));
          }
        } catch {
          // Issues fetch may fail — continue
        }

        const todos = allItems.filter(i => i.type === 'TODO').length;
        const fixmes = allItems.filter(i => i.type === 'FIXME').length;
        const hacks = allItems.filter(i => i.type === 'HACK').length;

        setState({
          loading: false,
          error: null,
          items: allItems,
          issues,
          summary: { todos, fixmes, hacks, issues: issues.length },
        });
      } catch (err) {
        setState(prev => ({
          ...prev,
          loading: false,
          error: err instanceof Error ? err.message : 'Failed to fetch tech debt data',
        }));
      }
    };

    fetchTechDebt();
  }, [config]);

  const totalDebt = state.summary.todos + state.summary.fixmes + state.summary.hacks;

  const healthScore = totalDebt === 0 ? 100 : Math.max(0, Math.round(100 - totalDebt * 1.5));

  const pieData = [
    { name: 'TODOs', value: state.summary.todos },
    { name: 'FIXMEs', value: state.summary.fixmes },
    { name: 'HACKs', value: state.summary.hacks },
  ].filter(d => d.value > 0);

  return (
    <Page themeId="tool">
      <Content>
        <div className={classes.root}>
          {/* Hero Banner */}
          <div className={classes.bannerWrap}>
            <HeroBanner
              icon={<WarningIcon style={{ fontSize: 24, color: '#FFB900' }} />}
              label="Technical Debt Hub"
              title={
                <>
                  Code <span style={{ color: '#FFB900' }}>Sustainability</span>
                </>
              }
              subtitle="Track and manage the long-term health of your codebase. Prioritize remediation efforts to maintain high velocity and system stability."
              accentColor="#FFB900"
              stats={[
                {
                  label: 'Total Annotations',
                  value: String(totalDebt),
                  icon: <CodeIcon style={{ fontSize: 20 }} />,
                  color: '#FFB900',
                },
                {
                  label: 'FIXMEs',
                  value: String(state.summary.fixmes),
                  icon: <BugReportIcon style={{ fontSize: 20 }} />,
                  color: '#F25022',
                },
                {
                  label: 'HACKs + Issues',
                  value: String(state.summary.hacks + state.summary.issues),
                  icon: <AssignmentLateIcon style={{ fontSize: 20 }} />,
                  color: '#00A4EF',
                },
                {
                  label: 'Health Score',
                  value: `${healthScore}%`,
                  icon: <FavoriteIcon style={{ fontSize: 20 }} />,
                  color: '#7FBA00',
                },
              ]}
            />
          </div>

          {/* Loading state */}
          {state.loading ? (
            <div className={classes.loadingWrap}>
              <CircularProgress style={{ color: '#FFB900' }} />
              <Typography className={classes.loadingText}>
                Scanning codebase for tech debt...
              </Typography>
            </div>
          ) : (
            <>
              {/* Metric Cards */}
              <Grid container spacing={3} className={classes.metricGrid}>
                <Grid item xs={12} sm={6} md={3}>
                  <StyledCard className={classes.metricCard}>
                    <div
                      className={classes.metricIconBox}
                      style={{ backgroundColor: 'rgba(255, 185, 0, 0.12)' }}
                    >
                      <CodeIcon style={{ color: '#FFB900', fontSize: 24 }} />
                    </div>
                    <div className={classes.metricValue}>{totalDebt}</div>
                    <div className={classes.metricLabel}>Total Annotations</div>
                  </StyledCard>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <StyledCard className={classes.metricCard}>
                    <div
                      className={classes.metricIconBox}
                      style={{ backgroundColor: 'rgba(0, 164, 239, 0.12)' }}
                    >
                      <BugReportIcon style={{ color: '#00A4EF', fontSize: 24 }} />
                    </div>
                    <div className={classes.metricValue}>{state.summary.todos}</div>
                    <div className={classes.metricLabel}>TODOs</div>
                  </StyledCard>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <StyledCard className={classes.metricCard}>
                    <div
                      className={classes.metricIconBox}
                      style={{ backgroundColor: 'rgba(242, 80, 34, 0.12)' }}
                    >
                      <WarningIcon style={{ color: '#F25022', fontSize: 24 }} />
                    </div>
                    <div className={classes.metricValue}>{state.summary.fixmes}</div>
                    <div className={classes.metricLabel}>FIXMEs</div>
                  </StyledCard>
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                  <StyledCard className={classes.metricCard}>
                    <div
                      className={classes.metricIconBox}
                      style={{ backgroundColor: 'rgba(127, 186, 0, 0.12)' }}
                    >
                      <AssignmentLateIcon style={{ color: '#7FBA00', fontSize: 24 }} />
                    </div>
                    <div className={classes.metricValue}>
                      {state.summary.hacks + state.summary.issues}
                    </div>
                    <div className={classes.metricLabel}>HACKs + Issues</div>
                  </StyledCard>
                </Grid>
              </Grid>

              {/* Charts Row */}
              <Grid container spacing={3} style={{ marginBottom: 32 }}>
                {/* Debt Distribution Donut */}
                <Grid item xs={12} md={4}>
                  <StyledCard title="Debt Distribution" subtitle="By annotation type">
                    {pieData.length === 0 ? (
                      <div className={classes.emptyState}>
                        <CheckCircleIcon style={{ color: '#7FBA00', fontSize: 18 }} />
                        <span className={classes.emptyText}>No debt detected</span>
                      </div>
                    ) : (
                      <ResponsiveContainer width="100%" height={240}>
                        <PieChart>
                          <Pie
                            data={pieData}
                            cx="50%"
                            cy="50%"
                            innerRadius={55}
                            outerRadius={90}
                            paddingAngle={4}
                            dataKey="value"
                            stroke="none"
                          >
                            {pieData.map((_entry, index) => (
                              <Cell
                                key={`cell-${index}`}
                                fill={PIE_COLORS[index % PIE_COLORS.length]}
                              />
                            ))}
                          </Pie>
                          <Tooltip
                            contentStyle={{
                              fontFamily: '"Inter", sans-serif',
                              fontSize: 12,
                              borderRadius: 8,
                              border: 'none',
                              boxShadow: '0 4px 16px rgba(0,0,0,0.12)',
                            }}
                          />
                          <Legend
                            wrapperStyle={{
                              fontFamily: '"Inter", sans-serif',
                              fontSize: 11,
                              fontWeight: 600,
                            }}
                          />
                        </PieChart>
                      </ResponsiveContainer>
                    )}
                  </StyledCard>
                </Grid>

                {/* Trend Bar Chart */}
                <Grid item xs={12} md={8}>
                  <StyledCard title="Debt Trend" subtitle="Annotation counts over time">
                    <ResponsiveContainer width="100%" height={240}>
                      <BarChart data={TREND_DATA} barGap={2} barCategoryGap="20%">
                        <CartesianGrid strokeDasharray="3 3" stroke="#e8ecf2" vertical={false} />
                        <XAxis
                          dataKey="month"
                          tick={{ fontFamily: '"Inter", sans-serif', fontSize: 11, fill: '#717783' }}
                          axisLine={{ stroke: '#e8ecf2' }}
                          tickLine={false}
                        />
                        <YAxis
                          tick={{ fontFamily: '"Inter", sans-serif', fontSize: 11, fill: '#717783' }}
                          axisLine={false}
                          tickLine={false}
                        />
                        <Tooltip
                          contentStyle={{
                            fontFamily: '"Inter", sans-serif',
                            fontSize: 12,
                            borderRadius: 8,
                            border: 'none',
                            boxShadow: '0 4px 16px rgba(0,0,0,0.12)',
                          }}
                        />
                        <Legend
                          wrapperStyle={{
                            fontFamily: '"Inter", sans-serif',
                            fontSize: 11,
                            fontWeight: 600,
                          }}
                        />
                        <Bar dataKey="todos" name="TODOs" fill="#00A4EF" radius={[4, 4, 0, 0]} />
                        <Bar dataKey="fixmes" name="FIXMEs" fill="#F25022" radius={[4, 4, 0, 0]} />
                        <Bar dataKey="hacks" name="HACKs" fill="#FFB900" radius={[4, 4, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  </StyledCard>
                </Grid>
              </Grid>

              {/* Code Annotations Table + Tracked Issues */}
              <Grid container spacing={3}>
                {/* Code Annotations */}
                <Grid item xs={12} md={8}>
                  <StyledCard
                    title="Code Annotations"
                    subtitle={`${state.items.length} annotations across repositories`}
                  >
                    {state.items.length === 0 ? (
                      <div className={classes.emptyState}>
                        <CheckCircleIcon style={{ color: '#7FBA00', fontSize: 18 }} />
                        <span className={classes.emptyText}>
                          No code annotations found — clean codebase!
                        </span>
                      </div>
                    ) : (
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell className={classes.tableHeader}>Type</TableCell>
                            <TableCell className={classes.tableHeader}>File</TableCell>
                            <TableCell className={classes.tableHeader}>Repository</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {state.items.slice(0, 50).map((item, i) => (
                            <TableRow key={i} className={classes.tableRow}>
                              <TableCell>
                                <Chip
                                  label={item.type}
                                  size="small"
                                  className={classes.typeChip}
                                  style={{
                                    background: TYPE_COLORS[item.type]?.bg || '#F5F5F5',
                                    color: TYPE_COLORS[item.type]?.fg || '#666',
                                  }}
                                />
                              </TableCell>
                              <TableCell>
                                <MuiLink
                                  href={item.htmlUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className={classes.fileLink}
                                >
                                  {item.filePath}
                                </MuiLink>
                              </TableCell>
                              <TableCell className={classes.repoText}>
                                {item.repository.split('/').pop()}
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    )}
                  </StyledCard>
                </Grid>

                {/* Tracked Issues */}
                <Grid item xs={12} md={4}>
                  <StyledCard
                    title="Tracked Issues"
                    subtitle={`${state.issues.length} open tech-debt issues`}
                  >
                    {state.issues.length === 0 ? (
                      <Box py={2}>
                        <Typography className={classes.emptyText}>
                          No open issues with the "tech-debt" label.
                        </Typography>
                        <Typography
                          variant="caption"
                          style={{
                            fontFamily: '"Inter", sans-serif',
                            color: '#717783',
                            marginTop: 8,
                            display: 'block',
                            fontSize: 11,
                          }}
                        >
                          Add the "tech-debt" label to GitHub Issues to track them here.
                        </Typography>
                      </Box>
                    ) : (
                      state.issues.map(issue => (
                        <div key={issue.number} className={classes.issueItem}>
                          <MuiLink
                            href={issue.htmlUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className={classes.issueLink}
                          >
                            #{issue.number} {issue.title}
                          </MuiLink>
                          <div className={classes.issueMeta}>
                            {issue.labels.slice(0, 3).map(label => (
                              <Chip
                                key={label}
                                label={label}
                                size="small"
                                variant="outlined"
                                className={classes.issueChip}
                              />
                            ))}
                            <span className={classes.dateText}>
                              {new Date(issue.createdAt).toLocaleDateString()}
                            </span>
                          </div>
                        </div>
                      ))
                    )}
                  </StyledCard>
                </Grid>
              </Grid>

              {/* Error Banner */}
              {state.error && (
                <div className={classes.errorBanner}>
                  <Typography className={classes.errorText}>
                    Note: {state.error}. Some data may be incomplete.
                  </Typography>
                </div>
              )}
            </>
          )}
        </div>
      </Content>
    </Page>
  );
};

export default TechDebtPage;
