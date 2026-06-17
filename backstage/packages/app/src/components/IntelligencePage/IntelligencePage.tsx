/**
 * IntelligencePage — Intelligence Hub
 *
 * Agentic Operations center. Links to AI Chat, Platform Graph,
 * and shows agent status and neural telemetry.
 */

import React from 'react';
import { makeStyles } from '@material-ui/core/styles';
import { Chip, LinearProgress } from '@material-ui/core';
import { Page, Content } from '@backstage/core-components';
import { Link as RouterLink } from 'react-router-dom';
import EmojiObjectsIcon from '@material-ui/icons/EmojiObjects';
import ChatIcon from '@material-ui/icons/Chat';
import ShareIcon from '@material-ui/icons/Share';
import SettingsIcon from '@material-ui/icons/Settings';
import SecurityIcon from '@material-ui/icons/Security';
import MemoryIcon from '@material-ui/icons/Memory';
import SpeedIcon from '@material-ui/icons/Speed';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import ArrowForwardIcon from '@material-ui/icons/ArrowForward';
import TimelineIcon from '@material-ui/icons/Timeline';
import VisibilityIcon from '@material-ui/icons/Visibility';
import BuildIcon from '@material-ui/icons/Build';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';

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

  /* Section labels */
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

  /* Tool cards grid */
  toolGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 24,
  },
  toolCard: {
    backgroundColor: '#ffffff',
    borderRadius: 16,
    padding: 28,
    boxShadow: '0 8px 32px rgba(0, 28, 57, 0.08)',
    transition: 'all 0.3s ease',
    display: 'flex',
    flexDirection: 'column' as const,
    gap: 16,
    '&:hover': {
      transform: 'translateY(-4px)',
      boxShadow: '0 16px 48px rgba(0, 28, 57, 0.14)',
    },
  },
  toolHeader: {
    display: 'flex',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
  },
  toolIconBox: {
    width: 48,
    height: 48,
    borderRadius: 12,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  toolName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '1.1rem',
    fontWeight: 800,
    color: '#171c21',
    letterSpacing: '-0.02em',
  },
  toolDescription: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    color: '#717783',
    lineHeight: 1.6,
    flex: 1,
  },
  toolMetrics: {
    display: 'flex',
    gap: 16,
    flexWrap: 'wrap' as const,
  },
  toolMetric: {
    display: 'flex',
    flexDirection: 'column' as const,
  },
  toolMetricValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 18,
    fontWeight: 800,
    color: '#171c21',
  },
  toolMetricLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
  },
  launchBtn: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 8,
    padding: '12px 24px',
    borderRadius: 10,
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 800,
    color: '#ffffff',
    textDecoration: 'none',
    border: 'none',
    cursor: 'pointer',
    transition: 'all 0.2s ease',
    alignSelf: 'flex-start',
    '&:hover': {
      transform: 'translateY(-1px)',
      boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
    },
  },
  disabledBtn: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 8,
    padding: '12px 24px',
    borderRadius: 10,
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 800,
    color: '#ffffff',
    border: 'none',
    cursor: 'default',
    opacity: 0.6,
    alignSelf: 'flex-start',
  },
  statusBadge: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 900,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
  },

  /* Bottom section */
  bottomGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 24,
  },

  /* Agent status rows */
  agentRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    padding: '16px 0',
    borderBottom: '1px solid #eef1f6',
    '&:last-child': { borderBottom: 'none' },
  },
  agentIconBox: {
    width: 40,
    height: 40,
    borderRadius: 10,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  agentInfo: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column' as const,
    gap: 6,
  },
  agentHeader: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  agentName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 700,
    color: '#171c21',
  },
  agentLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
  },
  progressBar: {
    height: 6,
    borderRadius: 3,
    backgroundColor: '#eaeef5',
  },
  progressBarColorPrimary: {
    borderRadius: 3,
  },

  /* Telemetry metrics */
  telemetryGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, 1fr)',
    gap: 16,
  },
  telemetryCard: {
    backgroundColor: '#f0f4fb',
    borderRadius: 12,
    padding: 20,
    display: 'flex',
    flexDirection: 'column' as const,
    gap: 8,
  },
  telemetryIcon: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  telemetryValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 24,
    fontWeight: 800,
    color: '#171c21',
    letterSpacing: '-0.02em',
  },
  telemetryLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
  },
  telemetryTrend: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 600,
    color: '#7FBA00',
    display: 'flex',
    alignItems: 'center',
    gap: 4,
  },
});

/* ------------------------------------------------------------------ */
/*  Data                                                               */
/* ------------------------------------------------------------------ */

