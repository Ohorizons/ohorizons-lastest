/**
 * OnboardingPage — Developer Onboarding Hub
 *
 * Personalized onboarding checklist, best practices, resources,
 * and AI Chat CTA for new platform users.
 *
 * Redesigned with Open Horizons UX prototype pattern:
 * HeroBanner + StyledCard + design-system styling.
 */

import { useState, useEffect } from 'react';
import { Chip, Box, Button, LinearProgress } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { Page, Content, Link } from '@backstage/core-components';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import RadioButtonUncheckedIcon from '@material-ui/icons/RadioButtonUnchecked';
import AccountTreeIcon from '@material-ui/icons/AccountTree';
import SecurityIcon from '@material-ui/icons/Security';
import BuildIcon from '@material-ui/icons/Build';
import WidgetsIcon from '@material-ui/icons/Widgets';
import ExtensionIcon from '@material-ui/icons/Extension';
import GroupIcon from '@material-ui/icons/Group';
import DescriptionIcon from '@material-ui/icons/Description';
import MenuBookIcon from '@material-ui/icons/MenuBook';
import SmartToyIcon from '@material-ui/icons/EmojiObjects';
import SchoolIcon from '@material-ui/icons/School';
import ListAltIcon from '@material-ui/icons/ListAlt';
import CloudIcon from '@material-ui/icons/Cloud';
import ChatIcon from '@material-ui/icons/Chat';
import AccessTimeIcon from '@material-ui/icons/AccessTime';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import LibraryBooksIcon from '@material-ui/icons/LibraryBooks';
import AssignmentTurnedInIcon from '@material-ui/icons/AssignmentTurnedIn';
import { HeroBanner } from '../shared/HeroBanner';
import { StyledCard } from '../shared/StyledCard';

/* ------------------------------------------------------------------ */
/*  Persistence                                                        */
/* ------------------------------------------------------------------ */

const STORAGE_KEY = 'oh-onboarding-progress';

interface ChecklistItem {
  id: string;
  title: string;
  description: string;
  status: 'completed' | 'required' | 'optional';
}

const defaultChecklist: ChecklistItem[] = [
  {
    id: 'github-sso',
    title: 'Sign in with GitHub SSO',
    description: 'Authenticate using your organization GitHub account',
    status: 'completed',
  },
  {
    id: 'explore-catalog',
    title: 'Explore the Software Catalog',
    description: 'Browse registered components, services, and APIs in the catalog',
    status: 'completed',
  },
  {
    id: 'review-api-docs',
    title: 'Review API documentation',
    description: 'Understand available APIs and integration patterns',
    status: 'completed',
  },
  {
    id: 'configure-dev-env',
    title: 'Configure your development environment',
    description: 'Set up Codespaces, local tooling, and required extensions',
    status: 'required',
  },
  {
    id: 'scaffold-service',
    title: 'Scaffold your first service',
    description: 'Use golden path templates to create a new microservice',
    status: 'required',
  },
  {
    id: 'enable-ghas',
    title: 'Enable GitHub Advanced Security',
    description: 'Activate code scanning, secret detection, and dependency review',
    status: 'required',
  },
  {
    id: 'connect-ai-chat',
    title: 'Connect to AI Agent Chat',
    description: 'Learn how to interact with the AI assistant for platform operations',
    status: 'optional',
  },
];

/* ------------------------------------------------------------------ */
/*  Data                                                               */
/* ------------------------------------------------------------------ */

