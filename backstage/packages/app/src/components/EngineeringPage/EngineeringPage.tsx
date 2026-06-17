/**
 * EngineeringPage — Engineering Hub
 *
 * Central command for all engineering operations.
 * Links to engineering tools: Tech Insights, Cost Insights,
 * Copilot Analytics, Lighthouse, and Validation.
 */

import { makeStyles } from '@material-ui/core/styles';
import { Chip } from '@material-ui/core';
import { Page, Content } from '@backstage/core-components';
import { Link as RouterLink } from 'react-router-dom';
import BuildIcon from '@material-ui/icons/Build';
import ScoreIcon from '@material-ui/icons/Score';
import AttachMoneyIcon from '@material-ui/icons/AttachMoney';
import NewReleasesIcon from '@material-ui/icons/NewReleases';
import VerifiedUserIcon from '@material-ui/icons/VerifiedUser';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import AccessTimeIcon from '@material-ui/icons/AccessTime';
import ArrowForwardIcon from '@material-ui/icons/ArrowForward';
import FiberManualRecordIcon from '@material-ui/icons/FiberManualRecord';
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
    gridTemplateColumns: 'repeat(3, 1fr)',
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

  /* Deployment rows */
  deployRow: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '14px 0',
    borderBottom: '1px solid #eef1f6',
    '&:last-child': { borderBottom: 'none' },
  },
  deployLeft: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
  },
  deployDot: {
    width: 8,
    height: 8,
    borderRadius: '50%',
  },
  deployInfo: {
    display: 'flex',
    flexDirection: 'column' as const,
  },
  deployName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 600,
    color: '#171c21',
  },
  deployMeta: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    color: '#717783',
  },
  deployTime: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    color: '#717783',
    fontVariantNumeric: 'tabular-nums',
  },

  /* Pipeline rows */
  pipelineRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    padding: '14px 0',
    borderBottom: '1px solid #eef1f6',
    '&:last-child': { borderBottom: 'none' },
  },
  pipelineInfo: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column' as const,
    gap: 6,
  },
  pipelineName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 600,
    color: '#171c21',
  },
  pipelineBar: {
    height: 6,
    width: '100%',
    backgroundColor: '#eaeef5',
    borderRadius: 3,
    overflow: 'hidden',
  },
  pipelineBarFill: {
    height: '100%',
    borderRadius: 3,
    transition: 'width 0.5s ease',
  },
  pipelineStage: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
  },
});

/* ------------------------------------------------------------------ */
/*  Data                                                               */
/* ------------------------------------------------------------------ */

const tools = [
  {
    name: 'Tech Insights',
    description: 'Track tech debt, compliance scorecards, and engineering standards across all services.',
    to: '/tech-insights',
    Icon: ScoreIcon,
    color: '#00A4EF',
    status: 'Active',
    statusColor: '#7FBA00',
    metrics: [
      { label: 'Score', value: '87%' },
      { label: 'Checks', value: '1.2k' },
    ],
  },
  {
    name: 'Cost Insights',
    description: 'Monitor cloud spending, identify cost anomalies, and optimize resource allocation.',
    to: '/cost-insights',
    Icon: AttachMoneyIcon,
    color: '#7FBA00',
    status: 'Active',
    statusColor: '#7FBA00',
    metrics: [
      { label: 'Savings', value: '$42k' },
      { label: 'Trend', value: '-12%' },
    ],
  },
  {
    name: 'Copilot Analytics',
    description: 'Measure developer productivity, AI-assisted code acceptance rates, and team velocity.',
    to: '/copilot',
    Icon: NewReleasesIcon,
    color: '#FFB900',
    status: 'Active',
    statusColor: '#7FBA00',
    metrics: [
      { label: 'Acceptance', value: '34%' },
      { label: 'Users', value: '28' },
    ],
  },
  {
    name: 'Validation',
    description: 'Enforce entity schema validation, check ownership rules, and verify catalog integrity.',
    to: '/entity-validation',
    Icon: VerifiedUserIcon,
    color: '#0078D4',
    status: 'Active',
    statusColor: '#7FBA00',
    metrics: [
      { label: 'Pass Rate', value: '98%' },
      { label: 'Entities', value: '142' },
    ],
  },
];

