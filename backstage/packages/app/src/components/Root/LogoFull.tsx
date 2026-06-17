import { makeStyles } from '@material-ui/core';
import logoMsftGithub from '../../assets/logo-msft-github-color-black.png';

const useStyles = makeStyles({
  root: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
  },
  img: {
    height: 28,
    width: 'auto',
  },
  title: {
    fontSize: 16,
    fontWeight: 600,
    color: '#1a1a1a',
    whiteSpace: 'nowrap',
  },
});

const LogoFull = () => {
  const classes = useStyles();

  return (
    <div className={classes.root}>
      <img
        className={classes.img}
        src={logoMsftGithub}
        alt="Open Horizons"
      />
      <span className={classes.title}>Open Horizons</span>
    </div>
  );
};

export default LogoFull;
