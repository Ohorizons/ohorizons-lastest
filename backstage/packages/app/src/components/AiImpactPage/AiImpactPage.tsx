/**
 * AiImpactPage — AI Impact Dashboard
 *
 * Measures and visualizes the real impact of AI and Agentic DevOps on the SDLC.
 * Fetches data from the AI Impact backend (agent-api-impact on port 8011).
 *
 * Sections:
 * - Hero banner with AI Impact Score
 * - KPI metric cards (Adoption, Productivity, Velocity, Quality)
 * - On-demand LLM analysis
 * - RAG insights history
 */

import { useState, useEffect, useCallback } from 'react';
import {
  makeStyles,
  Typography,
  CircularProgress,
  Chip,
  LinearProgress,
  TextField,
  Button,
  IconButton,
  Tooltip,
} from '@material-ui/core';
import AssessmentIcon from '@material-ui/icons/Assessment';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import PeopleIcon from '@material-ui/icons/People';
import SpeedIcon from '@material-ui/icons/Speed';
import SecurityIcon from '@material-ui/icons/Security';
import RefreshIcon from '@material-ui/icons/Refresh';
import SendIcon from '@material-ui/icons/Send';
import EmojiObjectsIcon from '@material-ui/icons/EmojiObjects';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import WarningIcon from '@material-ui/icons/Warning';
import TimelineIcon from '@material-ui/icons/Timeline';
import MemoryIcon from '@material-ui/icons/Memory';
import { Page, Content } from '@backstage/core-components';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';
import ReactMarkdown from 'react-markdown';

// ── API Base URL ─────────────────────────────────────────────────────
const API_BASE = '/api/proxy/ai-impact';

// ── Types ────────────────────────────────────────────────────────────
interface ImpactSummary {
  calculated_at: string;
  ai_impact_score: number;
  adoption: {
    total_seats: number;
    active_seats: number;
    adoption_rate: number;
    plan_type: string;
  };
  productivity: {
    acceptance_rate: number;
    total_suggestions: number;
    total_acceptances: number;
    total_lines_accepted: number;
    estimated_hours_saved: number;
    estimated_cost_saved_usd: number;
  };
  velocity: {
    avg_merge_time_hours: number;
    merge_rate_pct: number;
    unique_contributors: number;
    deploy_frequency_per_day: number;
    deploy_classification: string;
  };
  quality: {
    change_failure_rate: number;
    cfr_classification: string;
    risk_level: string;
    total_vulnerabilities: number;
  };
}

interface Insight {
  text: string;
  category: string;
  timestamp: string;
}

