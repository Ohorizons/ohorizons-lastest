import { PropsWithChildren } from 'react';
import { makeStyles, Typography } from '@material-ui/core';
import HomeIcon from '@material-ui/icons/Home';
import CategoryIcon from '@material-ui/icons/Category';
import ExtensionIcon from '@material-ui/icons/Extension';
import LibraryBooks from '@material-ui/icons/LibraryBooks';
import CreateComponentIcon from '@material-ui/icons/AddCircleOutline';
import AssessmentIcon from '@material-ui/icons/Assessment';
import FavoriteIcon from '@material-ui/icons/Favorite';
import ChatIcon from '@material-ui/icons/Chat';
import SecurityIcon from '@material-ui/icons/Security';
import TimelineIcon from '@material-ui/icons/Timeline';
import TrackChangesIcon from '@material-ui/icons/TrackChanges';
import BuildIcon from '@material-ui/icons/Build';
import ScoreIcon from '@material-ui/icons/Score';
import AttachMoneyIcon from '@material-ui/icons/AttachMoney';
// FlashOnIcon removed — logo removed from sidebar
import VerifiedUserIcon from '@material-ui/icons/VerifiedUser';
import ShareIcon from '@material-ui/icons/Share';
import SettingsIcon from '@material-ui/icons/Settings';
import TopBar from './TopBar';

import { Sidebar, SidebarGroup, SidebarItem, SidebarPage, SidebarScrollWrapper, SidebarSpace } from '@backstage/core-components';
import MenuIcon from '@material-ui/icons/Menu';

const useStyles = makeStyles({
  page: {
    position: 'relative',
    margin: '0 auto',
    padding: '54px 0 0',
    boxSizing: 'border-box' as const,
    minHeight: '100vh',
    maxWidth: 1600,
    backgroundColor: '#f7f9ff',
    overflowX: 'hidden' as const,
    '@global': {
      '@import': "url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap')",
      'html, body': {
        overflowX: 'hidden',
        fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
      },
      body: {
        backgroundColor: '#f7f9ff',
      },
      // SidebarPage — keep native layout, constrain to container
      '[class*="BackstageSidebarPage"]': {
        width: '100% !important' as any,
        maxWidth: 'inherit !important' as any,
      },
      // Sidebar root — fixed but aligned to container left edge
      '[data-testid="sidebar-root"]': {
        left: 'max(0px, calc(50vw - 800px)) !important' as any,
        top: '54px !important' as any,
        bottom: '0 !important' as any,
      },
      // Sidebar drawer — dark theme
      '[data-testid="sidebar-root"] > div': {
        backgroundColor: '#2c3136 !important',
        borderRight: 'none !important',
        paddingTop: '16px !important' as any,
        overflowY: 'auto !important' as any,
        overflowX: 'hidden !important' as any,
      },
      // Sidebar items — dark theme styling
      '.MuiListItem-root': {
        borderRadius: '8px !important',
        margin: '1px 8px !important',
        width: 'auto !important',
        transition: 'all 0.2s ease !important',
      },
      '.MuiListItem-root:hover': {
        backgroundColor: 'rgba(255,255,255,0.05) !important',
      },
      // Selected item
      '.MuiListItem-root[class*="selected"], .MuiListItem-root.Mui-selected': {
        backgroundColor: '#0078d4 !important',
        boxShadow: '0 4px 12px rgba(0, 120, 212, 0.3) !important',
      },
      '.MuiListItem-root[class*="selected"] .MuiTypography-root, .MuiListItem-root.Mui-selected .MuiTypography-root': {
        color: '#ffffff !important',
        fontWeight: '900 !important',
      },
      '.MuiListItem-root[class*="selected"] svg, .MuiListItem-root.Mui-selected svg': {
        color: '#ffffff !important',
      },
      // Non-selected items text and icons
      '.MuiDrawer-paper .MuiTypography-root': {
        color: 'rgba(192, 199, 212, 0.6) !important',
        fontFamily: '"Inter", sans-serif !important',
        fontSize: '10px !important',
        textTransform: 'uppercase' as const,
        letterSpacing: '0.1em !important',
        fontWeight: '700 !important',
      },
      '.MuiDrawer-paper svg': {
        color: 'rgba(192, 199, 212, 0.4) !important',
        fontSize: '18px !important',
      },
      // Sidebar indicator
      '.MuiDrawer-paper [class*="indicator"]': {
        backgroundColor: '#0078d4 !important',
      },
      // Kill ALL inner scrollbars — only body scrolls
      'main, [class*="BackstagePage"], [class*="BackstageContent"], [class*="BackstageSidebarPage"]': {
        overflow: 'visible !important' as any,
        overflowY: 'visible !important' as any,
        overflowX: 'hidden !important' as any,
        height: 'auto !important' as any,
        maxHeight: 'none !important' as any,
        minHeight: '0 !important' as any,
      },
      '[class*="BackstageHeader-header"]': {
        position: 'sticky',
        top: 54,
        zIndex: 100,
      },
    },
    '&::before': {
      content: '""',
      position: 'fixed',
      top: 0,
      left: '50%',
      transform: 'translateX(-50%)',
      width: '100%',
      maxWidth: 1600,
      height: 4,
      zIndex: 1400,
      background:
        'linear-gradient(to right, #F25022 0%, #F25022 25%, #7FBA00 25%, #7FBA00 50%, #00A4EF 50%, #00A4EF 75%, #FFB900 75%, #FFB900 100%)',
    },
  },
  sectionLabel: {
    fontSize: '10px !important',
    fontWeight: 900,
    color: 'rgba(192, 199, 212, 0.3) !important',
    letterSpacing: '0.2em !important',
    textTransform: 'uppercase' as const,
    padding: '16px 24px 4px',
    fontFamily: '"Inter", sans-serif !important',
  },
  firstSectionLabel: {
    fontSize: '10px !important',
    fontWeight: 900,
    color: 'rgba(192, 199, 212, 0.3) !important',
    letterSpacing: '0.2em !important',
    textTransform: 'uppercase' as const,
    padding: '24px 24px 4px',
    marginTop: 8,
    fontFamily: '"Inter", sans-serif !important',
  },
  bottomSection: {
    borderTop: '1px solid rgba(255,255,255,0.05)',
    padding: '16px 8px 8px',
    marginTop: 8,
  },
  createBtn: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    width: 'calc(100% - 16px)',
    margin: '0 8px 12px',
    padding: '12px 16px',
    backgroundColor: '#0078d4',
    color: '#ffffff',
    border: 'none',
    borderRadius: 8,
    cursor: 'pointer',
    fontFamily: '"Inter", sans-serif',
    fontSize: 10,
    fontWeight: 900,
    textTransform: 'uppercase' as const,
    letterSpacing: '0.15em',
    boxShadow: '0 4px 12px rgba(0, 120, 212, 0.2)',
    transition: 'all 0.2s ease',
    '&:hover': {
      backgroundColor: '#006cbd',
    },
  },
});

