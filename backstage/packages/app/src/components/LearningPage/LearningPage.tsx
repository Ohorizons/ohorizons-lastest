import { Link as RouterLink } from 'react-router-dom';
import { Grid, makeStyles, Typography, Card, CardContent, CardActions, Button } from '@material-ui/core';
import OpenInNewIcon from '@material-ui/icons/OpenInNew';
import { StandardPage } from '../layout/StandardPage';

import copilotLogo from '../../assets/logo-github-copilot.png';
import aiCopilotLogo from '../../assets/logo-ai-copilot.png';
import aiMicrosoftLogo from '../../assets/logo-ai-microsoft.png';

const useStyles = makeStyles(theme => ({
  card: {
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
    borderRadius: 12,
  },
  cardMedia: {
    height: 100,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'linear-gradient(135deg, #f5f5f5 0%, #e8e8e8 100%)',
    padding: theme.spacing(2),
  },
  cardImage: {
    maxHeight: 60,
    maxWidth: '80%',
    objectFit: 'contain',
  },
  cardContent: {
    flexGrow: 1,
  },
  sectionTitle: {
    fontWeight: 600,
    marginBottom: theme.spacing(2),
    marginTop: theme.spacing(2),
  },
}));

const resources = [
  {
    title: 'GitHub Copilot',
    description: 'AI-powered code completion and chat for developers. Learn how to use Copilot to accelerate development.',
    image: copilotLogo,
    links: [
      { label: 'Documentation', url: 'https://docs.github.com/en/copilot' },
      { label: 'Best Practices', url: 'https://docs.github.com/en/copilot/using-github-copilot/best-practices-for-using-github-copilot' },
    ],
  },
  {
    title: 'Azure AI Foundry',
    description: 'Build, evaluate, and deploy generative AI solutions with Azure AI Foundry and OpenAI models.',
    image: aiMicrosoftLogo,
    links: [
      { label: 'Documentation', url: 'https://learn.microsoft.com/en-us/azure/ai-studio/' },
      { label: 'Quickstart', url: 'https://learn.microsoft.com/en-us/azure/ai-studio/quickstarts/' },
    ],
  },
  {
    title: 'AI Agents & Copilots',
    description: 'Design multi-agent architectures and custom copilots using Azure AI and GitHub Copilot extensions.',
    image: aiCopilotLogo,
    links: [
      { label: 'Agent Framework', url: 'https://learn.microsoft.com/en-us/azure/ai-services/agents/' },
      { label: 'Copilot Extensions', url: 'https://docs.github.com/en/copilot/building-copilot-extensions' },
    ],
  },
];

const platformDocs = [
  { title: 'Platform Architecture', description: 'Agentic DevOps Platform architecture covering H1 Foundation, H2 Enhancement, and H3 Innovation.', url: '/docs' },
  { title: 'Golden Path Templates', description: 'Scaffold new services using 22 standardized templates with best practices.', url: '/create' },
  { title: 'API Registry', description: 'Discover and consume APIs across the platform.', url: '/api-docs' },
  { title: 'Service Catalog', description: 'Browse all registered components, systems, and domains.', url: '/catalog' },
  { title: 'Catalog Graph', description: 'Visualize entity relationships and system dependencies.', url: '/catalog-graph' },
  { title: 'Notifications', description: 'Stay informed about platform events and template executions.', url: '/notifications' },
];

const onboardingSteps = [
  { step: '1', title: 'Sign in with GitHub', description: 'Authenticate with your GitHub account to access all features.', done: true },
  { step: '2', title: 'Explore the Catalog', description: 'Browse existing components, APIs, and systems in the Service Catalog.', done: false },
  { step: '3', title: 'Create a Service', description: 'Use a Golden Path template to scaffold a new service with best practices.', done: false },
  { step: '4', title: 'Open in Codespaces', description: 'Launch your scaffolded project in GitHub Codespaces for instant development.', done: false },
  { step: '5', title: 'Read the TechDocs', description: 'Access documentation for any component directly from the catalog.', done: false },
];

const LearningPage = () => {
  const classes = useStyles();

  return (
    <StandardPage title="Learning Center" subtitle="Resources, guides, and learning paths for the platform" themeId="home">
        <Typography className={classes.sectionTitle} variant="h5">
          AI & Developer Tools
        </Typography>
        <Grid container spacing={3}>
          {resources.map(resource => (
            <Grid item xs={12} md={4} key={resource.title}>
              <Card className={classes.card} variant="outlined">
                <div className={classes.cardMedia}>
                  <img className={classes.cardImage} src={resource.image} alt={resource.title} />
                </div>
                <CardContent className={classes.cardContent}>
                  <Typography variant="h6" gutterBottom>{resource.title}</Typography>
                  <Typography variant="body2" color="textSecondary">{resource.description}</Typography>
                </CardContent>
                <CardActions>
                  {resource.links.map(link => (
                    <Button
                      key={link.label}
                      size="small"
                      color="primary"
                      href={link.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      endIcon={<OpenInNewIcon fontSize="small" />}
                    >
                      {link.label}
                    </Button>
                  ))}
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>

        <Typography className={classes.sectionTitle} variant="h5">
          Platform Resources
        </Typography>
        <Grid container spacing={3}>
          {platformDocs.map(doc => (
            <Grid item xs={12} sm={6} md={4} key={doc.title}>
              <Card className={classes.card} variant="outlined">
                <CardContent className={classes.cardContent}>
                  <Typography variant="h6" gutterBottom>{doc.title}</Typography>
                  <Typography variant="body2" color="textSecondary">{doc.description}</Typography>
                </CardContent>
                <CardActions>
                  <Button size="small" color="primary" component={RouterLink} to={doc.url}>
                    Explore
                  </Button>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>

        <Typography className={classes.sectionTitle} variant="h5">
          Getting Started — Onboarding Checklist
        </Typography>
        <Grid container spacing={2}>
          {onboardingSteps.map(item => (
            <Grid item xs={12} sm={6} key={item.step}>
              <Card variant="outlined" style={{ borderRadius: 8 }}>
                <CardContent style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                  <Typography
                    variant="h5"
                    style={{
                      background: 'linear-gradient(135deg, #0078D4, #00B7C3)',
                      color: '#fff',
                      width: 36,
                      height: 36,
                      borderRadius: '50%',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                      fontSize: '1rem',
                      fontWeight: 700,
                    }}
                  >
                    {item.step}
                  </Typography>
                  <div>
                    <Typography variant="subtitle1" style={{ fontWeight: 600 }}>{item.title}</Typography>
                    <Typography variant="body2" color="textSecondary">{item.description}</Typography>
                  </div>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
    </StandardPage>
  );
};

export default LearningPage;
