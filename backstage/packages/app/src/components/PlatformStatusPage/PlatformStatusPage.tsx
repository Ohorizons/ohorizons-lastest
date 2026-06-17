import { makeStyles } from '@material-ui/core/styles';
import SpeedIcon from '@material-ui/icons/Speed';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import ErrorIcon from '@material-ui/icons/Error';
import CloudIcon from '@material-ui/icons/Cloud';
import TimerIcon from '@material-ui/icons/Timer';
import StorageIcon from '@material-ui/icons/Storage';
import WarningIcon from '@material-ui/icons/Warning';
import FiberManualRecordIcon from '@material-ui/icons/FiberManualRecord';
import { Page, Content, StatusOK, StatusWarning } from '@backstage/core-components';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';

/* ------------------------------------------------------------------ */
/*  Data                                                               */
/* ------------------------------------------------------------------ */

const services = [
  { name: 'Backstage Portal', ns: 'backstage', status: 'healthy', ver: 'v1.48.0', rep: '2/2', latency: '38ms' },
  { name: 'ArgoCD', ns: 'argocd', status: 'healthy', ver: 'v2.13.0', rep: '3/3', latency: '22ms' },
  { name: 'Prometheus', ns: 'monitoring', status: 'healthy', ver: 'v2.51.0', rep: '2/2', latency: '15ms' },
  { name: 'Grafana', ns: 'monitoring', status: 'healthy', ver: 'v10.4.0', rep: '1/1', latency: '45ms' },
  { name: 'PostgreSQL', ns: 'databases', status: 'healthy', ver: '16.2', rep: '1/1', latency: '12ms' },
  { name: 'Ingress NGINX', ns: 'ingress', status: 'healthy', ver: 'v1.10.0', rep: '2/2', latency: '8ms' },
  { name: 'Cert Manager', ns: 'cert-manager', status: 'healthy', ver: 'v1.14.0', rep: '1/1', latency: '31ms' },
  { name: 'External Secrets', ns: 'external-secrets', status: 'warning', ver: 'v0.9.0', rep: '1/1', latency: '125ms' },
];

const argoApps = [
  { name: 'open-horizons-portal', sync: 'Synced', health: 'Healthy', revision: 'e75e3c7', updated: '2 min ago' },
  { name: 'monitoring-stack', sync: 'Synced', health: 'Healthy', revision: 'a3b91c2', updated: '12 min ago' },
  { name: 'argocd', sync: 'Synced', health: 'Healthy', revision: 'f91d4e0', updated: '1 hr ago' },
  { name: 'gatekeeper', sync: 'Synced', health: 'Healthy', revision: 'b7c3a12', updated: '3 hr ago' },
  { name: 'external-secrets', sync: 'OutOfSync', health: 'Degraded', revision: 'c43f138', updated: '6 hr ago' },
];

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

  /* Health metric cards grid */
  metricsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 24,
  },
  metricIconBox: {
    width: 44,
    height: 44,
    borderRadius: 12,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  metricValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '2rem',
    fontWeight: 800,
    letterSpacing: '-0.02em',
    lineHeight: 1.1,
  },
  metricLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 900,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.2em',
    marginTop: 8,
  },
  metricSub: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 500,
    color: '#717783',
    marginTop: 8,
  },
  statusBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 900,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    padding: '4px 12px',
    borderRadius: 6,
    marginTop: 12,
  },

  /* Tables */
  table: {
    width: '100%',
    borderCollapse: 'collapse' as const,
    fontFamily: '"Inter", sans-serif',
  },
  tableHead: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 900,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    padding: '12px 16px',
    borderBottom: '2px solid #eaeef5',
    textAlign: 'left' as const,
  },
  tableCell: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 500,
    color: '#404752',
    padding: '12px 16px',
    borderBottom: '1px solid #eaeef5',
  },
  tableCellBold: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 700,
    color: '#171c21',
    padding: '12px 16px',
    borderBottom: '1px solid #eaeef5',
  },
  tableRow: {
    transition: 'background-color 0.15s',
    '&:hover': {
      backgroundColor: '#f7f9ff',
    },
  },

  /* Namespace chip */
  nsChip: {
    display: 'inline-block',
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 600,
    color: '#404752',
    backgroundColor: '#eaeef5',
    padding: '2px 10px',
    borderRadius: 4,
    letterSpacing: '0.02em',
  },

  /* Sync / health badges */
  syncBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 700,
    padding: '3px 10px',
    borderRadius: 6,
  },
  syncBadgeSynced: {
    backgroundColor: '#E8F5E9',
    color: '#2E7D32',
  },
  syncBadgeOutOfSync: {
    backgroundColor: '#FFF3E0',
    color: '#E65100',
  },
  healthBadgeHealthy: {
    backgroundColor: '#E8F5E9',
    color: '#2E7D32',
  },
  healthBadgeDegraded: {
    backgroundColor: '#FFEBEE',
    color: '#C62828',
  },

  /* Revision mono */
  revision: {
    fontFamily: '"JetBrains Mono", "Fira Code", monospace',
    fontSize: 12,
    fontWeight: 600,
    color: '#717783',
    backgroundColor: '#f0f2f7',
    padding: '2px 8px',
    borderRadius: 4,
  },

  /* Updated text */
  updated: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 500,
    color: '#717783',
  },

  /* Status indicator inline */
  statusDot: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
  },

  /* Sections grid */
  sectionsGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 24,
  },

  /* Footer note */
  footerNote: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 500,
    color: '#717783',
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    marginTop: 16,
  },
});

