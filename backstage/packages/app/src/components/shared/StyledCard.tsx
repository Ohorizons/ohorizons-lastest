import React from 'react';
import { makeStyles } from '@material-ui/core';
import { MicrosoftStripe } from './MicrosoftStripe';

const useStyles = makeStyles({
  card: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    border: 'none',
    boxShadow: '0 8px 32px rgba(0, 28, 57, 0.08)',
    transition: 'all 0.3s ease',
    position: 'relative',
    overflow: 'hidden',
    '&:hover': {
      transform: 'translateY(-2px)',
      boxShadow: '0 12px 40px rgba(0, 28, 57, 0.12)',
    },
  },
  stripe: {
    position: 'absolute',
    top: 0,
    left: 0,
    width: '100%',
  },
  header: {
    padding: '16px 16px 0',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerText: {
    display: 'flex',
    flexDirection: 'column' as const,
  },
  title: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '1.5rem',
    fontWeight: 700,
    letterSpacing: '-0.02em',
    color: '#171c21',
  },
  subtitle: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '0.75rem',
    color: '#404752',
    fontWeight: 700,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.05em',
  },
  body: {
    padding: 16,
  },
});

type StyledCardProps = {
  children: React.ReactNode;
  title?: string;
  subtitle?: string;
  headerAction?: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
};

export const StyledCard = ({
  children,
  title,
  subtitle,
  headerAction,
  className,
  style,
}: StyledCardProps) => {
  const classes = useStyles();

  return (
    <div className={`${classes.card} ${className || ''}`} style={style}>
      <div className={classes.stripe}>
        <MicrosoftStripe />
      </div>
      {(title || subtitle || headerAction) && (
        <div className={classes.header}>
          <div className={classes.headerText}>
            {title && <h3 className={classes.title}>{title}</h3>}
            {subtitle && <p className={classes.subtitle}>{subtitle}</p>}
          </div>
          {headerAction && <div>{headerAction}</div>}
        </div>
      )}
      <div className={classes.body}>{children}</div>
    </div>
  );
};