const practiceCards = [
  {
    title: 'Agent Architecture Patterns',
    color: '#0078D4',
    icon: AccountTreeIcon,
    description:
      'Design patterns for building autonomous agents: event-driven workflows, orchestration vs. choreography, guardrails, and human-in-the-loop.',
    tags: ['Claude SDK', 'MCP', 'Patterns'],
  },
  {
    title: 'Security-First Development',
    color: '#7FBA00',
    icon: SecurityIcon,
    description:
      'GitHub Advanced Security integration, shift-left practices, code scanning in CI/CD, secret management with Azure Key Vault.',
    tags: ['GHAS', 'CodeQL', 'Shift-Left'],
  },
  {
    title: 'CI/CD Pipeline Standards',
    color: '#FFB900',
    icon: BuildIcon,
    description:
      'GitHub Actions workflows, deployment strategies (blue-green, canary), environment promotion gates, and rollback procedures.',
    tags: ['Actions', 'Pipelines', 'GitOps'],
  },
  {
    title: 'Golden Path Templates',
    color: '#F25022',
    icon: WidgetsIcon,
    description:
      'Standardized project scaffolds for microservices, APIs, libraries, and infrastructure modules. Pre-configured with best practices.',
    tags: ['Backstage', 'Templates', 'Scaffolder'],
  },
  {
    title: 'MCP Tool Development',
    color: '#7B1FA2',
    icon: ExtensionIcon,
    description:
      'Building Model Context Protocol tools for AI agents: tool schemas, authentication, error handling, and catalog integration.',
    tags: ['MCP', 'Tools', 'SDK'],
  },
  {
    title: 'Team Ownership Model',
    color: '#00897B',
    icon: GroupIcon,
    description:
      'Service ownership standards, CODEOWNERS configuration, on-call rotations, SLO definitions, and incident response procedures.',
    tags: ['Ownership', 'SLOs', 'RACI'],
  },
];

const resourceItems = [
  {
    icon: DescriptionIcon,
    title: 'Platform Documentation',
    subtitle: 'Complete guides for the Open Horizons platform',
  },
  {
    icon: MenuBookIcon,
    title: 'API Catalog & Specs',
    subtitle: 'OpenAPI specifications and integration guides',
  },
  {
    icon: SmartToyIcon,
    title: 'AI Agent Guides',
    subtitle: 'How to use Claude SDK, MCP tools, and AI assistants',
  },
  {
    icon: SchoolIcon,
    title: 'Learning Paths',
    subtitle: 'Structured courses for Agentic DevOps adoption',
  },
  {
    icon: ListAltIcon,
    title: 'Software Catalog Guide',
    subtitle: 'Register and manage services, components, and resources',
  },
  {
    icon: CloudIcon,
    title: 'Codespaces Setup',
    subtitle: 'Pre-configured dev environments in the cloud',
  },
];

