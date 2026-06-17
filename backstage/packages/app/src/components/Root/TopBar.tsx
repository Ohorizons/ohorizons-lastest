import { useEffect, useState } from 'react';
import { makeStyles, IconButton, Avatar, Typography } from '@material-ui/core';
import AddCircleOutlineIcon from '@material-ui/icons/AddCircleOutline';
import StarBorderIcon from '@material-ui/icons/StarBorder';
import AppsIcon from '@material-ui/icons/Apps';
import NotificationsNoneIcon from '@material-ui/icons/NotificationsNone';
import SearchIcon from '@material-ui/icons/Search';
import SettingsIcon from '@material-ui/icons/Settings';
import { Link, useNavigate } from 'react-router-dom';
import { useApi, githubAuthApiRef } from '@backstage/core-plugin-api';
const useStyles = makeStyles({
  wrapper: {
    position: 'fixed',
    top: 4,
    left: '50%',
    transform: 'translateX(-50%)',
    width: '100%',
    maxWidth: 1600,
    zIndex: 1300,
    display: 'flex',
    flexDirection: 'column',
  },
  stripe: {
    flexShrink: 0,
  },
  topBar: {
    height: 48,
    backgroundColor: 'rgba(247, 249, 255, 0.7)',
    backdropFilter: 'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    borderBottom: '1px solid rgba(192, 199, 212, 0.1)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  topBarInner: {
    display: 'flex',
    alignItems: 'center',
    width: '100%',
    padding: '0 16px',
    gap: 16,
  },
  logoArea: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    textDecoration: 'none',
    flexShrink: 0,
  },
  logoText: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 15,
    fontWeight: 700,
    color: '#171c21',
    letterSpacing: '-0.02em',
    whiteSpace: 'nowrap' as const,
  },
  navLinks: {
    display: 'flex',
    alignItems: 'center',
    gap: 24,
    marginLeft: 24,
  },
  navLink: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 13,
    fontWeight: 500,
    color: '#404752',
    textDecoration: 'none',
    transition: 'color 0.2s',
    '&:hover': {
      color: '#171c21',
    },
  },
  searchWrap: {
    position: 'relative',
    maxWidth: 256,
    flex: 1,
    marginLeft: 16,
  },
  searchIcon: {
    position: 'absolute',
    left: 12,
    top: '50%',
    transform: 'translateY(-50%)',
    color: '#717783',
    fontSize: 16,
  },
  searchInput: {
    width: '100%',
    height: 32,
    borderRadius: 4,
    border: 'none',
    backgroundColor: '#dee3e9',
    padding: '0 12px 0 36px',
    fontSize: 13,
    fontFamily: '"Inter", sans-serif',
    outline: 'none',
    transition: 'all 0.2s',
    '&:focus': {
      borderBottom: '2px solid #0078d4',
      backgroundColor: '#ffffff',
    },
  },
  spacer: {
    flex: 1,
  },
  actions: {
    display: 'flex',
    alignItems: 'center',
    gap: 4,
    flexShrink: 0,
  },
  actionBtn: {
    padding: 6,
    color: '#404752',
    transition: 'all 0.2s',
    '&:hover': {
      color: '#171c21',
      backgroundColor: '#e4e8ef',
    },
  },
  actionIcon: {
    fontSize: 20,
  },
  notifBadge: {
    position: 'relative' as const,
  },
  notifDot: {
    position: 'absolute' as const,
    top: 8,
    right: 8,
    width: 6,
    height: 6,
    borderRadius: '50%',
    backgroundColor: '#ba1a1a',
  },
  divider: {
    height: 32,
    width: 1,
    backgroundColor: 'rgba(192, 199, 212, 0.2)',
    margin: '0 8px',
  },
  userArea: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '4px 8px',
    borderRadius: 8,
    cursor: 'pointer',
    transition: 'background-color 0.2s',
    textDecoration: 'none',
    '&:hover': {
      backgroundColor: '#e4e8ef',
    },
  },
  avatar: {
    width: 28,
    height: 28,
    fontSize: 11,
    fontWeight: 700,
    border: '2px solid #ffffff',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
  },
  userInfo: {
    display: 'flex',
    flexDirection: 'column' as const,
  },
  userName: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 12,
    fontWeight: 700,
    color: '#171c21',
    lineHeight: 1.2,
  },
  userRole: {
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    color: '#717783',
    lineHeight: 1.2,
  },
  logoutBtn: {
    padding: 6,
    color: '#717783',
    marginLeft: 4,
    transition: 'all 0.2s',
    '&:hover': {
      color: '#ba1a1a',
      backgroundColor: 'rgba(186, 26, 26, 0.1)',
    },
  },
});

