/**
 * EntityCodeQualityContent — Code Quality tab for entity pages
 *
 * Shows CodeQL quality alerts (maintainability, reliability, correctness)
 * and Copilot Autofix availability for the entity's repository.
 */

import { useState, useEffect } from 'react';
import {
  Typography,
  Grid,
  Card,
  CardContent,
  Chip,
  Box,
  CircularProgress,
} from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import BugReportIcon from '@material-ui/icons/BugReport';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import WarningIcon from '@material-ui/icons/Warning';
import { configApiRef, useApi } from '@backstage/core-plugin-api';
import { useEntity } from '@backstage/plugin-catalog-react';

const useStyles = makeStyles(theme => ({
  metricCard: { borderRadius: 12, height: '100%' },
  metricValue: { fontSize: '2rem', fontWeight: 700, lineHeight: 1.2 },
  metricLabel: { fontSize: '0.85rem', color: theme.palette.text.secondary, marginTop: theme.spacing(0.5) },
  iconBox: {
    width: 44, height: 44, borderRadius: 10,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    marginBottom: theme.spacing(1),
  },
}));

export const EntityCodeQualityContent = () => {
  const classes = useStyles();
  const config = useApi(configApiRef);
  const { entity } = useEntity();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<{
    total: number; maintainability: number; reliability: number;
    correctness: number; autofix: number; securityTotal: number;
  } | null>(null);

  const slug = entity.metadata.annotations?.['github.com/project-slug'] || 'Ohorizons/ohorizons-demo';
  const [owner, repo] = slug.includes('/') ? slug.split('/') : ['Ohorizons', slug];

  useEffect(() => {
    const fetchQuality = async () => {
      try {
        const baseUrl = config.getString('backend.baseUrl');
        const headers: Record<string, string> = { Accept: 'application/vnd.github+json' };

        const res = await fetch(
          `${baseUrl}/api/proxy/github-api/repos/${owner}/${repo}/code-scanning/alerts?state=open&per_page=100`,
          { headers, credentials: 'include' },
        );
        if (!res.ok) { setLoading(false); return; }
        const alerts = await res.json();

        const quality = alerts.filter((a: any) =>
          !a.rule?.security_severity_level &&
          a.rule?.tags?.some((t: string) => ['quality', 'maintainability', 'reliability', 'correctness', 'performance', 'style'].includes(t))
        );
        const security = alerts.filter((a: any) => a.rule?.security_severity_level);

        setData({
          total: quality.length,
          maintainability: quality.filter((a: any) => a.rule?.tags?.includes('maintainability')).length,
          reliability: quality.filter((a: any) => a.rule?.tags?.includes('reliability')).length,
          correctness: quality.filter((a: any) => a.rule?.tags?.includes('correctness')).length,
          autofix: alerts.filter((a: any) => a.most_recent_instance?.fix_available).length,
          securityTotal: security.length,
        });
      } catch {
        // Fail silently
      } finally {
        setLoading(false);
      }
    };
    fetchQuality();
  }, [config, owner, repo]);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" py={4}>
        <CircularProgress />
      </Box>
    );
  }

  if (!data) {
    return (
      <Box py={4} textAlign="center">
        <Typography color="textSecondary">Code scanning not enabled for this component.</Typography>
      </Box>
    );
  }

  const items = [
    { label: 'Quality Alerts', value: data.total, icon: <BugReportIcon />, color: data.total > 0 ? '#F57F17' : '#2E7D32', bg: data.total > 0 ? '#FFF8E1' : '#E8F5E9' },
    { label: 'Maintainability', value: data.maintainability, icon: <BugReportIcon />, color: data.maintainability > 0 ? '#1565C0' : '#2E7D32', bg: data.maintainability > 0 ? '#E3F2FD' : '#E8F5E9' },
    { label: 'Reliability', value: data.reliability, icon: <WarningIcon />, color: data.reliability > 0 ? '#E65100' : '#2E7D32', bg: data.reliability > 0 ? '#FFF3E0' : '#E8F5E9' },
    { label: 'Security Alerts', value: data.securityTotal, icon: <WarningIcon />, color: data.securityTotal > 0 ? '#C62828' : '#2E7D32', bg: data.securityTotal > 0 ? '#FFEBEE' : '#E8F5E9' },
  ];

  return (
    <Box p={2}>
      <Grid container spacing={3}>
        {items.map(item => (
          <Grid item xs={12} sm={6} md={3} key={item.label}>
            <Card className={classes.metricCard} variant="outlined">
              <CardContent>
                <div className={classes.iconBox} style={{ background: item.bg }}>
                  {<item.icon.type style={{ color: item.color }} />}
                </div>
                <Typography className={classes.metricValue}>{item.value}</Typography>
                <Typography className={classes.metricLabel}>{item.label}</Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {data.autofix > 0 && (
        <Box mt={2} p={2} bgcolor="#E8F5E9" borderRadius={8} border="1px solid #A5D6A7">
          <Box display="flex" alignItems="center" style={{ gap: 8 }}>
            <CheckCircleIcon style={{ color: '#2E7D32', fontSize: 18 }} />
            <Typography variant="body2" style={{ fontWeight: 500 }}>
              {data.autofix} alert{data.autofix !== 1 ? 's' : ''} with Copilot Autofix available
            </Typography>
            <Chip label="AUTOFIX" size="small" style={{ fontSize: 9, height: 18, fontWeight: 700, background: '#2E7D32', color: '#fff' }} />
          </Box>
        </Box>
      )}
    </Box>
  );
};
