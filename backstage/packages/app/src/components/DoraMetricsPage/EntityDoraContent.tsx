/**
 * EntityDoraContent — DORA Metrics tab for entity pages
 *
 * Compact version of the DORA dashboard scoped to the entity's repository.
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
import SpeedIcon from '@material-ui/icons/Speed';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import BuildIcon from '@material-ui/icons/Build';
import RestoreIcon from '@material-ui/icons/Restore';
import { configApiRef, useApi } from '@backstage/core-plugin-api';
import { useEntity } from '@backstage/plugin-catalog-react';

const useStyles = makeStyles(theme => ({
  metricCard: { borderRadius: 12, height: '100%' },
  metricValue: { fontSize: '2rem', fontWeight: 700, lineHeight: 1.2 },
  metricLabel: { fontSize: '0.85rem', color: theme.palette.text.secondary, marginTop: theme.spacing(0.5) },
  classificationChip: { fontSize: 10, height: 22, fontWeight: 700, marginTop: theme.spacing(1) },
}));

type Classification = 'elite' | 'high' | 'medium' | 'low';

const classColors: Record<Classification, { bg: string; fg: string }> = {
  elite: { bg: '#E8F5E9', fg: '#2E7D32' },
  high: { bg: '#E3F2FD', fg: '#1565C0' },
  medium: { bg: '#FFF8E1', fg: '#F57F17' },
  low: { bg: '#FFEBEE', fg: '#C62828' },
};

function classifyDF(perDay: number): Classification {
  if (perDay >= 1) return 'elite';
  if (perDay >= 1 / 7) return 'high';
  if (perDay >= 1 / 30) return 'medium';
  return 'low';
}

function classifyLower(value: number, thresholds: { elite: number; high: number; medium: number }): Classification {
  if (value <= thresholds.elite) return 'elite';
  if (value <= thresholds.high) return 'high';
  if (value <= thresholds.medium) return 'medium';
  return 'low';
}

function median(arr: number[]): number {
  if (arr.length === 0) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 !== 0 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

function formatFreq(perDay: number): string {
  if (perDay >= 1) return `${perDay.toFixed(1)}/day`;
  if (perDay >= 1 / 7) return `${(perDay * 7).toFixed(1)}/week`;
  return `${(perDay * 30).toFixed(1)}/month`;
}

function formatHours(hours: number): string {
  if (hours < 1) return `${Math.round(hours * 60)}m`;
  if (hours < 24) return `${hours.toFixed(1)}h`;
  return `${(hours / 24).toFixed(1)}d`;
}

export const EntityDoraContent = () => {
  const classes = useStyles();
  const config = useApi(configApiRef);
  const { entity } = useEntity();
  const [loading, setLoading] = useState(true);
  const [metrics, setMetrics] = useState<{
    df: { perDay: number; count: number; cls: Classification };
    lt: { hours: number; cls: Classification };
    cfr: { pct: number; cls: Classification };
    mttr: { hours: number; cls: Classification };
  } | null>(null);

  const slug = entity.metadata.annotations?.['github.com/project-slug'] || 'Ohorizons/ohorizons-demo';
  const [owner, repo] = slug.includes('/') ? slug.split('/') : ['Ohorizons', slug];

  useEffect(() => {
    const fetchDora = async () => {
      try {
        const baseUrl = config.getString('backend.baseUrl');
        const headers: Record<string, string> = { Accept: 'application/vnd.github+json' };
        const since = new Date();
        since.setDate(since.getDate() - 30);
        const sinceStr = since.toISOString().split('T')[0];

        const runsRes = await fetch(
          `${baseUrl}/api/proxy/github-api/repos/${owner}/${repo}/actions/runs?per_page=100&created=%3E${sinceStr}`,
          { headers, credentials: 'include' },
        );
        if (!runsRes.ok) { setLoading(false); return; }
        const runsData = await runsRes.json();
        const allRuns = runsData.workflow_runs || [];
        const deployRuns = allRuns.filter((r: any) => {
          const name = (r.name || '').toLowerCase();
          return name.includes('deploy') || name.includes('cd') || name.includes('release');
        });
        const runs = deployRuns.length > 0 ? deployRuns : allRuns.filter((r: any) => r.status === 'completed');

        const dfPerDay = runs.length / 30;
        const completed = runs.filter((r: any) => r.status === 'completed');
        const failed = completed.filter((r: any) => r.conclusion === 'failure');
        const cfrPct = completed.length > 0 ? (failed.length / completed.length) * 100 : 0;

        // Lead time
        const prRes = await fetch(
          `${baseUrl}/api/proxy/github-api/repos/${owner}/${repo}/pulls?state=closed&sort=updated&direction=desc&per_page=30`,
          { headers, credentials: 'include' },
        );
        let leadTimes: number[] = [];
        if (prRes.ok) {
          const prs = await prRes.json();
          const merged = prs.filter((pr: any) => pr.merged_at && new Date(pr.merged_at) >= since);
          const successes = completed.filter((r: any) => r.conclusion === 'success')
            .sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
          for (const pr of merged) {
            const mt = new Date(pr.merged_at).getTime();
            const next = successes.find((r: any) => new Date(r.created_at).getTime() >= mt);
            if (next) {
              const h = (new Date(next.created_at).getTime() - mt) / 3600000;
              if (h >= 0 && h < 720) leadTimes.push(h);
            }
          }
        }

        // MTTR
        const sorted = completed.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
        const recoveries: number[] = [];
        for (let i = 0; i < sorted.length; i++) {
          if (sorted[i].conclusion === 'failure') {
            for (let j = i + 1; j < sorted.length; j++) {
              if (sorted[j].conclusion === 'success') {
                recoveries.push((new Date(sorted[j].created_at).getTime() - new Date(sorted[i].created_at).getTime()) / 3600000);
                break;
              }
            }
          }
        }

        const ltHours = median(leadTimes);
        const mttrHours = median(recoveries);

        setMetrics({
          df: { perDay: dfPerDay, count: runs.length, cls: classifyDF(dfPerDay) },
          lt: { hours: ltHours, cls: classifyLower(ltHours, { elite: 24, high: 168, medium: 720 }) },
          cfr: { pct: cfrPct, cls: classifyLower(cfrPct, { elite: 5, high: 10, medium: 15 }) },
          mttr: { hours: mttrHours, cls: classifyLower(mttrHours, { elite: 1, high: 24, medium: 168 }) },
        });
      } catch {
        // Fail silently
      } finally {
        setLoading(false);
      }
    };
    fetchDora();
  }, [config, owner, repo]);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" py={4}>
        <CircularProgress />
      </Box>
    );
  }

  if (!metrics) {
    return (
      <Box py={4} textAlign="center">
        <Typography color="textSecondary">No DORA data available for this component.</Typography>
      </Box>
    );
  }

  const items = [
    { label: 'Deploy Frequency', value: formatFreq(metrics.df.perDay), cls: metrics.df.cls, icon: <SpeedIcon style={{ fontSize: 28, opacity: 0.2 }} />, sub: `${metrics.df.count} deploys in 30d` },
    { label: 'Lead Time', value: formatHours(metrics.lt.hours), cls: metrics.lt.cls, icon: <TrendingUpIcon style={{ fontSize: 28, opacity: 0.2 }} />, sub: 'PR merge to deploy' },
    { label: 'Failure Rate', value: `${metrics.cfr.pct.toFixed(1)}%`, cls: metrics.cfr.cls, icon: <BuildIcon style={{ fontSize: 28, opacity: 0.2 }} />, sub: 'Failed deployments' },
    { label: 'MTTR', value: metrics.mttr.hours > 0 ? formatHours(metrics.mttr.hours) : 'N/A', cls: metrics.mttr.hours > 0 ? metrics.mttr.cls : 'low' as Classification, icon: <RestoreIcon style={{ fontSize: 28, opacity: 0.2 }} />, sub: 'Failure to recovery' },
  ];

  return (
    <Grid container spacing={3} style={{ padding: 16 }}>
      {items.map(item => (
        <Grid item xs={12} sm={6} md={3} key={item.label}>
          <Card className={classes.metricCard} variant="outlined">
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="flex-start">
                <div>
                  <Typography className={classes.metricValue} style={{ color: classColors[item.cls].fg }}>
                    {item.value}
                  </Typography>
                  <Typography className={classes.metricLabel}>{item.label}</Typography>
                  <Chip
                    label={item.cls.toUpperCase()}
                    size="small"
                    className={classes.classificationChip}
                    style={{ background: classColors[item.cls].bg, color: classColors[item.cls].fg }}
                  />
                </div>
                {item.icon}
              </Box>
              <Typography variant="caption" color="textSecondary">{item.sub}</Typography>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
};