/* ------------------------------------------------------------------ */
/*  Component                                                          */
/* ------------------------------------------------------------------ */

const PlatformStatusPage = () => {
  const classes = useStyles();
  const healthyCount = services.filter(s => s.status === 'healthy').length;
  const degradedCount = services.filter(s => s.status !== 'healthy').length;

  return (
    <Page themeId="tool">
      <Content className={classes.pageRoot}>
        <div className={classes.content}>
          {/* Hero Banner */}
          <HeroBanner
            icon={<SpeedIcon style={{ fontSize: 24, color: '#00A4EF' }} />}
            label="Platform Status Hub"
            title={<>System <span style={{ color: '#00A4EF' }}>Telemetry</span></>}
            subtitle="Real-time health telemetry across the orchestrator ecosystem. Monitor service availability, latency, and infrastructure health."
            accentColor="#00A4EF"
            stats={[
              {
                label: 'Global Uptime',
                value: '99.99%',
                icon: <CheckCircleIcon style={{ fontSize: 20 }} />,
                color: '#7FBA00',
              },
              {
                label: 'Active Nodes',
                value: String(services.length),
                icon: <StorageIcon style={{ fontSize: 20 }} />,
                color: '#00A4EF',
              },
              {
                label: 'Avg Latency',
                value: '42ms',
                icon: <TimerIcon style={{ fontSize: 20 }} />,
                color: '#FFB900',
              },
              {
                label: 'Incidents',
                value: '0',
                icon: <ErrorIcon style={{ fontSize: 20 }} />,
                color: '#F25022',
              },
            ]}
          />

          <div className={classes.space} />

          {/* Health Metric Cards */}
          <div className={classes.metricsGrid}>
            {/* Overall Health */}
            <StyledCard>
              <div
                className={classes.metricIconBox}
                style={{ backgroundColor: '#E8F5E9' }}
              >
                <CheckCircleIcon style={{ fontSize: 22, color: '#2E7D32' }} />
              </div>
              <div className={classes.metricValue} style={{ color: '#2E7D32' }}>
                {healthyCount}/{services.length}
              </div>
              <div className={classes.metricLabel}>Services Healthy</div>
              <div
                className={classes.statusBadge}
                style={{ backgroundColor: '#E8F5E9', color: '#2E7D32' }}
              >
                <FiberManualRecordIcon style={{ fontSize: 8 }} />
                HEALTHY
              </div>
              <div className={classes.metricSub}>
                All core services operational
              </div>
            </StyledCard>

            {/* Degraded Services */}
            <StyledCard>
              <div
                className={classes.metricIconBox}
                style={{ backgroundColor: degradedCount > 0 ? '#FFF3E0' : '#E8F5E9' }}
              >
                <WarningIcon style={{ fontSize: 22, color: degradedCount > 0 ? '#E65100' : '#2E7D32' }} />
              </div>
              <div className={classes.metricValue} style={{ color: degradedCount > 0 ? '#E65100' : '#2E7D32' }}>
                {degradedCount}
              </div>
              <div className={classes.metricLabel}>Degraded Services</div>
              <div
                className={classes.statusBadge}
                style={{
                  backgroundColor: degradedCount > 0 ? '#FFF3E0' : '#E8F5E9',
                  color: degradedCount > 0 ? '#E65100' : '#2E7D32',
                }}
              >
                <FiberManualRecordIcon style={{ fontSize: 8 }} />
                {degradedCount > 0 ? 'DEGRADED' : 'HEALTHY'}
              </div>
              <div className={classes.metricSub}>
                {degradedCount > 0 ? 'Requires attention' : 'No issues detected'}
              </div>
            </StyledCard>

            {/* Average Latency */}
            <StyledCard>
              <div
                className={classes.metricIconBox}
                style={{ backgroundColor: '#E3F2FD' }}
              >
                <TimerIcon style={{ fontSize: 22, color: '#00A4EF' }} />
              </div>
              <div className={classes.metricValue} style={{ color: '#00A4EF' }}>
                42ms
              </div>
              <div className={classes.metricLabel}>Average Latency</div>
              <div
                className={classes.statusBadge}
                style={{ backgroundColor: '#E3F2FD', color: '#1565C0' }}
              >
                <FiberManualRecordIcon style={{ fontSize: 8 }} />
                HEALTHY
              </div>
              <div className={classes.metricSub}>
                P95: 125ms across all endpoints
              </div>
            </StyledCard>

            {/* Uptime */}
            <StyledCard>
              <div
                className={classes.metricIconBox}
                style={{ backgroundColor: '#F1F8E9' }}
              >
                <CloudIcon style={{ fontSize: 22, color: '#7FBA00' }} />
              </div>
              <div className={classes.metricValue} style={{ color: '#7FBA00' }}>
                99.99%
              </div>
              <div className={classes.metricLabel}>Uptime (30d)</div>
              <div
                className={classes.statusBadge}
                style={{ backgroundColor: '#F1F8E9', color: '#33691E' }}
              >
                <FiberManualRecordIcon style={{ fontSize: 8 }} />
                HEALTHY
              </div>
              <div className={classes.metricSub}>
                4.3s total downtime this month
              </div>
            </StyledCard>
          </div>

          <div className={classes.space} />

          {/* Platform Services Table + ArgoCD Applications */}
          <div className={classes.sectionsGrid}>
            {/* Platform Services */}
            <StyledCard title="Platform Services" subtitle="Service health across namespaces">
              <table className={classes.table}>
                <thead>
                  <tr>
                    <th className={classes.tableHead}>Service</th>
                    <th className={classes.tableHead}>Namespace</th>
                    <th className={classes.tableHead}>Status</th>
                    <th className={classes.tableHead}>Version</th>
                    <th className={classes.tableHead}>Replicas</th>
                    <th className={classes.tableHead}>Latency</th>
                  </tr>
                </thead>
                <tbody>
                  {services.map(s => (
                    <tr key={s.name} className={classes.tableRow}>
                      <td className={classes.tableCellBold}>{s.name}</td>
                      <td className={classes.tableCell}>
                        <span className={classes.nsChip}>{s.ns}</span>
                      </td>
                      <td className={classes.tableCell}>
                        <span className={classes.statusDot}>
                          {s.status === 'healthy' ? (
                            <StatusOK />
                          ) : (
                            <StatusWarning />
                          )}
                          {s.status}
                        </span>
                      </td>
                      <td className={classes.tableCell}>{s.ver}</td>
                      <td className={classes.tableCell}>{s.rep}</td>
                      <td className={classes.tableCell}>{s.latency}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className={classes.footerNote}>
                <CheckCircleIcon style={{ fontSize: 14, color: '#7FBA00' }} />
                Last checked: 30 seconds ago
              </div>
            </StyledCard>

            {/* ArgoCD Applications */}
            <StyledCard title="ArgoCD Applications" subtitle="GitOps sync status">
              <table className={classes.table}>
                <thead>
                  <tr>
                    <th className={classes.tableHead}>Application</th>
                    <th className={classes.tableHead}>Sync</th>
                    <th className={classes.tableHead}>Health</th>
                    <th className={classes.tableHead}>Revision</th>
                    <th className={classes.tableHead}>Updated</th>
                  </tr>
                </thead>
                <tbody>
                  {argoApps.map(a => (
                    <tr key={a.name} className={classes.tableRow}>
                      <td className={classes.tableCellBold}>{a.name}</td>
                      <td className={classes.tableCell}>
                        <span
                          className={`${classes.syncBadge} ${
                            a.sync === 'Synced' ? classes.syncBadgeSynced : classes.syncBadgeOutOfSync
                          }`}
                        >
                          {a.sync === 'Synced' ? (
                            <CheckCircleIcon style={{ fontSize: 12 }} />
                          ) : (
                            <WarningIcon style={{ fontSize: 12 }} />
                          )}
                          {a.sync}
                        </span>
                      </td>
                      <td className={classes.tableCell}>
                        <span
                          className={`${classes.syncBadge} ${
                            a.health === 'Healthy' ? classes.healthBadgeHealthy : classes.healthBadgeDegraded
                          }`}
                        >
                          {a.health === 'Healthy' ? (
                            <CheckCircleIcon style={{ fontSize: 12 }} />
                          ) : (
                            <ErrorIcon style={{ fontSize: 12 }} />
                          )}
                          {a.health}
                        </span>
                      </td>
                      <td className={classes.tableCell}>
                        <span className={classes.revision}>{a.revision}</span>
                      </td>
                      <td className={classes.tableCell}>
                        <span className={classes.updated}>{a.updated}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className={classes.footerNote}>
                <CheckCircleIcon style={{ fontSize: 14, color: '#7FBA00' }} />
                ArgoCD sync status is live
              </div>
            </StyledCard>
          </div>
        </div>
      </Content>
    </Page>
  );
};

export default PlatformStatusPage;
