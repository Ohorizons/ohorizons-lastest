/**
 * Tech Radar — Organization Technology Radar
 *
 * Visual radar showing technology adoption status across the organization.
 * Static data derived from golden-paths templates and platform stack.
 */

import { useState } from 'react';
import {
  Typography,
  Grid,
  Chip,
  ButtonGroup,
  Button,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
} from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import TrackChangesIcon from '@material-ui/icons/TrackChanges';
import CategoryIcon from '@material-ui/icons/Category';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import FlashOnIcon from '@material-ui/icons/FlashOn';
import ExploreIcon from '@material-ui/icons/Explore';
import { Page, Content } from '@backstage/core-components';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';

const useStyles = makeStyles(theme => ({
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
  radarContainer: {
    display: 'flex',
    justifyContent: 'center',
    padding: theme.spacing(2),
  },
  filterButton: {
    textTransform: 'none' as const,
    fontWeight: 700,
    fontSize: 12,
    fontFamily: '"Inter", sans-serif',
    borderRadius: 8,
    padding: '6px 16px',
    '&.MuiButton-contained': {
      backgroundColor: '#7FBA00',
      color: '#fff',
      boxShadow: 'none',
      '&:hover': {
        backgroundColor: '#6da200',
      },
    },
  },
  filterWrapper: {
    display: 'flex',
    justifyContent: 'center',
    marginBottom: 32,
  },
  legendItem: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '8px 0',
    borderBottom: '1px solid rgba(0,0,0,0.04)',
    '&:last-child': {
      borderBottom: 'none',
    },
  },
  legendDot: {
    width: 12,
    height: 12,
    borderRadius: '50%',
    flexShrink: 0,
  },
  legendLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#171c21',
    flex: 1,
  },
  techRow: {
    cursor: 'pointer',
    transition: 'background 0.15s',
    '&:hover': { background: 'rgba(127, 186, 0, 0.04)' },
  },
  ringChip: {
    fontSize: 10,
    height: 22,
    fontWeight: 800,
    fontFamily: '"Inter", sans-serif',
    letterSpacing: '0.05em',
    textTransform: 'uppercase' as const,
  },
  sectionLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    fontWeight: 900,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    marginBottom: 16,
  },
  tableHeader: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 800,
    fontSize: 11,
    color: '#717783',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.1em',
    borderBottom: '2px solid #eaeef5',
  },
  tableName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 600,
    color: '#171c21',
  },
  tableDesc: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    color: '#717783',
    lineHeight: 1.5,
  },
  categoryChip: {
    fontSize: 10,
    height: 22,
    fontWeight: 700,
    fontFamily: '"Inter", sans-serif',
  },
}));

type Ring = 'adopt' | 'trial' | 'assess' | 'hold';
type Category = 'all' | 'languages' | 'frameworks' | 'infrastructure' | 'tools' | 'databases' | 'ai-ml';

interface TechEntry {
  name: string;
  ring: Ring;
  category: Exclude<Category, 'all'>;
  description: string;
}

const RING_CONFIG: Record<Ring, { label: string; color: string; radius: number }> = {
  adopt: { label: 'Adopt', color: '#2E7D32', radius: 90 },
  trial: { label: 'Trial', color: '#0078D4', radius: 160 },
  assess: { label: 'Assess', color: '#F57F17', radius: 230 },
  hold: { label: 'Hold', color: '#C62828', radius: 290 },
};

const CATEGORY_CONFIG: Record<Exclude<Category, 'all'>, { label: string; color: string; startAngle: number }> = {
  languages: { label: 'Languages', color: '#3178c6', startAngle: 0 },
  frameworks: { label: 'Frameworks', color: '#2E7D32', startAngle: 60 },
  infrastructure: { label: 'Infrastructure', color: '#E65100', startAngle: 120 },
  tools: { label: 'Tools', color: '#5C2D91', startAngle: 180 },
  databases: { label: 'Databases', color: '#00695C', startAngle: 240 },
  'ai-ml': { label: 'AI / ML', color: '#AD1457', startAngle: 300 },
};