const TopBar = () => {
  const classes = useStyles();
  const navigate = useNavigate();
  const [displayName, setDisplayName] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');

  let githubAuthApi: any;
  try {
    githubAuthApi = useApi(githubAuthApiRef);
  } catch {
    githubAuthApi = null;
  }

  useEffect(() => {
    if (githubAuthApi) {
      githubAuthApi
        .getProfile?.()
        .then((profile: any) => {
          if (profile?.displayName) setDisplayName(profile.displayName);
          if (profile?.picture) setAvatarUrl(profile.picture);
        })
        .catch(() => {});
    }
  }, [githubAuthApi]);

  return (
    <div className={classes.wrapper}>
      <div className={classes.topBar}>
        <div className={classes.topBarInner}>
          <Link to="/home" className={classes.logoArea}>
            <img src="/logo-msft-github.png" alt="Microsoft + GitHub" style={{ height: 22 }} />
            <span className={classes.logoText}>Open Horizons</span>
          </Link>

          <div className={classes.navLinks}>
            <Link to="/home" className={classes.navLink}>Dashboard</Link>
            <Link to="/catalog" className={classes.navLink}>Catalog</Link>
            <Link to="/docs" className={classes.navLink}>Docs</Link>
          </div>

          <div className={classes.searchWrap}>
            <SearchIcon className={classes.searchIcon} />
            <input
              type="text"
              placeholder="Search resources..."
              className={classes.searchInput}
              onFocus={() => navigate('/search')}
            />
          </div>

          <div className={classes.spacer} />

          <div className={classes.actions}>
            <IconButton className={classes.actionBtn} onClick={() => navigate('/create')} title="Create...">
              <AddCircleOutlineIcon className={classes.actionIcon} />
            </IconButton>
            <IconButton className={classes.actionBtn} onClick={() => navigate('/catalog?filters[starred]=starred')} title="Starred">
              <StarBorderIcon className={classes.actionIcon} />
            </IconButton>
            <IconButton className={classes.actionBtn} onClick={() => navigate('/catalog')} title="Catalog">
              <AppsIcon className={classes.actionIcon} />
            </IconButton>
            <div className={classes.notifBadge}>
              <IconButton className={classes.actionBtn} onClick={() => navigate('/notifications')} title="Notifications">
                <NotificationsNoneIcon className={classes.actionIcon} />
              </IconButton>
              <span className={classes.notifDot} />
            </div>
            <IconButton className={classes.actionBtn} onClick={() => navigate('/settings')} title="Settings">
              <SettingsIcon className={classes.actionIcon} />
            </IconButton>
          </div>

          <div className={classes.divider} />

          <Link to="/settings" className={classes.userArea}>
            <Avatar
              src={avatarUrl}
              alt={displayName}
              className={classes.avatar}
            >
              {!avatarUrl && (displayName?.substring(0, 2).toUpperCase() || 'GH')}
            </Avatar>
            {displayName && (
              <div className={classes.userInfo}>
                <Typography className={classes.userName}>{displayName}</Typography>
                <Typography className={classes.userRole}>GitHub User</Typography>
              </div>
            )}
          </Link>
        </div>
      </div>
    </div>
  );
};

export default TopBar;