export const Root = ({ children }: PropsWithChildren<{}>) => {
  const classes = useStyles();

  return (
    <div className={classes.page}>
      <TopBar />
      <SidebarPage>
        <Sidebar>
          <SidebarGroup label="Menu" icon={<MenuIcon />}>
            <SidebarItem icon={HomeIcon} to="home" text="Home" />
            <SidebarItem icon={CategoryIcon} to="catalog" text="Catalog" />
            <SidebarItem icon={ExtensionIcon} to="api-docs" text="APIs" />
            <SidebarItem icon={LibraryBooks} to="docs" text="Docs" />
            <SidebarItem icon={CreateComponentIcon} to="create" text="Create" />
            <SidebarItem icon={ShareIcon} to="catalog-graph" text="Graph" />
            <SidebarItem icon={AttachMoneyIcon} to="cost-insights" text="Cost Insights" />
            <SidebarItem icon={VerifiedUserIcon} to="entity-validation" text="Validation" />
          </SidebarGroup>

          <Typography className={classes.sectionLabel}>Platform</Typography>
          <SidebarGroup label="Platform" icon={<AssessmentIcon />}>
            <SidebarItem icon={AssessmentIcon} to="copilot-metrics" text="Copilot Metrics" />
            <SidebarItem icon={TimelineIcon} to="dora-metrics" text="DORA Metrics" />
            <SidebarItem icon={SecurityIcon} to="security" text="Security & Quality" />
            <SidebarItem icon={BuildIcon} to="tech-debt" text="Tech Debt" />
            <SidebarItem icon={FavoriteIcon} to="platform-status" text="Platform Status" />
            <SidebarItem icon={TrackChangesIcon} to="tech-radar" text="Tech Radar" />
            <SidebarItem icon={ScoreIcon} to="tech-insights" text="Tech Insights" />
          </SidebarGroup>

          <Typography className={classes.sectionLabel}>Intelligence</Typography>
          <SidebarGroup label="Intelligence" icon={<ChatIcon />}>
            <SidebarItem icon={ChatIcon} to="ai-chat" text="AI Chat" />
            <SidebarItem icon={AssessmentIcon} to="ai-impact" text="AI Impact" />
            <SidebarScrollWrapper />
          </SidebarGroup>

          <SidebarSpace />

          <div className={classes.bottomSection}>
            <SidebarItem icon={SettingsIcon} to="settings" text="Settings" />
          </div>
        </Sidebar>
        {children}
      </SidebarPage>
    </div>
  );
};