const recentDeployments = [
  { name: 'ohorizons-demo v7.1.0', env: 'Production', status: 'Success', color: '#7FBA00', time: '12m ago' },
  { name: 'todo-app-full-stack v1.2.0', env: 'Staging', status: 'Success', color: '#7FBA00', time: '34m ago' },
  { name: 'backstage v1.38.0', env: 'Production', status: 'Success', color: '#7FBA00', time: '1h ago' },
  { name: 'golden-paths v0.9.4', env: 'Development', status: 'Failed', color: '#F25022', time: '2h ago' },
  { name: 'agentic-workflows v1.0.0', env: 'Staging', status: 'Success', color: '#7FBA00', time: '3h ago' },
];

const activePipelines = [
  { name: 'CI/CD - ohorizons-demo', stage: 'Build', progress: 65, color: '#00A4EF' },
  { name: 'CI/CD - todo-app-full-stack', stage: 'Test', progress: 40, color: '#7FBA00' },
  { name: 'Infrastructure - Terraform', stage: 'Plan', progress: 80, color: '#FFB900' },
  { name: 'Security Scan - Weekly', stage: 'Scanning', progress: 25, color: '#F25022' },
];

/* ------------------------------------------------------------------ */
/*  Component                                                          */
/* ------------------------------------------------------------------ */

const EngineeringPage = () => {
  const classes = useStyles();

  return (
    <Page themeId="tool" className={classes.pageRoot}>
      <Content className={classes.content}>
        {/* Hero Banner */}
        <HeroBanner
          icon={<BuildIcon style={{ fontSize: 24, color: '#00A4EF' }} />}
          label="Engineering Hub"
          title={
            <>
              Build with <span style={{ color: '#00A4EF' }}>Precision</span>
            </>
          }
          subtitle="The central command for all engineering operations. Monitor performance, optimize costs, and enforce governance."
          accentColor="#00A4EF"
          stats={[
            { label: 'Services', value: '142', icon: <BuildIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
            { label: 'Uptime', value: '99.9%', icon: <CheckCircleIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
            { label: 'Efficiency', value: '92.4%', icon: <TrendingUpIcon style={{ fontSize: 20 }} />, color: '#FFB900' },
            { label: 'Security', value: 'Elite', icon: <VerifiedUserIcon style={{ fontSize: 20 }} />, color: '#0078D4' },
          ]}
        />

        <div className={classes.space} />

        {/* Engineering Tools */}
        <p className={classes.sectionLabel}>Engineering Tools</p>
        <h2 className={classes.sectionTitle}>Platform Toolchain</h2>
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
              <RouterLink
                to={tool.to}
                className={classes.launchBtn}
                style={{ backgroundColor: tool.color }}
              >
                Launch Tool <ArrowForwardIcon style={{ fontSize: 16 }} />
              </RouterLink>
            </div>
          ))}
        </div>

        <div className={classes.space} />

        {/* Bottom: Recent Deployments + Active Pipelines */}
        <div className={classes.bottomGrid}>
          <StyledCard title="Recent Deployments" subtitle="Deployment History">
            <div style={{ marginTop: 8 }}>
              {recentDeployments.map((deploy, i) => (
                <div key={i} className={classes.deployRow}>
                  <div className={classes.deployLeft}>
                    <div className={classes.deployDot} style={{ backgroundColor: deploy.color }} />
                    <div className={classes.deployInfo}>
                      <span className={classes.deployName}>{deploy.name}</span>
                      <span className={classes.deployMeta}>
                        {deploy.env} &middot; {deploy.status}
                      </span>
                    </div>
                  </div>
                  <span className={classes.deployTime}>
                    <AccessTimeIcon style={{ fontSize: 12, marginRight: 4, verticalAlign: 'middle' }} />
                    {deploy.time}
                  </span>
                </div>
              ))}
            </div>
          </StyledCard>

          <StyledCard title="Active Pipelines" subtitle="In Progress">
            <div style={{ marginTop: 8 }}>
              {activePipelines.map((pipeline, i) => (
                <div key={i} className={classes.pipelineRow}>
                  <FiberManualRecordIcon style={{ fontSize: 10, color: pipeline.color }} />
                  <div className={classes.pipelineInfo}>
                    <span className={classes.pipelineName}>{pipeline.name}</span>
                    <div className={classes.pipelineBar}>
                      <div
                        className={classes.pipelineBarFill}
                        style={{
                          width: `${pipeline.progress}%`,
                          backgroundColor: pipeline.color,
                        }}
                      />
                    </div>
                    <span className={classes.pipelineStage}>
                      {pipeline.stage} &middot; {pipeline.progress}%
                    </span>
                  </div>
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

export default EngineeringPage;