const tools = [
  {
    name: 'AI Chat',
    description: 'Interact with autonomous agents to manage infrastructure, run diagnostics, and execute workflows.',
    to: '/ai-chat',
    Icon: ChatIcon,
    color: '#0078D4',
    status: 'Online',
    statusColor: '#7FBA00',
    hasLink: true,
    metrics: [
      { label: 'Sessions', value: '1.4k' },
      { label: 'Accuracy', value: '99.2%' },
    ],
  },
  {
    name: 'Platform Graph',
    description: 'Visualize service dependencies, ownership, and relationships across the entire software catalog.',
    to: '/catalog-graph',
    Icon: ShareIcon,
    color: '#00A4EF',
    status: 'Online',
    statusColor: '#7FBA00',
    hasLink: true,
    metrics: [
      { label: 'Nodes', value: '1.2k' },
      { label: 'Edges', value: '3.8k' },
    ],
  },
  {
    name: 'Orchestrator',
    description: 'Autonomous agent for pipeline orchestration, deployment coordination, and resource provisioning.',
    to: '',
    Icon: SettingsIcon,
    color: '#FFB900',
    status: 'Demo',
    statusColor: '#FFB900',
    hasLink: false,
    metrics: [
      { label: 'Pipelines', value: '48' },
      { label: 'Success', value: '97%' },
    ],
  },
  {
    name: 'Sentinel',
    description: 'Security-focused agent that monitors threats, enforces policies, and responds to vulnerability alerts.',
    to: '',
    Icon: SecurityIcon,
    color: '#F25022',
    status: 'Demo',
    statusColor: '#FFB900',
    hasLink: false,
    metrics: [
      { label: 'Threats', value: '0' },
      { label: 'Policies', value: '124' },
    ],
  },
  {
    name: 'Guardian',
    description: 'Security & compliance agent — scans for CVEs, secret leaks, and code scanning alerts via GitHub GHAS.',
    to: '',
    Icon: SecurityIcon,
    color: '#E91E63',
    status: 'Online',
    statusColor: '#7FBA00',
    hasLink: false,
    metrics: [
      { label: 'CVEs', value: '3' },
      { label: 'Secrets', value: '0' },
    ],
  },
  {
    name: 'Lighthouse',
    description: 'Observability & SRE agent — monitors deployments, environment health, and cluster metrics.',
    to: '',
    Icon: VisibilityIcon,
    color: '#00BCD4',
    status: 'Online',
    statusColor: '#7FBA00',
    hasLink: false,
    metrics: [
      { label: 'Deploys', value: '24' },
      { label: 'Uptime', value: '99.9%' },
    ],
  },
  {
    name: 'Forge',
    description: 'Infrastructure & cloud agent — manages repos, branches, releases, and Backstage catalog entities.',
    to: '',
    Icon: BuildIcon,
    color: '#795548',
    status: 'Online',
    statusColor: '#7FBA00',
    hasLink: false,
    metrics: [
      { label: 'Repos', value: '12' },
      { label: 'Releases', value: '8' },
    ],
  },
];

const agentStatuses = [
  { name: 'Compass', role: 'Planning & Stories', load: 72, color: '#0078D4', Icon: EmojiObjectsIcon },
  { name: 'Pipeline', role: 'CI/CD Diagnostics', load: 58, color: '#7FBA00', Icon: SettingsIcon },
  { name: 'Sentinel', role: 'Test & Coverage', load: 45, color: '#F25022', Icon: SecurityIcon },
  { name: 'Guardian', role: 'Security & Compliance', load: 38, color: '#E91E63', Icon: SecurityIcon },
  { name: 'Lighthouse', role: 'Observability & SRE', load: 52, color: '#00BCD4', Icon: VisibilityIcon },
  { name: 'Forge', role: 'Infrastructure & Cloud', load: 61, color: '#795548', Icon: BuildIcon },
  { name: 'Orchestrator', role: 'Resource Management', load: 83, color: '#FFB900', Icon: TimelineIcon },
];

const telemetryMetrics = [
  { label: 'Avg Latency', value: '14ms', trend: '-3ms', icon: SpeedIcon, color: '#0078D4' },
  { label: 'Throughput', value: '2.4k/s', trend: '+12%', icon: TrendingUpIcon, color: '#7FBA00' },
  { label: 'Model Accuracy', value: '99.9%', trend: '+0.1%', icon: CheckCircleIcon, color: '#00A4EF' },
  { label: 'Memory Usage', value: '4.2GB', trend: '-8%', icon: MemoryIcon, color: '#FFB900' },
];

/* ------------------------------------------------------------------ */
/*  Component                                                          */
/* ------------------------------------------------------------------ */

