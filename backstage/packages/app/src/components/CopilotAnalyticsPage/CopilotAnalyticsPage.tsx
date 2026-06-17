import { makeStyles } from '@material-ui/core/styles';
import NewReleasesIcon from '@material-ui/icons/NewReleases';
import PeopleIcon from '@material-ui/icons/People';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import CodeIcon from '@material-ui/icons/Code';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import { CopilotIndexPage } from '@backstage-community/plugin-copilot';
import { HeroBanner } from '../shared/HeroBanner';

const useStyles = makeStyles({
  wrapper: {
    backgroundColor: '#f7f9ff',
    minHeight: '100%',
    padding: '24px 32px',
  },
  space: {
    height: 32,
  },
  pluginWrap: {
    '& .MuiPaper-root': {
      borderRadius: 12,
      boxShadow: '0 8px 32px rgba(0, 28, 57, 0.08)',
    },
  },
});

const CopilotAnalyticsPage = () => {
  const classes = useStyles();

  return (
    <>
      <div className={classes.wrapper}>
        <HeroBanner
          icon={<NewReleasesIcon style={{ fontSize: 24, color: '#FFB900' }} />}
          label="Copilot Analytics"
          title={<>AI-Powered <span style={{ color: '#FFB900' }}>Productivity</span></>}
          subtitle="Deep analytics on GitHub Copilot adoption, code acceptance rates, and AI-assisted developer velocity across the organization."
          accentColor="#FFB900"
          stats={[
            { label: 'Active Users', value: '28', icon: <PeopleIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
            { label: 'Acceptance', value: '34%', icon: <TrendingUpIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
            { label: 'Suggestions', value: '24k', icon: <CodeIcon style={{ fontSize: 20 }} />, color: '#FFB900' },
            { label: 'Efficiency', value: '+18%', icon: <CheckCircleIcon style={{ fontSize: 20 }} />, color: '#F25022' },
          ]}
        />
        <div className={classes.space} />
      </div>
      <CopilotIndexPage />
    </>
  );
};

export default CopilotAnalyticsPage;
