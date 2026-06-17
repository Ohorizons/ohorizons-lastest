import { makeStyles } from '@material-ui/core';

const useStyles = makeStyles({
  stripe: {
    display: 'flex',
    height: 2,
    width: '100%',
  },
  blue: { flex: 1, backgroundColor: '#00A4EF' },
  red: { flex: 1, backgroundColor: '#F25022' },
  green: { flex: 1, backgroundColor: '#7FBA00' },
  yellow: { flex: 1, backgroundColor: '#FFB900' },
});

export const MicrosoftStripe = ({ height = 2 }: { height?: number }) => {
  const classes = useStyles();
  return (
    <div className={classes.stripe} style={height !== 2 ? { height } : undefined}>
      <div className={classes.blue} />
      <div className={classes.red} />
      <div className={classes.green} />
      <div className={classes.yellow} />
    </div>
  );
};