function loadProgress(): Record<string, boolean> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function saveProgress(progress: Record<string, boolean>) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
}

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

  /* Progress bar at top */
  progressSection: {
    marginBottom: 8,
  },
  progressHeader: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  progressLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 700,
    color: '#171c21',
  },
  progressPercent: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 14,
    fontWeight: 800,
    color: '#7FBA00',
  },
  progressBar: {
    height: 8,
    borderRadius: 4,
    backgroundColor: 'rgba(127, 186, 0, 0.12)',
    '& .MuiLinearProgress-bar': {
      backgroundColor: '#7FBA00',
      borderRadius: 4,
    },
  },
  progressSubtext: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    color: '#717783',
    marginTop: 6,
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

  /* Checklist */
  checklistBody: {
    padding: 0,
  },
  checklistRow: {
    display: 'flex',
    alignItems: 'center',
    padding: '14px 20px',
    borderBottom: '1px solid rgba(0, 0, 0, 0.06)',
    cursor: 'pointer',
    background: 'none',
    border: 'none',
    width: '100%',
    textAlign: 'left' as const,
    fontFamily: '"Inter", sans-serif',
    transition: 'background-color 0.15s ease',
    '&:hover': {
      backgroundColor: 'rgba(127, 186, 0, 0.04)',
    },
    '&:last-child': {
      borderBottom: 'none',
    },
  },
  checkIcon: {
    color: '#7FBA00',
    fontSize: 22,
    marginRight: 16,
    flexShrink: 0,
  },
  uncheckIcon: {
    color: '#c0c7d4',
    fontSize: 22,
    marginRight: 16,
    flexShrink: 0,
  },
  itemContent: {
    flex: 1,
    minWidth: 0,
  },
  itemTitle: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 700,
    fontSize: 14,
    color: '#171c21',
    marginBottom: 2,
  },
  itemTitleCompleted: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 700,
    fontSize: 14,
    color: '#717783',
    textDecoration: 'line-through',
    marginBottom: 2,
  },
  itemDescription: {
    fontFamily: '"Inter", sans-serif',
    color: '#717783',
    fontSize: 12,
    lineHeight: 1.4,
  },
  badgeCompleted: {
    backgroundColor: 'rgba(127, 186, 0, 0.12)',
    color: '#5a8a00',
    fontWeight: 700,
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    height: 24,
    borderRadius: 6,
  },
  badgeRequired: {
    backgroundColor: 'rgba(242, 80, 34, 0.10)',
    color: '#c62828',
    fontWeight: 700,
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    height: 24,
    borderRadius: 6,
  },
  badgeOptional: {
    backgroundColor: 'rgba(113, 119, 131, 0.10)',
    color: '#717783',
    fontWeight: 700,
    fontFamily: '"Inter", sans-serif',
    fontSize: 11,
    height: 24,
    borderRadius: 6,
  },

  /* Practice cards — 3 column grid */
  practiceGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(3, 1fr)',
    gap: 24,
  },
  practiceCard: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    boxShadow: '0 8px 32px rgba(0, 28, 57, 0.08)',
    overflow: 'hidden',
    transition: 'all 0.3s ease',
    '&:hover': {
      transform: 'translateY(-2px)',
      boxShadow: '0 12px 40px rgba(0, 28, 57, 0.12)',
    },
  },
  practiceCardTop: {
    height: 4,
  },
  practiceCardBody: {
    padding: 24,
  },
  practiceIcon: {
    fontSize: 32,
    marginBottom: 12,
  },
  practiceTitle: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 800,
    fontSize: 15,
    color: '#171c21',
    letterSpacing: '-0.01em',
    marginBottom: 8,
  },
  practiceDescription: {
    fontFamily: '"Inter", sans-serif',
    color: '#717783',
    fontSize: 13,
    lineHeight: 1.6,
    marginBottom: 16,
  },
  practiceTags: {
    display: 'flex',
    gap: 6,
    flexWrap: 'wrap' as const,
  },
  tagChip: {
    height: 22,
    fontSize: 11,
    fontFamily: '"Inter", sans-serif',
    fontWeight: 600,
    borderColor: 'rgba(0, 0, 0, 0.12)',
  },

  /* Resources — two-column grid */
  resourceGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 24,
  },
  resourceRow: {
    display: 'flex',
    alignItems: 'center',
    padding: '16px 20px',
    borderBottom: '1px solid rgba(0, 0, 0, 0.06)',
    '&:last-child': {
      borderBottom: 'none',
    },
  },
  resourceIcon: {
    color: '#0078D4',
    marginRight: 16,
    fontSize: 26,
    flexShrink: 0,
  },
  resourceTitle: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 700,
    fontSize: 14,
    color: '#171c21',
    marginBottom: 2,
  },
  resourceSubtitle: {
    fontFamily: '"Inter", sans-serif',
    color: '#717783',
    fontSize: 12,
    lineHeight: 1.4,
  },

  /* CTA Banner */
  ctaBanner: {
    background: 'linear-gradient(135deg, #0078D4 0%, #00A4EF 100%)',
    color: '#fff',
    borderRadius: 16,
    padding: '40px 48px',
    display: 'flex',
    alignItems: 'center',
    gap: 32,
    boxShadow: '0 12px 40px rgba(0, 120, 212, 0.25)',
    position: 'relative' as const,
    overflow: 'hidden',
  },
  ctaBlur: {
    position: 'absolute' as const,
    top: -60,
    right: -60,
    width: 200,
    height: 200,
    borderRadius: '50%',
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    filter: 'blur(40px)',
  },
  ctaIcon: {
    fontSize: 48,
    opacity: 0.9,
    flexShrink: 0,
    zIndex: 1,
  },
  ctaContent: {
    flex: 1,
    minWidth: 280,
    zIndex: 1,
  },
  ctaTitle: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 800,
    fontSize: '1.25rem',
    marginBottom: 6,
    letterSpacing: '-0.01em',
  },
  ctaDescription: {
    fontFamily: '"Inter", sans-serif',
    opacity: 0.85,
    fontSize: 14,
    lineHeight: 1.6,
  },
  ctaLink: {
    textDecoration: 'none',
    zIndex: 1,
  },
  ctaButton: {
    backgroundColor: '#fff',
    color: '#0078D4',
    fontFamily: '"Inter", sans-serif',
    fontWeight: 800,
    textTransform: 'none' as const,
    padding: '12px 32px',
    borderRadius: 10,
    fontSize: 14,
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
    '&:hover': {
      backgroundColor: '#e3f2fd',
    },
  },
});

