import { makeStyles } from '@material-ui/core';
import { Page, Content } from '@backstage/core-components';
import { Link as RouterLink } from 'react-router-dom';
import DashboardIcon from '@material-ui/icons/Dashboard';
import CodeIcon from '@material-ui/icons/Code';
import FlashOnIcon from '@material-ui/icons/FlashOn';
import GroupIcon from '@material-ui/icons/Group';
import StarIcon from '@material-ui/icons/Star';
import GitHubIcon from '@material-ui/icons/GitHub';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import TerminalIcon from '@material-ui/icons/Computer';
import TimelineIcon from '@material-ui/icons/Timeline';
import BookIcon from '@material-ui/icons/Book';
import LaunchIcon from '@material-ui/icons/Launch';
import LayersIcon from '@material-ui/icons/Layers';
import HelpIcon from '@material-ui/icons/HelpOutline';
import ChevronRightIcon from '@material-ui/icons/ChevronRight';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const deploymentData = [
  { name: 'Mon', deployments: 12, success: 11 },
  { name: 'Tue', deployments: 19, success: 18 },
  { name: 'Wed', deployments: 15, success: 15 },
  { name: 'Thu', deployments: 22, success: 20 },
  { name: 'Fri', deployments: 30, success: 28 },
  { name: 'Sat', deployments: 8, success: 7 },
  { name: 'Sun', deployments: 5, success: 5 },
];

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
  // Stat Cards
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
    marginTop: 16,
    height: 6,
    width: '100%',
    backgroundColor: '#eaeef5',
    borderRadius: 3,
    overflow: 'hidden',
  },
  statBarFill: {
    height: '100%',
    width: '85%',
    borderRadius: 3,
  },
  statTrend: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 500,
    marginTop: 8,
  },
  trendUp: {
    color: '#7FBA00',
  },
  trendDown: {
    color: '#F25022',
  },
  // Charts section
  chartsGrid: {
    display: 'grid',
    gridTemplateColumns: '2fr 1fr',
    gap: 24,
  },
  chartContainer: {
    height: 300,
    width: '100%',
    marginTop: 16,
  },
  // System Health
  healthItem: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '12px 0',
    cursor: 'pointer',
    '&:hover $healthName': {
      color: '#0078d4',
    },
  },
  healthLeft: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
  },
  healthDot: {
    width: 8,
    height: 8,
    borderRadius: '50%',
  },
  healthInfo: {
    display: 'flex',
    flexDirection: 'column' as const,
  },
  healthName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 500,
    color: '#171c21',
    transition: 'color 0.2s',
  },
  healthStatus: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
  },
  healthUptime: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    color: '#717783',
    fontVariantNumeric: 'tabular-nums',
  },
  viewAllBtn: {
    width: '100%',
    padding: '8px 16px',
    marginTop: 16,
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 700,
    color: '#0078d4',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    backgroundColor: 'transparent',
    border: 'none',
    borderRadius: 8,
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    transition: 'background-color 0.2s',
    '&:hover': {
      backgroundColor: 'rgba(0, 120, 212, 0.05)',
    },
  },
  // Bottom grids
  bottomGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 24,
  },
  // Activity
  activityItem: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    padding: 12,
    borderRadius: 12,
    transition: 'background-color 0.2s',
    cursor: 'pointer',
    '&:hover': {
      backgroundColor: '#f0f4fb',
    },
  },
  activityIcon: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: '#e4e8ef',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  activityIconSvg: {
    fontSize: 20,
    color: '#404752',
  },
  activityInfo: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column' as const,
  },
  activityAction: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 500,
    color: '#171c21',
  },
  activityUser: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    color: '#717783',
  },
  activityTime: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    color: '#717783',
    fontVariantNumeric: 'tabular-nums',
    flexShrink: 0,
  },
  // Quick Links
  quickLinksGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 16,
    marginTop: 8,
  },
  quickLink: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    borderRadius: 16,
    backgroundColor: '#f0f4fb',
    textDecoration: 'none',
    transition: 'all 0.2s',
    '&:hover': {
      backgroundColor: '#e4e8ef',
    },
    '&:hover $quickLinkIcon': {
      transform: 'scale(1.1)',
    },
  },
  quickLinkIcon: {
    fontSize: 24,
    marginBottom: 12,
    transition: 'transform 0.2s',
  },
  quickLinkLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 600,
    color: '#171c21',
    letterSpacing: '-0.01em',
  },
});