const TECHNOLOGIES: TechEntry[] = [
  // Languages
  { name: 'TypeScript', ring: 'adopt', category: 'languages', description: 'Primary for Backstage plugins, frontend apps, and MCP servers' },
  { name: 'Python', ring: 'adopt', category: 'languages', description: 'FastAPI agent backends, AI/ML pipelines, automation scripts' },
  { name: 'C#', ring: 'adopt', category: 'languages', description: '.NET microservices and Azure Functions' },
  { name: 'Go', ring: 'trial', category: 'languages', description: 'Cloud-native CLI tools and microservices' },
  { name: 'Java', ring: 'trial', category: 'languages', description: 'Spring Boot enterprise applications' },
  { name: 'Bicep', ring: 'adopt', category: 'languages', description: 'Azure infrastructure as code' },
  // Frameworks
  { name: 'React', ring: 'adopt', category: 'frameworks', description: 'Portal frontend (Backstage)' },
  { name: 'FastAPI', ring: 'adopt', category: 'frameworks', description: 'Python API microservices and agent backends' },
  { name: 'Express.js', ring: 'adopt', category: 'frameworks', description: 'Node.js backend services and MCP servers' },
  { name: 'Spring Boot', ring: 'trial', category: 'frameworks', description: 'Java enterprise applications' },
  { name: '.NET Aspire', ring: 'assess', category: 'frameworks', description: 'Cloud-ready .NET distributed applications' },
  // Infrastructure
  { name: 'AKS', ring: 'adopt', category: 'infrastructure', description: 'Azure Kubernetes Service — production workloads' },
  { name: 'Terraform', ring: 'adopt', category: 'infrastructure', description: 'Multi-cloud infrastructure as code' },
  { name: 'ArgoCD', ring: 'adopt', category: 'infrastructure', description: 'GitOps continuous delivery for Kubernetes' },
  { name: 'Helm', ring: 'adopt', category: 'infrastructure', description: 'Kubernetes package management' },
  { name: 'Azure Container Apps', ring: 'trial', category: 'infrastructure', description: 'Serverless container hosting' },
  // Tools
  { name: 'GitHub Actions', ring: 'adopt', category: 'tools', description: 'CI/CD workflows and automation' },
  { name: 'GitHub Copilot', ring: 'adopt', category: 'tools', description: 'AI pair programmer and code review' },
  { name: 'Backstage', ring: 'adopt', category: 'tools', description: 'Internal developer portal' },
  { name: 'Prometheus', ring: 'adopt', category: 'tools', description: 'Metrics collection and alerting' },
  { name: 'Grafana', ring: 'adopt', category: 'tools', description: 'Observability dashboards' },
  { name: 'Claude Code', ring: 'trial', category: 'tools', description: 'Agentic coding assistant' },
  // Databases
  { name: 'PostgreSQL', ring: 'adopt', category: 'databases', description: 'Primary relational database' },
  { name: 'Redis', ring: 'adopt', category: 'databases', description: 'In-memory cache and messaging' },
  { name: 'CosmosDB', ring: 'trial', category: 'databases', description: 'Globally distributed NoSQL database' },
  // AI/ML
  { name: 'Azure AI Foundry', ring: 'trial', category: 'ai-ml', description: 'AI model deployment and management' },
  { name: 'MCP Protocol', ring: 'trial', category: 'ai-ml', description: 'Model Context Protocol for tool integration' },
  { name: 'Semantic Kernel', ring: 'trial', category: 'ai-ml', description: 'Microsoft AI orchestration framework' },
  { name: 'MS Agent Framework', ring: 'trial', category: 'ai-ml', description: 'Microsoft Agent Framework for multi-agent systems' },
  { name: 'LangChain', ring: 'assess', category: 'ai-ml', description: 'LLM application framework' },
  { name: 'AutoGen', ring: 'assess', category: 'ai-ml', description: 'Multi-agent conversation framework' },
];

// Deterministic position based on name hash
function hashCode(s: string): number {
  let hash = 0;
  for (let i = 0; i < s.length; i++) {
    hash = ((hash << 5) - hash + s.charCodeAt(i)) | 0;
  }
  return Math.abs(hash);
}

function getTechPosition(tech: TechEntry, index: number): { x: number; y: number } {
  const catConfig = CATEGORY_CONFIG[tech.category];
  const ringConfig = RING_CONFIG[tech.ring];
  const prevRing = tech.ring === 'adopt' ? 0 : tech.ring === 'trial' ? 90 : tech.ring === 'assess' ? 160 : 230;

  const h = hashCode(tech.name + index);
  const radiusOffset = prevRing + ((h % 100) / 100) * (ringConfig.radius - prevRing) * 0.8 + (ringConfig.radius - prevRing) * 0.1;
  const angleSpread = 50; // degrees within sector
  const angleOffset = catConfig.startAngle + 5 + ((h % 73) / 73) * angleSpread;
  const rad = (angleOffset * Math.PI) / 180;

  return {
    x: 300 + radiusOffset * Math.cos(rad),
    y: 300 + radiusOffset * Math.sin(rad),
  };
}

