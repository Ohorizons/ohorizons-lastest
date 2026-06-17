/**
 * TechInsightsPage — Tech Health Scorecards
 *
 * Custom page replacing the native @backstage-community/plugin-tech-insights.
 * Fetches real catalog entities and evaluates them against quality checks.
 */

import { useState, useEffect } from 'react';
import {
  makeStyles,
  Typography,
  CircularProgress,
  Chip,
  LinearProgress,
  Tooltip,
  IconButton,
} from '@material-ui/core';
import ScoreIcon from '@material-ui/icons/Score';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import CancelIcon from '@material-ui/icons/Cancel';
import RefreshIcon from '@material-ui/icons/Refresh';
import DescriptionIcon from '@material-ui/icons/Description';
import BuildIcon from '@material-ui/icons/Build';
import SecurityIcon from '@material-ui/icons/Security';
import PeopleIcon from '@material-ui/icons/People';
import LabelIcon from '@material-ui/icons/Label';
import TimelineIcon from '@material-ui/icons/Timeline';
import MenuBookIcon from '@material-ui/icons/MenuBook';
import CodeIcon from '@material-ui/icons/Code';
import { Page, Content } from '@backstage/core-components';
import { configApiRef, useApi } from '@backstage/core-plugin-api';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';

// ── Types ────────────────────────────────────────────────────────────
interface CatalogEntity {
  metadata: {
    name: string;
    namespace?: string;
    description?: string;
    tags?: string[];
    annotations?: Record<string, string>;
  };
  spec?: {
    type?: string;
    lifecycle?: string;
    owner?: string;
    system?: string;
  };
  kind: string;
}

interface CheckResult {
  name: string;
  description: string;
  icon: React.ReactNode;
  passed: number;
  failed: number;
  total: number;
  pct: number;
  entities: { name: string; passed: boolean }[];
}

// ── Styles ───────────────────────────────────────────────────────────
const useStyles = makeStyles({
  pageRoot: {
    minHeight: '100%',
    backgroundColor: '#f7f9ff',
    position: 'relative',
  },
  content: { padding: '24px 32px' },
  space: { height: 48 },
  spaceSm: { height: 24 },
  overviewGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 24,
  },
  overviewValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '2rem',
    fontWeight: 800,
    color: '#171c21',
    letterSpacing: '-0.02em',
    lineHeight: 1.2,
  },
  overviewLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 700,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
    marginTop: 4,
  },
  overviewHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
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
  sectionIcon: { fontSize: 16 },
  checksGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, 1fr)',
    gap: 24,
  },
  checkHeader: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    marginBottom: 12,
  },
  checkIconBox: {
    width: 36,
    height: 36,
    borderRadius: 8,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkTitle: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 15,
    fontWeight: 700,
    color: '#171c21',
  },
  checkDesc: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    color: '#717783',
  },
  checkStats: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    marginBottom: 12,
  },
  checkPct: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 24,
    fontWeight: 900,
    letterSpacing: '-0.02em',
  },
  checkCount: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    color: '#717783',
    fontWeight: 600,
  },
  progressBar: {
    borderRadius: 4,
    height: 6,
    marginBottom: 12,
  },
  entityRow: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '6px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': { borderBottom: 'none' },
  },
  entityName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 600,
    color: '#404752',
  },
  passIcon: { fontSize: 16, color: '#7FBA00' },
  failIcon: { fontSize: 16, color: '#F25022' },
  entityScoreRow: {
    display: 'grid',
    gridTemplateColumns: '200px repeat(8, 1fr) 80px',
    alignItems: 'center',
    padding: '10px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': { borderBottom: 'none' },
  },
  entityScoreName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 700,
    color: '#171c21',
  },
  scoreCell: {
    display: 'flex',
    justifyContent: 'center',
  },
  overallScore: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 800,
    textAlign: 'center' as const,
  },
  headerRow: {
    display: 'grid',
    gridTemplateColumns: '200px repeat(8, 1fr) 80px',
    alignItems: 'center',
    padding: '8px 0',
    borderBottom: '2px solid rgba(0,0,0,0.08)',
  },
  headerCell: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 9,
    fontWeight: 900,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
    textAlign: 'center' as const,
  },
  centerBox: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    justifyContent: 'center',
    padding: '64px 0',
    gap: 16,
  },
});

// ── Helpers ──────────────────────────────────────────────────────────
function pctColor(pct: number): string {
  if (pct >= 80) return '#7FBA00';
  if (pct >= 60) return '#00A4EF';
  if (pct >= 40) return '#FFB900';
  return '#F25022';
}

function scoreGrade(pct: number): string {
  if (pct >= 90) return 'A';
  if (pct >= 80) return 'B';
  if (pct >= 60) return 'C';
  if (pct >= 40) return 'D';
  return 'F';
}