const statCards = [
  { label: 'Active Deployments', value: '1,284', trend: 'up', trendValue: '+12.5%', color: '#00A4EF' },
  { label: 'Success Rate', value: '99.4%', trend: 'up', trendValue: '+0.2%', color: '#7FBA00' },
  { label: 'Avg. Lead Time', value: '42m', trend: 'down', trendValue: '-5.4%', color: '#FFB900' },
  { label: 'Open Incidents', value: '3', trend: 'down', trendValue: '-2', color: '#F25022' },
];

const environments = [
  { name: 'Production', status: 'Healthy', color: '#7FBA00', uptime: '99.99%' },
  { name: 'Staging', status: 'Healthy', color: '#7FBA00', uptime: '99.95%' },
  { name: 'Development', status: 'Degraded', color: '#FFB900', uptime: '98.40%' },
  { name: 'QA', status: 'Healthy', color: '#7FBA00', uptime: '99.90%' },
];

const activities = [
  { user: 'Paula Adoleta', action: 'Provisioned AKS Cluster', time: '2m ago', Icon: TerminalIcon },
  { user: 'System', action: 'Auto-scaled Azure VMSS', time: '15m ago', Icon: TimelineIcon },
  { user: 'John Doe', action: 'Merged PR #452', time: '1h ago', Icon: GitHubIcon },
  { user: 'GitHub Actions', action: 'Pipeline completed', time: '3h ago', Icon: CheckCircleIcon },
];

const quickLinks = [
  { label: 'Documentation', Icon: BookIcon, color: '#00A4EF', to: '/docs' },
  { label: 'Cloud Console', Icon: LaunchIcon, color: '#7FBA00', href: 'https://portal.azure.com/' },
  { label: 'Service Catalog', Icon: LayersIcon, color: '#FFB900', to: '/catalog' },
  { label: 'Support Desk', Icon: HelpIcon, color: '#F25022', to: '/ai-chat' },
];