const TechRadarPage = () => {
  const classes = useStyles();
  const [filter, setFilter] = useState<Category>('all');
  const [hoveredTech, setHoveredTech] = useState<string | null>(null);

  const filteredTechs = filter === 'all' ? TECHNOLOGIES : TECHNOLOGIES.filter(t => t.category === filter);

  const ringCounts: Record<Ring, number> = { adopt: 0, trial: 0, assess: 0, hold: 0 };
  for (const t of filteredTechs) ringCounts[t.ring]++;

  return (
    <Page themeId="tool" className={classes.pageRoot}>
      <Content className={classes.content}>
        {/* Hero Banner */}
        <HeroBanner
          icon={<TrackChangesIcon style={{ fontSize: 24, color: '#7FBA00' }} />}
          label="Technology Strategy"
          title={<>Technology <span style={{ color: '#7FBA00' }}>Radar</span></>}
          subtitle="Navigate the evolving landscape of software engineering. Discover, track, and evaluate technologies across our enterprise ecosystem."
          accentColor="#7FBA00"
          stats={[
            {
              label: 'Tracked Items',
              value: String(TECHNOLOGIES.length),
              icon: <CategoryIcon style={{ fontSize: 20 }} />,
              color: '#7FBA00',
            },
            {
              label: 'Adopt',
              value: String(TECHNOLOGIES.filter(t => t.ring === 'adopt').length),
              icon: <CheckCircleIcon style={{ fontSize: 20 }} />,
              color: '#2E7D32',
            },
            {
              label: 'Trial',
              value: String(TECHNOLOGIES.filter(t => t.ring === 'trial').length),
              icon: <FlashOnIcon style={{ fontSize: 20 }} />,
              color: '#0078D4',
            },
            {
              label: 'Assess',
              value: String(TECHNOLOGIES.filter(t => t.ring === 'assess').length),
              icon: <ExploreIcon style={{ fontSize: 20 }} />,
              color: '#F57F17',
            },
          ]}
        />

        <div className={classes.space} />

        {/* Category Filter */}
        <div className={classes.filterWrapper}>
          <ButtonGroup size="small" variant="outlined">
            <Button
              className={classes.filterButton}
              onClick={() => setFilter('all')}
              variant={filter === 'all' ? 'contained' : 'outlined'}
            >
              All
            </Button>
            {Object.entries(CATEGORY_CONFIG).map(([key, cfg]) => (
              <Button
                key={key}
                className={classes.filterButton}
                onClick={() => setFilter(key as Category)}
                variant={filter === key ? 'contained' : 'outlined'}
              >
                {cfg.label}
              </Button>
            ))}
          </ButtonGroup>
        </div>

        <Grid container spacing={3}>
          {/* Radar SVG */}
          <Grid item xs={12} md={8}>
            <StyledCard title="Radar View" subtitle="Interactive technology landscape">
              <div className={classes.radarContainer}>
                <svg viewBox="0 0 600 600" width="100%" style={{ maxWidth: 560 }}>
                  {/* Ring circles */}
                  {Object.entries(RING_CONFIG).reverse().map(([, cfg]) => (
                    <circle
                      key={cfg.radius}
                      cx={300}
                      cy={300}
                      r={cfg.radius}
                      fill="none"
                      stroke={cfg.color}
                      strokeWidth={1}
                      strokeOpacity={0.2}
                    />
                  ))}
                  {/* Ring fills (background) */}
                  {Object.entries(RING_CONFIG).reverse().map(([, cfg]) => (
                    <circle
                      key={`fill-${cfg.radius}`}
                      cx={300}
                      cy={300}
                      r={cfg.radius}
                      fill={cfg.color}
                      fillOpacity={0.03}
                    />
                  ))}

                  {/* Sector dividers */}
                  {Object.values(CATEGORY_CONFIG).map(cfg => {
                    const rad = (cfg.startAngle * Math.PI) / 180;
                    return (
                      <line
                        key={cfg.startAngle}
                        x1={300}
                        y1={300}
                        x2={300 + 290 * Math.cos(rad)}
                        y2={300 + 290 * Math.sin(rad)}
                        stroke="#e0e0e0"
                        strokeWidth={1}
                      />
                    );
                  })}

                  {/* Ring labels */}
                  {Object.entries(RING_CONFIG).map(([, cfg]) => (
                    <text
                      key={`label-${cfg.radius}`}
                      x={300}
                      y={300 - cfg.radius + 14}
                      textAnchor="middle"
                      fontSize={10}
                      fontWeight={600}
                      fill={cfg.color}
                      opacity={0.6}
                      fontFamily='"Inter", sans-serif'
                    >
                      {cfg.label}
                    </text>
                  ))}

                  {/* Category labels */}
                  {Object.entries(CATEGORY_CONFIG).map(([, cfg]) => {
                    const midAngle = cfg.startAngle + 30;
                    const rad = (midAngle * Math.PI) / 180;
                    const labelR = 270;
                    return (
                      <text
                        key={`cat-${cfg.startAngle}`}
                        x={300 + labelR * Math.cos(rad)}
                        y={300 + labelR * Math.sin(rad)}
                        textAnchor="middle"
                        fontSize={9}
                        fontWeight={700}
                        fill={cfg.color}
                        opacity={0.7}
                        fontFamily='"Inter", sans-serif'
                      >
                        {cfg.label}
                      </text>
                    );
                  })}

                  {/* Technology dots */}
                  {filteredTechs.map((tech, i) => {
                    const pos = getTechPosition(tech, i);
                    const isHovered = hoveredTech === tech.name;
                    const catColor = CATEGORY_CONFIG[tech.category].color;
                    return (
                      <g key={tech.name}>
                        <circle
                          cx={pos.x}
                          cy={pos.y}
                          r={isHovered ? 10 : 7}
                          fill={catColor}
                          fillOpacity={isHovered ? 1 : 0.8}
                          stroke="#fff"
                          strokeWidth={2}
                          style={{ cursor: 'pointer', transition: 'r 0.2s' }}
                          onMouseEnter={() => setHoveredTech(tech.name)}
                          onMouseLeave={() => setHoveredTech(null)}
                        />
                        {isHovered && (
                          <>
                            <rect
                              x={pos.x + 12}
                              y={pos.y - 12}
                              width={tech.name.length * 7 + 16}
                              height={22}
                              rx={4}
                              fill="rgba(0,0,0,0.8)"
                            />
                            <text
                              x={pos.x + 20}
                              y={pos.y + 2}
                              fontSize={11}
                              fontWeight={600}
                              fill="#fff"
                              fontFamily='"Inter", sans-serif'
                            >
                              {tech.name}
                            </text>
                          </>
                        )}
                      </g>
                    );
                  })}
                </svg>
              </div>
            </StyledCard>
          </Grid>

          {/* Legend + Summary */}
          <Grid item xs={12} md={4}>
            <StyledCard title="Ring Summary" subtitle="Adoption stages">
              {Object.entries(RING_CONFIG).map(([ring, cfg]) => (
                <div key={ring} className={classes.legendItem}>
                  <div className={classes.legendDot} style={{ background: cfg.color }} />
                  <span className={classes.legendLabel}>{cfg.label}</span>
                  <Chip
                    label={ringCounts[ring as Ring]}
                    size="small"
                    className={classes.ringChip}
                    style={{ background: `${cfg.color}15`, color: cfg.color }}
                  />
                </div>
              ))}
            </StyledCard>

            <div className={classes.spaceSm} />

            <StyledCard title="Categories" subtitle="Technology domains">
              {Object.entries(CATEGORY_CONFIG).map(([key, cfg]) => {
                const count = TECHNOLOGIES.filter(t => t.category === key).length;
                return (
                  <div key={key} className={classes.legendItem}>
                    <div className={classes.legendDot} style={{ background: cfg.color }} />
                    <span className={classes.legendLabel}>{cfg.label}</span>
                    <Typography
                      variant="caption"
                      style={{
                        fontFamily: '"Inter", sans-serif',
                        fontWeight: 700,
                        color: '#717783',
                        fontSize: 12,
                      }}
                    >
                      {count}
                    </Typography>
                  </div>
                );
              })}
            </StyledCard>
          </Grid>
        </Grid>

        <div className={classes.space} />

        {/* Technology Table */}
        <StyledCard
          title={`Technology Details (${filteredTechs.length})`}
          subtitle="Complete technology inventory"
        >
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell className={classes.tableHeader}>Technology</TableCell>
                <TableCell className={classes.tableHeader}>Ring</TableCell>
                <TableCell className={classes.tableHeader}>Category</TableCell>
                <TableCell className={classes.tableHeader}>Description</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredTechs.map(tech => (
                <TableRow
                  key={tech.name}
                  className={classes.techRow}
                  onMouseEnter={() => setHoveredTech(tech.name)}
                  onMouseLeave={() => setHoveredTech(null)}
                  style={{ background: hoveredTech === tech.name ? 'rgba(127, 186, 0, 0.04)' : undefined }}
                >
                  <TableCell className={classes.tableName}>{tech.name}</TableCell>
                  <TableCell>
                    <Chip
                      label={RING_CONFIG[tech.ring].label}
                      size="small"
                      className={classes.ringChip}
                      style={{
                        background: `${RING_CONFIG[tech.ring].color}15`,
                        color: RING_CONFIG[tech.ring].color,
                      }}
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={CATEGORY_CONFIG[tech.category].label}
                      size="small"
                      variant="outlined"
                      className={classes.categoryChip}
                      style={{
                        borderColor: CATEGORY_CONFIG[tech.category].color,
                        color: CATEGORY_CONFIG[tech.category].color,
                      }}
                    />
                  </TableCell>
                  <TableCell className={classes.tableDesc}>{tech.description}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </StyledCard>
      </Content>
    </Page>
  );
};

export default TechRadarPage;
