import { makeStyles } from '@material-ui/core/styles';
import AttachMoneyIcon from '@material-ui/icons/AttachMoney';
import TrendingDownIcon from '@material-ui/icons/TrendingDown';
import CloudIcon from '@material-ui/icons/Cloud';
import AccountBalanceIcon from '@material-ui/icons/AccountBalance';
import SpeedIcon from '@material-ui/icons/Speed';
import { CostInsightsPage as CostInsightsPlugin } from '@backstage-community/plugin-cost-insights';
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

const CostInsightsPage = () => {
  const classes = useStyles();

  return (
    <>
      <div className={classes.wrapper}>
        <HeroBanner
          icon={<AttachMoneyIcon style={{ fontSize: 24, color: '#7FBA00' }} />}
          label="Cost Insights"
          title={<>Cloud <span style={{ color: '#7FBA00' }}>Economics</span></>}
          subtitle="Monitor cloud spending, identify cost anomalies, and optimize resource allocation across your infrastructure."
          accentColor="#7FBA00"
          stats={[
            { label: 'Monthly Spend', value: '$12.4k', icon: <AccountBalanceIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
            { label: 'Savings', value: '$42k', icon: <TrendingDownIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
            { label: 'Resources', value: '340', icon: <CloudIcon style={{ fontSize: 20 }} />, color: '#FFB900' },
            { label: 'Efficiency', value: '94%', icon: <SpeedIcon style={{ fontSize: 20 }} />, color: '#F25022' },
          ]}
        />
        <div className={classes.space} />
      </div>
      <CostInsightsPlugin />
    </>
  );
};

export default CostInsightsPage;
