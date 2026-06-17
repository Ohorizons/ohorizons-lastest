import { makeStyles } from '@material-ui/core/styles';
import VerifiedUserIcon from '@material-ui/icons/VerifiedUser';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import ErrorIcon from '@material-ui/icons/Error';
import AssessmentIcon from '@material-ui/icons/Assessment';
import SecurityIcon from '@material-ui/icons/Security';
import { EntityValidationPage } from '@backstage-community/plugin-entity-validation';
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

const ValidationPage = () => {
  const classes = useStyles();

  return (
    <>
      <div className={classes.wrapper}>
        <HeroBanner
          icon={<VerifiedUserIcon style={{ fontSize: 24, color: '#0078D4' }} />}
          label="Entity Validation"
          title={<>Governance <span style={{ color: '#0078D4' }}>Compliance</span></>}
          subtitle="Enforce entity schema validation, check ownership rules, and verify catalog integrity across all registered components."
          accentColor="#0078D4"
          stats={[
            { label: 'Pass Rate', value: '98%', icon: <CheckCircleIcon style={{ fontSize: 20 }} />, color: '#7FBA00' },
            { label: 'Entities', value: '142', icon: <AssessmentIcon style={{ fontSize: 20 }} />, color: '#00A4EF' },
            { label: 'Violations', value: '3', icon: <ErrorIcon style={{ fontSize: 20 }} />, color: '#F25022' },
            { label: 'Policies', value: '18', icon: <SecurityIcon style={{ fontSize: 20 }} />, color: '#FFB900' },
          ]}
        />
        <div className={classes.space} />
      </div>
      <EntityValidationPage />
    </>
  );
};

export default ValidationPage;