const HomePage = () => {
  const classes = useStyles();

  return (
    <Page themeId="home" className={classes.pageRoot}>
      <Content className={classes.content}>
        {/* Hero Banner */}
        <HeroBanner
          icon={<DashboardIcon style={{ fontSize: 24, color: '#00A4EF' }} />}
          label="Platform Overview"
          title={<>Agentic DevOps <span style={{ color: '#00A4EF' }}>Command</span></>}
          subtitle="Your central Agentic DevOps hub for the entire SDLC. Monitor platform health, CI/CD pipelines, and key performance indicators across Azure, GitHub, and Azure DevOps."
          accentColor="#00A4EF"
          primaryAction={{ label: 'View All Metrics' }}
          secondaryAction={{ label: 'Quick Actions' }}
          stats={[
            { label: 'Active Projects', value: '14', icon: <CodeIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
            { label: 'Deployments', value: '124', icon: <FlashOnIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
            { label: 'Team Members', value: '42', icon: <GroupIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
            { label: 'Health Score', value: '94%', icon: <StarIcon style={{ fontSize: 20 }} />, color: '#FFB900' },
          ]}
        />

        <div className={classes.space} />

        {/* Stat Cards */}
        <div className={classes.statGrid}>
          {statCards.map(stat => (
            <StyledCard key={stat.label}>
              <div>
                <p className={classes.statLabel}>{stat.label}</p>
                <h4 className={classes.statValue}>{stat.value}</h4>
                <div className={classes.statBar}>
                  <div className={classes.statBarFill} style={{ backgroundColor: stat.color }} />
                </div>
                <p className={`${classes.statTrend} ${stat.trend === 'up' ? classes.trendUp : classes.trendDown}`}>
                  {stat.trend === 'up' ? '↑' : '↓'} {stat.trendValue} from last week
                </p>
              </div>
            </StyledCard>
          ))}
        </div>

        <div className={classes.space} />

        {/* Charts Section */}
        <div className={classes.chartsGrid}>
          <StyledCard title="Deployment Velocity" subtitle="Weekly Trend">
            <div className={classes.chartContainer}>
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={deploymentData}>
                  <defs>
                    <linearGradient id="colorDeploy" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#0078D4" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#0078D4" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e4e8ef" />
                  <XAxis
                    dataKey="name"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fontSize: 11, fill: '#717783' }}
                    dy={10}
                  />
                  <YAxis
                    axisLine={false}
                    tickLine={false}
                    tick={{ fontSize: 11, fill: '#717783' }}
                  />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#ffffff',
                      border: 'none',
                      borderRadius: 12,
                      boxShadow: '0 8px 32px rgba(0, 28, 57, 0.08)',
                    }}
                    itemStyle={{ fontSize: 12 }}
                  />
                  <Area
                    type="monotone"
                    dataKey="deployments"
                    stroke="#0078D4"
                    strokeWidth={3}
                    fillOpacity={1}
                    fill="url(#colorDeploy)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </StyledCard>

          <StyledCard title="System Health" subtitle="By Environment">
            <div style={{ marginTop: 16 }}>
              {environments.map(env => (
                <div key={env.name} className={classes.healthItem}>
                  <div className={classes.healthLeft}>
                    <div className={classes.healthDot} style={{ backgroundColor: env.color }} />
                    <div className={classes.healthInfo}>
                      <span className={classes.healthName}>{env.name}</span>
                      <span className={classes.healthStatus}>{env.status}</span>
                    </div>
                  </div>
                  <span className={classes.healthUptime}>{env.uptime}</span>
                </div>
              ))}
              <button className={classes.viewAllBtn}>
                View All Environments <ChevronRightIcon style={{ fontSize: 14 }} />
              </button>
            </div>
          </StyledCard>
        </div>

        <div className={classes.space} />

        {/* Activity + Quick Links */}
        <div className={classes.bottomGrid}>
          <StyledCard title="Recent Activity" subtitle="Platform Logs">
            <div style={{ marginTop: 16 }}>
              {activities.map((activity, i) => (
                <div key={i} className={classes.activityItem}>
                  <div className={classes.activityIcon}>
                    <activity.Icon className={classes.activityIconSvg} />
                  </div>
                  <div className={classes.activityInfo}>
                    <span className={classes.activityAction}>{activity.action}</span>
                    <span className={classes.activityUser}>{activity.user}</span>
                  </div>
                  <span className={classes.activityTime}>{activity.time}</span>
                </div>
              ))}
            </div>
          </StyledCard>

          <StyledCard title="Quick Links" subtitle="Resources">
            <div className={classes.quickLinksGrid}>
              {quickLinks.map(link => {
                const inner = (
                  <>
                    <link.Icon className={classes.quickLinkIcon} style={{ color: link.color }} />
                    <span className={classes.quickLinkLabel}>{link.label}</span>
                  </>
                );
                return link.to ? (
                  <RouterLink key={link.label} to={link.to} className={classes.quickLink}>
                    {inner}
                  </RouterLink>
                ) : (
                  <a key={link.label} href={link.href} target="_blank" rel="noopener noreferrer" className={classes.quickLink}>
                    {inner}
                  </a>
                );
              })}
            </div>
          </StyledCard>
        </div>

        <div className={classes.space} />
      </Content>
    </Page>
  );
};

export default HomePage;