const IntelligencePage = () => {
  const classes = useStyles();

  return (
    <Page themeId="tool" className={classes.pageRoot}>
      <Content className={classes.content}>
        {/* Hero Banner */}
        <HeroBanner
          icon={<EmojiObjectsIcon style={{ fontSize: 24, color: '#0078D4' }} />}
          label="Intelligence Hub"
          title={
            <>
              Agentic <span style={{ color: '#0078D4' }}>Operations</span>
            </>
          }
          subtitle="Harness the power of autonomous agents to manage, secure, and scale your infrastructure."
          accentColor="#0078D4"
          stats={[
            { label: 'Agents', value: '7 Active', icon: <MemoryIcon style={{ fontSize: 20 }} />, color: '#0078D4' },
            { label: 'Nodes', value: '1.2k', icon: <ShareIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
            { label: 'Latency', value: '14ms', icon: <SpeedIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
            { label: 'Accuracy', value: '99.9%', icon: <CheckCircleIcon style={{ fontSize: 20 }} />, color: '#FFB900' },
          ]}
        />

        <div className={classes.space} />

        {/* Intelligence Tools */}
        <p className={classes.sectionLabel}>Intelligence Tools</p>
        <h2 className={classes.sectionTitle}>Agentic Capabilities</h2>
        <div className={classes.spaceSm} />

        <div className={classes.toolGrid}>
          {tools.map(tool => (
            <div key={tool.name} className={classes.toolCard}>
              <div className={classes.toolHeader}>
                <div
                  className={classes.toolIconBox}
                  style={{
                    backgroundColor: `${tool.color}1A`,
                  }}
                >
                  <tool.Icon style={{ fontSize: 24, color: tool.color }} />
                </div>
                <Chip
                  label={tool.status}
                  size="small"
                  className={classes.statusBadge}
                  style={{
                    backgroundColor: `${tool.statusColor}1A`,
                    color: tool.statusColor,
                  }}
                />
              </div>
              <h3 className={classes.toolName}>{tool.name}</h3>
              <p className={classes.toolDescription}>{tool.description}</p>
              <div className={classes.toolMetrics}>
                {tool.metrics.map(metric => (
                  <div key={metric.label} className={classes.toolMetric}>
                    <span className={classes.toolMetricValue}>{metric.value}</span>
                    <span className={classes.toolMetricLabel}>{metric.label}</span>
                  </div>
                ))}
              </div>
              {tool.hasLink ? (
                <RouterLink
                  to={tool.to}
                  className={classes.launchBtn}
                  style={{ backgroundColor: tool.color }}
                >
                  Launch Tool <ArrowForwardIcon style={{ fontSize: 16 }} />
                </RouterLink>
              ) : (
                <div
                  className={classes.disabledBtn}
                  style={{ backgroundColor: tool.color }}
                >
                  Coming Soon
                </div>
              )}
            </div>
          ))}
        </div>

        <div className={classes.space} />

        {/* Bottom: Agent Status + Neural Telemetry */}
        <div className={classes.bottomGrid}>
          <StyledCard title="Agent Status" subtitle="Active Agents">
            <div style={{ marginTop: 8 }}>
              {agentStatuses.map((agent, i) => (
                <div key={i} className={classes.agentRow}>
                  <div
                    className={classes.agentIconBox}
                    style={{ backgroundColor: `${agent.color}1A` }}
                  >
                    <agent.Icon style={{ fontSize: 20, color: agent.color }} />
                  </div>
                  <div className={classes.agentInfo}>
                    <div className={classes.agentHeader}>
                      <span className={classes.agentName}>{agent.name}</span>
                      <span className={classes.agentLabel}>{agent.load}% Load</span>
                    </div>
                    <LinearProgress
                      variant="determinate"
                      value={agent.load}
                      classes={{
                        root: classes.progressBar,
                        barColorPrimary: classes.progressBarColorPrimary,
                      }}
                      style={
                        {
                          '--bar-color': agent.color,
                        } as React.CSSProperties
                      }
                      // Use inline style on the bar via the bar1Determinate class
                    />
                    <span className={classes.agentLabel}>{agent.role}</span>
                  </div>
                </div>
              ))}
            </div>
          </StyledCard>

          <StyledCard title="Neural Telemetry" subtitle="Real-Time Metrics">
            <div className={classes.telemetryGrid} style={{ marginTop: 8 }}>
              {telemetryMetrics.map((metric, i) => (
                <div key={i} className={classes.telemetryCard}>
                  <div className={classes.telemetryIcon}>
                    <metric.icon style={{ fontSize: 18, color: metric.color }} />
                    <span className={classes.telemetryLabel}>{metric.label}</span>
                  </div>
                  <span className={classes.telemetryValue}>{metric.value}</span>
                  <span className={classes.telemetryTrend}>
                    <TrendingUpIcon style={{ fontSize: 14 }} />
                    {metric.trend}
                  </span>
                </div>
              ))}
            </div>
          </StyledCard>
        </div>

        <div className={classes.space} />
      </Content>
    </Page>
  );
};

export default IntelligencePage;