// ── Styles ───────────────────────────────────────────────────────────
const useStyles = makeStyles({
  pageRoot: {
    minHeight: '100%',
    backgroundColor: '#f7f9ff',
    position: 'relative',
  },
  content: {
    padding: '24px 32px',
  },
  space: { height: 48 },
  spaceSm: { height: 24 },

  // KPI grid
  kpiGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 24,
  },
  kpiValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '2rem',
    fontWeight: 800,
    color: '#171c21',
    letterSpacing: '-0.02em',
    lineHeight: 1.2,
  },
  kpiLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
    marginTop: 4,
  },
  kpiIcon: {
    opacity: 0.15,
    fontSize: 48,
  },
  kpiHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  kpiChip: {
    fontWeight: 700,
    fontSize: 10,
    fontFamily: '"Inter", sans-serif',
    letterSpacing: '0.05em',
    height: 22,
  },

  // Section labels
  sectionLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 900,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.2em',
    marginBottom: 16,
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  sectionIcon: {
    fontSize: 16,
    verticalAlign: 'middle',
  },

  // Score gauge
  scoreContainer: {
    display: 'flex',
    alignItems: 'center',
    gap: 24,
    padding: '24px 0',
  },
  scoreCircle: {
    position: 'relative' as const,
    width: 120,
    height: 120,
    flexShrink: 0,
  },
  scoreValue: {
    position: 'absolute' as const,
    top: '50%',
    left: '50%',
    transform: 'translate(-50%, -50%)',
    fontFamily: '"Inter", sans-serif',
    fontSize: 32,
    fontWeight: 900,
    color: '#171c21',
  },
  scoreLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    textAlign: 'center' as const,
    marginTop: 4,
  },
  scoreDetails: {
    flex: 1,
  },
  scoreCategory: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '8px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': { borderBottom: 'none' },
  },
  scoreCatLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#404752',
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  scoreCatValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 800,
    color: '#171c21',
  },
  progressBar: {
    borderRadius: 4,
    height: 6,
    flex: 1,
    margin: '0 16px',
  },

  // Two-column layout
  twoCol: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 24,
  },

  // Analysis section
  analyzeInput: {
    display: 'flex',
    gap: 12,
    marginBottom: 16,
  },
  analysisResult: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    lineHeight: 1.8,
    color: '#404752',
    '& h2': {
      fontSize: 18,
      fontWeight: 800,
      color: '#171c21',
      marginTop: 16,
      marginBottom: 8,
    },
    '& h3': {
      fontSize: 15,
      fontWeight: 700,
      color: '#171c21',
      marginTop: 12,
      marginBottom: 6,
    },
    '& strong': {
      color: '#171c21',
      fontWeight: 700,
    },
    '& ul, & ol': {
      paddingLeft: 20,
      margin: '8px 0',
    },
    '& li': {
      marginBottom: 4,
    },
    '& hr': {
      border: 'none',
      borderTop: '1px solid rgba(0,0,0,0.06)',
      margin: '16px 0',
    },
    '& blockquote': {
      borderLeft: '3px solid #0078D4',
      paddingLeft: 16,
      margin: '12px 0',
      color: '#0078D4',
      fontStyle: 'italic' as const,
    },
  },
  analysisEmpty: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    color: '#a0a7b4',
    fontStyle: 'italic' as const,
    padding: '24px 0',
    textAlign: 'center' as const,
  },

  // Insights
  insightItem: {
    padding: '12px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': { borderBottom: 'none' },
  },
  insightText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 500,
    color: '#404752',
    lineHeight: 1.5,
  },
  insightMeta: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    marginTop: 6,
  },
  insightChip: {
    height: 20,
    fontSize: 10,
    fontWeight: 700,
    fontFamily: '"Inter", sans-serif',
    letterSpacing: '0.05em',
  },
  insightDate: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    color: '#a0a7b4',
  },

  // Loading / Error states
  centerBox: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    justifyContent: 'center',
    padding: '64px 0',
    gap: 16,
  },
  errorText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    color: '#F25022',
    fontWeight: 600,
  },

  // Detail rows
  detailGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 16,
  },
  detailRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '8px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': { borderBottom: 'none' },
  },
  detailLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 500,
    color: '#717783',
  },
  detailValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 700,
    color: '#171c21',
  },
});

// ── Helpers ──────────────────────────────────────────────────────────
function scoreColor(score: number): string {
  if (score >= 80) return '#7FBA00';
  if (score >= 60) return '#00A4EF';
  if (score >= 40) return '#FFB900';
  return '#F25022';
}

function classificationColor(c: string): string {
  switch (c) {
    case 'elite': return '#7FBA00';
    case 'high': return '#00A4EF';
    case 'medium': return '#FFB900';
    case 'low': return '#F25022';
    default: return '#717783';
  }
}

function riskColor(r: string): string {
  switch (r) {
    case 'low': return '#7FBA00';
    case 'medium': return '#FFB900';
    case 'high': return '#F25022';
    case 'critical': return '#a4262c';
    default: return '#717783';
  }
}