/* ------------------------------------------------------------------ */
/*  Component                                                          */
/* ------------------------------------------------------------------ */

const OnboardingPage = () => {
  const classes = useStyles();
  const [completed, setCompleted] = useState<Record<string, boolean>>(() => {
    const saved = loadProgress();
    // Pre-fill default completed items if no saved state
    if (Object.keys(saved).length === 0) {
      return defaultChecklist.reduce(
        (acc, item) => {
          if (item.status === 'completed') acc[item.id] = true;
          return acc;
        },
        {} as Record<string, boolean>,
      );
    }
    return saved;
  });

  useEffect(() => {
    saveProgress(completed);
  }, [completed]);

  const toggleItem = (id: string) => {
    setCompleted(prev => ({ ...prev, [id]: !prev[id] }));
  };

  const completedCount = defaultChecklist.filter(i => completed[i.id]).length;
  const totalCount = defaultChecklist.length;
  const progressPercent = Math.round((completedCount / totalCount) * 100);

  const statusBadge = (item: ChecklistItem) => {
    if (completed[item.id]) {
      return <Chip label="Completed" size="small" className={classes.badgeCompleted} />;
    }
    if (item.status === 'required') {
      return <Chip label="Required" size="small" className={classes.badgeRequired} />;
    }
    return <Chip label="Optional" size="small" className={classes.badgeOptional} />;
  };

  return (
    <Page themeId="home">
      <Content className={classes.pageRoot}>
        <div className={classes.content}>
          {/* ── Hero Banner ── */}
          <HeroBanner
            icon={<GroupIcon style={{ fontSize: 24, color: '#7FBA00' }} />}
            label="Onboarding Hub"
            title={
              <>
                Your <span style={{ color: '#7FBA00' }}>Journey</span>
              </>
            }
            subtitle="Your personalized path to becoming a platform expert. Follow the steps below to set up your environment and start building."
            accentColor="#7FBA00"
            stats={[
              {
                label: 'Avg Onboarding',
                value: '3.2d',
                icon: <AccessTimeIcon style={{ fontSize: 20 }} />,
                color: '#7FBA00',
              },
              {
                label: 'Progress',
                value: `${completedCount}/${totalCount}`,
                icon: <TrendingUpIcon style={{ fontSize: 20 }} />,
                color: '#0078D4',
              },
              {
                label: 'Practices',
                value: '6',
                icon: <LibraryBooksIcon style={{ fontSize: 20 }} />,
                color: '#FFB900',
              },
              {
                label: 'Resources',
                value: '6',
                icon: <AssignmentTurnedInIcon style={{ fontSize: 20 }} />,
                color: '#F25022',
              },
            ]}
          />

          <div className={classes.space} />

          {/* ── Progress Bar ── */}
          <div className={classes.progressSection}>
            <div className={classes.progressHeader}>
              <span className={classes.progressLabel}>
                Onboarding Progress
              </span>
              <span className={classes.progressPercent}>
                {progressPercent}%
              </span>
            </div>
            <LinearProgress
              variant="determinate"
              value={progressPercent}
              className={classes.progressBar}
            />
            <div className={classes.progressSubtext}>
              {completedCount} of {totalCount} steps completed
            </div>
          </div>

          <div className={classes.space} />

          {/* ── Onboarding Checklist ── */}
          <div className={classes.sectionLabel}>Getting Started</div>
          <StyledCard title="Onboarding Checklist" subtitle="Setup Steps">
            <div className={classes.checklistBody}>
              {defaultChecklist.map(item => (
                <button
                  key={item.id}
                  type="button"
                  className={classes.checklistRow}
                  onClick={() => toggleItem(item.id)}
                >
                  {completed[item.id] ? (
                    <CheckCircleIcon className={classes.checkIcon} />
                  ) : (
                    <RadioButtonUncheckedIcon className={classes.uncheckIcon} />
                  )}
                  <div className={classes.itemContent}>
                    <div
                      className={
                        completed[item.id]
                          ? classes.itemTitleCompleted
                          : classes.itemTitle
                      }
                    >
                      {item.title}
                    </div>
                    <div className={classes.itemDescription}>
                      {item.description}
                    </div>
                  </div>
                  {statusBadge(item)}
                </button>
              ))}
            </div>
          </StyledCard>

          <div className={classes.space} />

          {/* ── Best Practices ── */}
          <div className={classes.sectionLabel}>Knowledge Base</div>
          <div className={classes.sectionTitle}>
            Agentic DevOps Best Practices
          </div>
          <div className={classes.spaceSm} />

          <div className={classes.practiceGrid}>
            {practiceCards.map(card => {
              const Icon = card.icon;
              return (
                <div key={card.title} className={classes.practiceCard}>
                  <div
                    className={classes.practiceCardTop}
                    style={{ backgroundColor: card.color }}
                  />
                  <div className={classes.practiceCardBody}>
                    <Icon
                      className={classes.practiceIcon}
                      style={{ color: card.color }}
                    />
                    <div className={classes.practiceTitle}>{card.title}</div>
                    <div className={classes.practiceDescription}>
                      {card.description}
                    </div>
                    <div className={classes.practiceTags}>
                      {card.tags.map(tag => (
                        <Chip
                          key={tag}
                          label={tag}
                          size="small"
                          variant="outlined"
                          className={classes.tagChip}
                        />
                      ))}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          <div className={classes.space} />

          {/* ── Documentation & Learning Resources ── */}
          <div className={classes.sectionLabel}>Reference</div>
          <div className={classes.sectionTitle}>
            Documentation &amp; Learning Resources
          </div>
          <div className={classes.spaceSm} />

          <div className={classes.resourceGrid}>
            {['left', 'right'].map(side => {
              const column =
                side === 'left'
                  ? resourceItems.slice(0, 3)
                  : resourceItems.slice(3);
              return (
                <StyledCard key={side}>
                  {column.map(res => {
                    const Icon = res.icon;
                    return (
                      <div key={res.title} className={classes.resourceRow}>
                        <Icon className={classes.resourceIcon} />
                        <div>
                          <div className={classes.resourceTitle}>
                            {res.title}
                          </div>
                          <div className={classes.resourceSubtitle}>
                            {res.subtitle}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </StyledCard>
              );
            })}
          </div>

          <div className={classes.space} />

          {/* ── AI Chat CTA Banner ── */}
          <Box className={classes.ctaBanner}>
            <div className={classes.ctaBlur} />
            <ChatIcon className={classes.ctaIcon} />
            <div className={classes.ctaContent}>
              <div className={classes.ctaTitle}>
                Need help? Ask the AI Agent
              </div>
              <div className={classes.ctaDescription}>
                The AI Chat agent can walk you through every onboarding step,
                recommend next actions based on your progress, search
                documentation, and help you scaffold your first service. Just
                ask!
              </div>
            </div>
            <Link to="/ai-chat" className={classes.ctaLink}>
              <Button variant="contained" className={classes.ctaButton}>
                Open AI Chat
              </Button>
            </Link>
          </Box>
        </div>
      </Content>
    </Page>
  );
};

export default OnboardingPage;
