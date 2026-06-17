import { makeStyles } from '@material-ui/core';
import logoMicrosoft from '../../assets/logo-color-microsoft.png';

const useStyles = makeStyles({
  img: {
    height: 28,
    width: 'auto',
  },
});

const LogoIcon = () => {
  const classes = useStyles();

  return (
    <img
      className={classes.img}
      src={logoMicrosoft}
      alt="Dev Portal"
    />
  );
};

export default LogoIcon;