// ── Component ────────────────────────────────────────────────────────
const AiImpactPage = () => {
  const classes = useStyles();

  const [summary, setSummary] = useState<ImpactSummary | null>(null);
  const [insights, setInsights] = useState<Insight[]>([]);
  const [insightsCount, setInsightsCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Analysis state
  const [question, setQuestion] = useState('');
  const [analysis, setAnalysis] = useState('');
  const [analyzing, setAnalyzing] = useState(false);

  const fetchSummary = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const res = await fetch(`${API_BASE}/api/impact/summary`);
      if (!res.ok) throw new Error(`API returned ${res.status}`);
      const data: ImpactSummary = await res.json();
      setSummary(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch impact data');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchInsights = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/api/impact/insights`);
      if (!res.ok) return;
      const data = await res.json();
      setInsights(data.insights || []);
      setInsightsCount(data.total || 0);
    } catch {
      // non-critical
    }
  }, []);

  useEffect(() => {
    fetchSummary();
    fetchInsights();
  }, [fetchSummary, fetchInsights]);

  const handleAnalyze = async () => {
    if (analyzing) return;
    setAnalyzing(true);
    setAnalysis('');
    try {
      const res = await fetch(`${API_BASE}/api/impact/analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ question: question || undefined }),
      });
      if (!res.ok) throw new Error(`Analysis failed: ${res.status}`);
      const data = await res.json();
      setAnalysis(data.analysis || 'No analysis returned.');
      setInsightsCount(data.insights_stored || insightsCount);
      fetchInsights();
    } catch (err) {
      setAnalysis(`Error: ${err instanceof Error ? err.message : 'Analysis failed'}`);
    } finally {
      setAnalyzing(false);
    }
  };

  // ── Loading state ─────────────────────────────────────────────────
  if (loading) {
    return (
      <Page themeId="tool">
        <Content>
          <div className={classes.centerBox}>
            <CircularProgress size={48} style={{ color: '#0078D4' }} />
            <Typography style={{ fontFamily: '"Inter", sans-serif', color: '#717783' }}>
              Collecting AI Impact metrics...
            </Typography>
          </div>
        </Content>
      </Page>
    );
  }

  // ── Error state ───────────────────────────────────────────────────
  if (error) {
    return (
      <Page themeId="tool">
        <Content>
          <div className={classes.pageRoot}>
            <div className={classes.content}>
              <HeroBanner
                icon={<AssessmentIcon style={{ color: '#F25022', fontSize: 28 }} />}
                label="AI Impact"
                title="AI Impact Dashboard"
                subtitle="Unable to connect to the AI Impact backend."
                accentColor="#F25022"
              />
              <div className={classes.space} />
              <div className={classes.centerBox}>
                <WarningIcon style={{ fontSize: 48, color: '#F25022' }} />
                <Typography className={classes.errorText}>{error}</Typography>
                <Button
                  variant="outlined"
                  onClick={fetchSummary}
                  startIcon={<RefreshIcon />}
                  style={{ marginTop: 16 }}
                >
                  Retry
                </Button>
              </div>
            </div>
          </div>
        </Content>
      </Page>
    );
  }

  const s = summary!;
  const sc = s.ai_impact_score;

  return (
    <Page themeId="tool">
      <Content>
        <div className={classes.pageRoot}>
          <div className={classes.content}>
            {/* ── Hero Banner ──────────────────────────────────── */}
            <HeroBanner
              icon={<AssessmentIcon style={{ color: '#0078D4', fontSize: 28 }} />}
              label="AI Impact"
              title={<>AI Impact<br />Dashboard</>}
              subtitle="Measure the real impact of AI and Agentic DevOps on your software development lifecycle. Powered by GitHub APIs, KPI engine, and Claude Opus."
              accentColor="#0078D4"
              stats={[
                {
                  label: 'Impact Score',
                  value: `${sc}/100`,
                  icon: <AssessmentIcon style={{ fontSize: 20 }} />,
                  color: scoreColor(sc),
                },
                {
                  label: 'Deploy Freq',
                  value: `${s.velocity.deploy_frequency_per_day}/day`,
                  icon: <SpeedIcon style={{ fontSize: 20 }} />,
                  color: '#00A4EF',
                },
                {
                  label: 'Contributors',
                  value: `${s.velocity.unique_contributors}`,
                  icon: <PeopleIcon style={{ fontSize: 20 }} />,
                  color: '#7FBA00',
                },
                {
                  label: 'Insights',
                  value: `${insightsCount}`,
                  icon: <EmojiObjectsIcon style={{ fontSize: 20 }} />,
                  color: '#FFB900',
                },
              ]}
              primaryAction={{
                label: 'Run AI Analysis',
                onClick: handleAnalyze,
              }}
              secondaryAction={{
                label: 'Refresh Data',
                onClick: fetchSummary,
              }}
            />

            <div className={classes.space} />

            {/* ── KPI Cards ───────────────────────────────────── */}
            <Typography className={classes.sectionLabel}>
              <TrendingUpIcon className={classes.sectionIcon} /> Key Performance Indicators
            </Typography>
            <div className={classes.kpiGrid}>
              {/* Adoption */}
              <StyledCard title="Adoption" subtitle="Copilot seat utilization">
                <div className={classes.kpiHeader}>
                  <div>
                    <div className={classes.kpiValue}>{s.adoption.adoption_rate}%</div>
                    <div className={classes.kpiLabel}>Adoption Rate</div>
                  </div>
                  <PeopleIcon className={classes.kpiIcon} style={{ color: '#0078D4' }} />
                </div>
                <div style={{ marginTop: 16 }}>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Total Seats</span>
                    <span className={classes.detailValue}>{s.adoption.total_seats}</span>
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Active Seats</span>
                    <span className={classes.detailValue}>{s.adoption.active_seats}</span>
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Plan</span>
                    <Chip
                      label={s.adoption.plan_type}
                      size="small"
                      className={classes.kpiChip}
                      style={{ backgroundColor: '#e8f4fd', color: '#0078D4' }}
                    />
                  </div>
                </div>
              </StyledCard>

              {/* Productivity */}
              <StyledCard title="Productivity" subtitle="Copilot effectiveness">
                <div className={classes.kpiHeader}>
                  <div>
                    <div className={classes.kpiValue}>{s.productivity.acceptance_rate}%</div>
                    <div className={classes.kpiLabel}>Acceptance Rate</div>
                  </div>
                  <SpeedIcon className={classes.kpiIcon} style={{ color: '#7FBA00' }} />
                </div>
                <div style={{ marginTop: 16 }}>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Suggestions</span>
                    <span className={classes.detailValue}>{s.productivity.total_suggestions.toLocaleString()}</span>
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Lines Accepted</span>
                    <span className={classes.detailValue}>{s.productivity.total_lines_accepted.toLocaleString()}</span>
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Hours Saved</span>
                    <span className={classes.detailValue} style={{ color: '#7FBA00' }}>{s.productivity.estimated_hours_saved}h</span>
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Cost Saved</span>
                    <span className={classes.detailValue} style={{ color: '#7FBA00' }}>${s.productivity.estimated_cost_saved_usd}</span>
                  </div>
                </div>
              </StyledCard>

              {/* Velocity */}
              <StyledCard title="Velocity" subtitle="Development speed">
                <div className={classes.kpiHeader}>
                  <div>
                    <div className={classes.kpiValue}>{s.velocity.deploy_frequency_per_day}</div>
                    <div className={classes.kpiLabel}>Deploys / Day</div>
                  </div>
                  <TrendingUpIcon className={classes.kpiIcon} style={{ color: '#00A4EF' }} />
                </div>
                <div style={{ marginTop: 16 }}>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Classification</span>
                    <Chip
                      label={s.velocity.deploy_classification}
                      size="small"
                      className={classes.kpiChip}
                      style={{
                        backgroundColor: `${classificationColor(s.velocity.deploy_classification)}22`,
                        color: classificationColor(s.velocity.deploy_classification),
                      }}
                    />
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Merge Rate</span>
                    <span className={classes.detailValue}>{s.velocity.merge_rate_pct}%</span>
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Avg Merge Time</span>
                    <span className={classes.detailValue}>{s.velocity.avg_merge_time_hours}h</span>
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Contributors</span>
                    <span className={classes.detailValue}>{s.velocity.unique_contributors}</span>
                  </div>
                </div>
              </StyledCard>

              {/* Quality */}
              <StyledCard title="Quality" subtitle="Reliability & security">
                <div className={classes.kpiHeader}>
                  <div>
                    <div className={classes.kpiValue}>{s.quality.change_failure_rate}%</div>
                    <div className={classes.kpiLabel}>Change Failure Rate</div>
                  </div>
                  <SecurityIcon className={classes.kpiIcon} style={{ color: '#F25022' }} />
                </div>
                <div style={{ marginTop: 16 }}>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>CFR Class</span>
                    <Chip
                      label={s.quality.cfr_classification}
                      size="small"
                      className={classes.kpiChip}
                      style={{
                        backgroundColor: `${classificationColor(s.quality.cfr_classification)}22`,
                        color: classificationColor(s.quality.cfr_classification),
                      }}
                    />
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Risk Level</span>
                    <Chip
                      label={s.quality.risk_level}
                      size="small"
                      className={classes.kpiChip}
                      style={{
                        backgroundColor: `${riskColor(s.quality.risk_level)}22`,
                        color: riskColor(s.quality.risk_level),
                      }}
                    />
                  </div>
                  <div className={classes.detailRow}>
                    <span className={classes.detailLabel}>Vulnerabilities</span>
                    <span className={classes.detailValue}>
                      {s.quality.total_vulnerabilities === 0 ? (
                        <span style={{ color: '#7FBA00', display: 'flex', alignItems: 'center', gap: 4 }}>
                          <CheckCircleIcon style={{ fontSize: 14 }} /> 0
                        </span>
                      ) : s.quality.total_vulnerabilities}
                    </span>
                  </div>
                </div>
              </StyledCard>
            </div>

            <div className={classes.space} />

            {/* ── AI Impact Score Breakdown ────────────────────── */}
            <div className={classes.twoCol}>
              <div>
                <Typography className={classes.sectionLabel}>
                  <AssessmentIcon className={classes.sectionIcon} /> AI Impact Score Breakdown
                </Typography>
                <StyledCard>
                  <div className={classes.scoreContainer}>
                    <div className={classes.scoreCircle}>
                      <CircularProgress
                        variant="determinate"
                        value={100}
                        size={120}
                        thickness={4}
                        style={{ color: '#e8edf2', position: 'absolute' }}
                      />
                      <CircularProgress
                        variant="determinate"
                        value={sc}
                        size={120}
                        thickness={4}
                        style={{ color: scoreColor(sc) }}
                      />
                      <div className={classes.scoreValue}>{sc}</div>
                    </div>
                    <div className={classes.scoreDetails}>
                      <div className={classes.scoreCategory}>
                        <span className={classes.scoreCatLabel}>
                          <PeopleIcon style={{ fontSize: 14, color: '#0078D4' }} /> Adoption
                        </span>
                        <LinearProgress
                          variant="determinate"
                          value={Math.min(s.adoption.adoption_rate, 100)}
                          className={classes.progressBar}
                          style={{ backgroundColor: '#e8edf2' }}
                        />
                        <span className={classes.scoreCatValue}>{s.adoption.adoption_rate}%</span>
                      </div>
                      <div className={classes.scoreCategory}>
                        <span className={classes.scoreCatLabel}>
                          <SpeedIcon style={{ fontSize: 14, color: '#7FBA00' }} /> Productivity
                        </span>
                        <LinearProgress
                          variant="determinate"
                          value={Math.min(s.productivity.acceptance_rate, 100)}
                          className={classes.progressBar}
                          style={{ backgroundColor: '#e8edf2' }}
                        />
                        <span className={classes.scoreCatValue}>{s.productivity.acceptance_rate}%</span>
                      </div>
                      <div className={classes.scoreCategory}>
                        <span className={classes.scoreCatLabel}>
                          <TrendingUpIcon style={{ fontSize: 14, color: '#00A4EF' }} /> Velocity
                        </span>
                        <LinearProgress
                          variant="determinate"
                          value={Math.min(s.velocity.merge_rate_pct, 100)}
                          className={classes.progressBar}
                          style={{ backgroundColor: '#e8edf2' }}
                        />
                        <span className={classes.scoreCatValue}>{s.velocity.merge_rate_pct}%</span>
                      </div>
                      <div className={classes.scoreCategory}>
                        <span className={classes.scoreCatLabel}>
                          <SecurityIcon style={{ fontSize: 14, color: '#F25022' }} /> Quality
                        </span>
                        <LinearProgress
                          variant="determinate"
                          value={Math.min(100 - s.quality.change_failure_rate, 100)}
                          className={classes.progressBar}
                          style={{ backgroundColor: '#e8edf2' }}
                        />
                        <span className={classes.scoreCatValue}>{(100 - s.quality.change_failure_rate).toFixed(0)}%</span>
                      </div>
                    </div>
                  </div>
                  <Typography style={{
                    fontFamily: '"Inter", sans-serif',
                    fontSize: 11,
                    color: '#a0a7b4',
                    textAlign: 'center',
                    marginTop: 8,
                  }}>
                    Last updated: {new Date(s.calculated_at).toLocaleString()}
                  </Typography>
                </StyledCard>
              </div>

              {/* ── RAG Insights ────────────────────────────────── */}
              <div>
                <Typography className={classes.sectionLabel}>
                  <EmojiObjectsIcon className={classes.sectionIcon} /> Learned Insights ({insightsCount})
                  <Tooltip title="Refresh insights">
                    <IconButton size="small" onClick={fetchInsights}>
                      <RefreshIcon style={{ fontSize: 14 }} />
                    </IconButton>
                  </Tooltip>
                </Typography>
                <StyledCard>
                  {insights.length === 0 ? (
                    <div className={classes.analysisEmpty}>
                      <MemoryIcon style={{ fontSize: 32, opacity: 0.3, display: 'block', margin: '0 auto 8px' }} />
                      No insights stored yet. Run an AI Analysis to generate and learn insights.
                    </div>
                  ) : (
                    insights.map((ins, i) => (
                      <div key={i} className={classes.insightItem}>
                        <div className={classes.insightText}>{ins.text}</div>
                        <div className={classes.insightMeta}>
                          <Chip
                            label={ins.category}
                            size="small"
                            className={classes.insightChip}
                            style={{ backgroundColor: '#e8f4fd', color: '#0078D4' }}
                          />
                          {ins.timestamp && (
                            <span className={classes.insightDate}>
                              {new Date(ins.timestamp).toLocaleDateString()}
                            </span>
                          )}
                        </div>
                      </div>
                    ))
                  )}
                </StyledCard>
              </div>
            </div>

            <div className={classes.space} />

            {/* ── On-Demand LLM Analysis ──────────────────────── */}
            <Typography className={classes.sectionLabel}>
              <TimelineIcon className={classes.sectionIcon} /> On-Demand AI Analysis
            </Typography>
            <StyledCard title="Ask the AI Impact Analyzer" subtitle="Powered by Claude Opus">
              <div className={classes.analyzeInput}>
                <TextField
                  fullWidth
                  variant="outlined"
                  size="small"
                  placeholder="Ask a question (e.g., 'How is our Copilot adoption trending?') or leave empty for a full analysis..."
                  value={question}
                  onChange={e => setQuestion(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && handleAnalyze()}
                  disabled={analyzing}
                  InputProps={{
                    style: { fontFamily: '"Inter", sans-serif', fontSize: 13 },
                  }}
                />
                <Button
                  variant="contained"
                  onClick={handleAnalyze}
                  disabled={analyzing}
                  style={{
                    backgroundColor: analyzing ? '#a0a7b4' : '#0078D4',
                    color: '#fff',
                    fontFamily: '"Inter", sans-serif',
                    fontWeight: 700,
                    textTransform: 'none',
                    minWidth: 120,
                  }}
                  startIcon={analyzing ? <CircularProgress size={16} style={{ color: '#fff' }} /> : <SendIcon />}
                >
                  {analyzing ? 'Analyzing...' : 'Analyze'}
                </Button>
              </div>

              {analysis ? (
                <div className={classes.analysisResult}>
                  <ReactMarkdown>{analysis}</ReactMarkdown>
                </div>
              ) : (
                <div className={classes.analysisEmpty}>
                  Click "Analyze" to collect metrics, generate insights, and get AI-powered recommendations. The agent will automatically store novel insights for future reference.
                </div>
              )}
            </StyledCard>

            <div className={classes.space} />
          </div>
        </div>
      </Content>
    </Page>
  );
};

export default AiImpactPage;