// ── Component ────────────────────────────────────────────────────────
const TechInsightsPage = () => {
  const classes = useStyles();
  const config = useApi(configApiRef);
  const baseUrl = config.getString('backend.baseUrl');

  const [checks, setChecks] = useState<CheckResult[]>([]);
  const [entities, setEntities] = useState<CatalogEntity[]>([]);
  const [loading, setLoading] = useState(true);

  const checkDefs = [
    {
      name: 'Has Description',
      description: 'Entity has a metadata description',
      icon: <DescriptionIcon style={{ color: '#0078D4', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.metadata.description && e.metadata.description.length > 0,
    },
    {
      name: 'Has Owner',
      description: 'Entity spec defines an owner',
      icon: <PeopleIcon style={{ color: '#7FBA00', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.spec?.owner,
    },
    {
      name: 'Has Tags',
      description: 'Entity has at least one tag',
      icon: <LabelIcon style={{ color: '#FFB900', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.metadata.tags && e.metadata.tags.length > 0,
    },
    {
      name: 'Has Lifecycle',
      description: 'Entity spec defines a lifecycle stage',
      icon: <TimelineIcon style={{ color: '#00A4EF', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.spec?.lifecycle,
    },
    {
      name: 'Has TechDocs',
      description: 'TechDocs annotation configured',
      icon: <MenuBookIcon style={{ color: '#9B59B6', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.metadata.annotations?.['backstage.io/techdocs-ref'],
    },
    {
      name: 'Has System',
      description: 'Entity belongs to a defined system',
      icon: <CodeIcon style={{ color: '#E74C3C', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.spec?.system,
    },
    {
      name: 'Has Type',
      description: 'Entity spec defines a component type',
      icon: <BuildIcon style={{ color: '#F39C12', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.spec?.type,
    },
    {
      name: 'Has Source',
      description: 'Source location annotation defined',
      icon: <SecurityIcon style={{ color: '#1ABC9C', fontSize: 18 }} />,
      test: (e: CatalogEntity) => !!e.metadata.annotations?.['backstage.io/source-location'],
    },
  ];

  const fetchData = async () => {
    setLoading(true);
    try {
      const res = await fetch(
        `${baseUrl}/api/catalog/entities?filter=kind=component`,
        { headers: { Accept: 'application/json' }, credentials: 'include' },
      );
      let items: CatalogEntity[] = [];
      if (res.ok) items = await res.json();
      setEntities(items);

      const results: CheckResult[] = checkDefs.map(def => {
        const er = items.map(e => ({ name: e.metadata.name, passed: def.test(e) }));
        const passed = er.filter(r => r.passed).length;
        const total = er.length;
        return {
          name: def.name,
          description: def.description,
          icon: def.icon,
          passed,
          failed: total - passed,
          total,
          pct: total > 0 ? Math.round((passed / total) * 100) : 0,
          entities: er,
        };
      });
      setChecks(results);
    } catch {
      // graceful empty
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  if (loading) {
    return (
      <Page themeId="tool">
        <Content>
          <div className={classes.centerBox}>
            <CircularProgress size={48} style={{ color: '#FFB900' }} />
            <Typography style={{ fontFamily: '"Inter", sans-serif', color: '#717783' }}>
              Evaluating tech health scorecards...
            </Typography>
          </div>
        </Content>
      </Page>
    );
  }

  const totalChecks = checks.length;
  const avgScore = totalChecks > 0 ? Math.round(checks.reduce((s, c) => s + c.pct, 0) / totalChecks) : 0;
  const passingChecks = checks.filter(c => c.pct >= 80).length;

  return (
    <Page themeId="tool">
      <Content>
        <div className={classes.pageRoot}>
          <div className={classes.content}>
            {/* Hero */}
            <HeroBanner
              icon={<ScoreIcon style={{ color: '#FFB900', fontSize: 28 }} />}
              label="Tech Insights"
              title={<>Tech Health<br />Scorecards</>}
              subtitle="Automated quality checks for catalog entities. Evaluate documentation, ownership, lifecycle, and engineering standards across your portfolio."
              accentColor="#FFB900"
              stats={[
                { label: 'Health Score', value: `${avgScore}%`, icon: <ScoreIcon style={{ fontSize: 20 }} />, color: pctColor(avgScore) },
                { label: 'Components', value: `${entities.length}`, icon: <CodeIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
                { label: 'Checks', value: `${totalChecks}`, icon: <BuildIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
                { label: 'Passing', value: `${passingChecks}/${totalChecks}`, icon: <CheckCircleIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
              ]}
              secondaryAction={{ label: 'Re-evaluate', onClick: fetchData }}
            />

            <div className={classes.space} />

            {/* Overview cards — top 4 checks */}
            <Typography className={classes.sectionLabel}>
              <ScoreIcon className={classes.sectionIcon} /> Overview
            </Typography>
            <div className={classes.overviewGrid}>
              {checks.slice(0, 4).map((c, i) => (
                <StyledCard key={i} title={c.name} subtitle={c.description}>
                  <div className={classes.overviewHeader}>
                    <div>
                      <div className={classes.overviewValue} style={{ color: pctColor(c.pct) }}>{c.pct}%</div>
                      <div className={classes.overviewLabel}>{c.passed} of {c.total} pass</div>
                    </div>
                  </div>
                  <LinearProgress
                    variant="determinate"
                    value={c.pct}
                    className={classes.progressBar}
                    style={{ backgroundColor: '#e8edf2', marginTop: 12 }}
                  />
                </StyledCard>
              ))}
            </div>

            <div className={classes.space} />

            {/* All checks detail */}
            <Typography className={classes.sectionLabel}>
              <BuildIcon className={classes.sectionIcon} /> All Checks
              <Tooltip title="Re-evaluate">
                <IconButton size="small" onClick={fetchData}><RefreshIcon style={{ fontSize: 14 }} /></IconButton>
              </Tooltip>
            </Typography>
            <div className={classes.checksGrid}>
              {checks.map((c, i) => (
                <StyledCard key={i}>
                  <div className={classes.checkHeader}>
                    <div className={classes.checkIconBox} style={{ backgroundColor: `${pctColor(c.pct)}15` }}>
                      {c.icon}
                    </div>
                    <div>
                      <div className={classes.checkTitle}>{c.name}</div>
                      <div className={classes.checkDesc}>{c.description}</div>
                    </div>
                  </div>
                  <div className={classes.checkStats}>
                    <span className={classes.checkPct} style={{ color: pctColor(c.pct) }}>{c.pct}%</span>
                    <span className={classes.checkCount}>
                      <span style={{ color: '#7FBA00' }}>{c.passed} passed</span>
                      {' / '}
                      <span style={{ color: '#F25022' }}>{c.failed} failed</span>
                    </span>
                  </div>
                  <LinearProgress
                    variant="determinate"
                    value={c.pct}
                    className={classes.progressBar}
                    style={{ backgroundColor: '#e8edf2' }}
                  />
                  {c.entities.map((ent, j) => (
                    <div key={j} className={classes.entityRow}>
                      <span className={classes.entityName}>{ent.name}</span>
                      {ent.passed ? <CheckCircleIcon className={classes.passIcon} /> : <CancelIcon className={classes.failIcon} />}
                    </div>
                  ))}
                </StyledCard>
              ))}
            </div>

            {entities.length > 0 && (
              <>
                <div className={classes.space} />

                {/* Entity scorecard matrix */}
                <Typography className={classes.sectionLabel}>
                  <CodeIcon className={classes.sectionIcon} /> Entity Scorecard
                </Typography>
                <StyledCard>
                  <div className={classes.headerRow}>
                    <span className={classes.headerCell} style={{ textAlign: 'left' }}>Component</span>
                    {checks.map((c, i) => (
                      <Tooltip key={i} title={c.name}>
                        <span className={classes.headerCell}>{c.name.replace('Has ', '').slice(0, 6)}</span>
                      </Tooltip>
                    ))}
                    <span className={classes.headerCell}>Grade</span>
                  </div>
                  {entities.map((ent, i) => {
                    const passCount = checks.filter(c => c.entities.find(e => e.name === ent.metadata.name)?.passed).length;
                    const entPct = Math.round((passCount / checks.length) * 100);
                    return (
                      <div key={i} className={classes.entityScoreRow}>
                        <span className={classes.entityScoreName}>{ent.metadata.name}</span>
                        {checks.map((c, j) => {
                          const r = c.entities.find(e => e.name === ent.metadata.name);
                          return (
                            <div key={j} className={classes.scoreCell}>
                              {r?.passed
                                ? <CheckCircleIcon style={{ fontSize: 16, color: '#7FBA00' }} />
                                : <CancelIcon style={{ fontSize: 16, color: '#F25022' }} />}
                            </div>
                          );
                        })}
                        <div className={classes.overallScore}>
                          <Chip
                            label={scoreGrade(entPct)}
                            size="small"
                            style={{
                              backgroundColor: `${pctColor(entPct)}22`,
                              color: pctColor(entPct),
                              fontWeight: 900,
                              fontSize: 11,
                              fontFamily: '"Inter", sans-serif',
                            }}
                          />
                        </div>
                      </div>
                    );
                  })}
                </StyledCard>
              </>
            )}

            <div className={classes.space} />
          </div>
        </div>
      </Content>
    </Page>
  );
};

export default TechInsightsPage;
