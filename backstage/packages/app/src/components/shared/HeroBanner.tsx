import React from 'react';
import { makeStyles } from '@material-ui/core';
import { MicrosoftStripe } from './MicrosoftStripe';

const useStyles = makeStyles({
  banner: {
    position: 'relative',
    overflow: 'hidden',
    borderRadius: 24,
    backgroundColor: '#2c3136',
    padding: '64px 48px',
    boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
  },
  stripe: {
    position: 'absolute',
    top: 0,
    left: 0,
    width: '100%',
  },
  blur1: {
    position: 'absolute',
    top: -80,
    right: -80,
    width: 384,
    height: 384,
    borderRadius: '50%',
    filter: 'blur(48px)',
    opacity: 0.2,
  },
  blur2: {
    position: 'absolute',
    bottom: -80,
    left: -80,
    width: 288,
    height: 288,
    borderRadius: '50%',
    filter: 'blur(48px)',
    opacity: 0.1,
  },
  content: {
    position: 'relative',
    zIndex: 1,
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 32,
  },
  left: {
    maxWidth: 640,
  },
  iconRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    marginBottom: 24,
  },
  iconBox: {
    width: 48,
    height: 48,
    borderRadius: 12,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    border: '1px solid',
  },
  label: {
    fontFamily: '"Inter", sans-serif',
    fontWeight: 900,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.3em',
    fontSize: 12,
  },
  title: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '2.5rem',
    fontWeight: 900,
    color: '#ffffff',
    letterSpacing: '-0.02em',
    marginBottom: 24,
    lineHeight: 1.1,
  },
  subtitle: {
    fontFamily: '"Inter", sans-serif',
    fontSize: '1rem',
    color: 'rgba(192, 199, 212, 0.7)',
    lineHeight: 1.6,
    marginBottom: 32,
    maxWidth: 540,
  },
  actions: {
    display: 'flex',
    flexWrap: 'wrap' as const,
    gap: 16,
  },
  primaryBtn: {
    padding: '16px 32px',
    color: '#ffffff',
    fontFamily: '"Inter", sans-serif',
    fontWeight: 900,
    borderRadius: 12,
    boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.2)',
    border: 'none',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    fontSize: 14,
    transition: 'transform 0.2s',
    '&:hover': {
      transform: 'translateY(-2px)',
    },
  },
  secondaryBtn: {
    padding: '16px 32px',
    backgroundColor: 'rgba(255,255,255,0.05)',
    color: '#ffffff',
    fontFamily: '"Inter", sans-serif',
    fontWeight: 900,
    borderRadius: 12,
    border: '1px solid rgba(255,255,255,0.1)',
    cursor: 'pointer',
    fontSize: 14,
    transition: 'background-color 0.2s',
    '&:hover': {
      backgroundColor: 'rgba(255,255,255,0.1)',
    },
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 16,
    width: '100%',
    maxWidth: 400,
  },
  statCard: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    backdropFilter: 'blur(12px)',
    border: '1px solid rgba(255,255,255,0.1)',
    padding: 24,
    borderRadius: 16,
  },
  statIcon: {
    marginBottom: 12,
  },
  statValue: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 24,
    fontWeight: 900,
    color: '#ffffff',
  },
  statLabel: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 700,
    color: 'rgba(192, 199, 212, 0.4)',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    marginTop: 4,
  },
});

type StatItem = {
  label: string;
  value: string;
  icon: React.ReactNode;
  color: string;
};

type HeroBannerProps = {
  icon: React.ReactNode;
  label: string;
  title: React.ReactNode;
  subtitle: string;
  accentColor: string;
  primaryAction?: { label: string; onClick?: () => void };
  secondaryAction?: { label: string; onClick?: () => void };
  stats?: StatItem[];
};

export const HeroBanner = ({
  icon,
  label,
  title,
  subtitle,
  accentColor,
  primaryAction,
  secondaryAction,
  stats,
}: HeroBannerProps) => {
  const classes = useStyles();

  return (
    <section className={classes.banner}>
      <div className={classes.stripe}>
        <MicrosoftStripe height={6} />
      </div>
      <div className={classes.blur1} style={{ backgroundColor: accentColor }} />
      <div className={classes.blur2} style={{ backgroundColor: '#005faa' }} />

      <div className={classes.content}>
        <div className={classes.left}>
          <div className={classes.iconRow}>
            <div
              className={classes.iconBox}
              style={{
                backgroundColor: `${accentColor}33`,
                borderColor: `${accentColor}4D`,
              }}
            >
              {icon}
            </div>
            <span className={classes.label} style={{ color: accentColor }}>
              {label}
            </span>
          </div>
          <h1 className={classes.title}>{title}</h1>
          <p className={classes.subtitle}>{subtitle}</p>
          {(primaryAction || secondaryAction) && (
            <div className={classes.actions}>
              {primaryAction && (
                <button
                  className={classes.primaryBtn}
                  style={{ backgroundColor: accentColor }}
                  onClick={primaryAction.onClick}
                >
                  {primaryAction.label}
                </button>
              )}
              {secondaryAction && (
                <button
                  className={classes.secondaryBtn}
                  onClick={secondaryAction.onClick}
                >
                  {secondaryAction.label}
                </button>
              )}
            </div>
          )}
        </div>

        {stats && stats.length > 0 && (
          <div className={classes.statsGrid}>
            {stats.map((stat, i) => (
              <div key={i} className={classes.statCard}>
                <div className={classes.statIcon} style={{ color: stat.color }}>
                  {stat.icon}
                </div>
                <div className={classes.statValue}>{stat.value}</div>
                <div className={classes.statLabel}>{stat.label}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
};
