import { useCallback, useState, useEffect, useRef } from 'react';
import { SignInPageProps, githubAuthApiRef, useApi } from '@backstage/core-plugin-api';
import { UserIdentity } from '@backstage/core-components';
import { Box, Button, CircularProgress, Typography, makeStyles } from '@material-ui/core';

// ─── Constants ───────────────────────────────────────────────────────────────
const VIDEO_URL = '/Open-Horizons-Demo.mp4'; // Local demo video

const EVOLUTIONS = [
  {
    gen: '01', title: 'DevOps', color: '#00A4EF',
    desc: 'CI/CD pipelines, infrastructure automation, containers, and monitoring. Manual decisions and human-triggered deployments.',
  },
  {
    gen: '02', title: 'DevSecOps', color: '#7FBA00',
    desc: 'Security integrated into every pipeline stage. Shift-left testing, compliance as code, GHAS scanning, zero-trust by default.',
  },
  {
    gen: '03', title: 'Agentic DevOps', color: '#FFB900',
    desc: 'AI agents that observe, reason, and act autonomously. Microsoft Agent Framework orchestration, self-healing systems, intelligent deployment decisions.',
  },
];

const HORIZONS = [
  {
    badge: 'H1', title: 'Foundation', color: '#00A4EF',
    desc: 'Enterprise-grade Azure infrastructure with AKS, networking, databases, security, and disaster recovery.',
    tags: ['AKS', 'Terraform', 'Key Vault', 'Networking', 'Defender'],
  },
  {
    badge: 'H2', title: 'Enhancement', color: '#7FBA00',
    desc: 'GitOps with ArgoCD, Backstage as IDP, full observability stack, Golden Paths, and self-hosted runners.',
    tags: ['ArgoCD', 'Backstage', 'Prometheus', 'Grafana', 'Golden Paths'],
  },
  {
    badge: 'H3', title: 'Innovation', color: '#FFB900',
    desc: 'Microsoft Agent Framework with AI agents, MCP servers, RAG applications, and intelligent SDLC automation.',
    tags: ['Agent Framework', 'AI Agents', 'MCP', 'RAG', 'Copilot'],
  },
];

const DIFFERENTIATORS = [
  { icon: '🌐', title: 'Open Source Portal', desc: 'Backstage community as single pane of glass — software catalog, Golden Paths, TechDocs, and AI chat in one place.' },
  { icon: '⚡', title: 'Complete Automation', desc: 'Zero manual steps from Terraform plan to ArgoCD sync. GitOps with App-of-Apps pattern and self-healing.' },
  { icon: '☁️', title: 'Azure Native', desc: 'AKS, Key Vault, Azure Monitor, Workload Identity, Defender for Cloud — cloud-native by design.' },
  { icon: '🤖', title: 'AI-Powered Engineering', desc: 'Microsoft Agent Framework agents, MCP servers, DORA metrics correlation, and intelligent deployment decisions.' },
  { icon: '🚀', title: 'Open Horizons Journey', desc: 'Start with H1 infrastructure, advance through H2 platform engineering, reach H3 AI innovation — at your own pace.' },
  { icon: '🔒', title: 'Security by Default', desc: 'Zero-trust, Workload Identity, GHAS scanning, OPA Gatekeeper, private endpoints — security is never optional.' },
];

const ARCH_LAYERS = [
  { name: 'Application Platform', items: 'AKS · Azure Container Apps · Azure Arc', color: '#00A4EF' },
  { name: 'Agents & Tools', items: 'Microsoft Agent Framework · MCP Servers · Copilot', color: '#0078D4' },
  { name: 'Engineering Systems', items: 'GitHub Platform · Azure DevOps · Azure AI', color: '#005faa' },
  { name: 'Infrastructure as Code', items: 'Terraform · Helm · Bicep', color: '#7FBA00' },
  { name: 'Developer Portal', items: 'Backstage · Templates · Software Catalog', color: '#4CAF50' },
  { name: 'CI/CD & GitOps', items: 'GitHub Actions · ArgoCD · Flux', color: '#FFB900' },
  { name: 'Monitoring & Observability', items: 'Azure Monitor · Prometheus · Grafana · Loki', color: '#FF9800' },
  { name: 'Security & Compliance', items: 'Defender · GHAS · Key Vault · Sentinel · Purview', color: '#F25022' },
];

const TEAMS = [
  {
    title: 'Developer Teams', color: '#00A4EF',
    items: ['Self-service Golden Paths', 'AI-assisted coding with Copilot', 'Inner loop tooling', 'TechDocs & API catalog'],
  },
  {
    title: 'Platform Engineers', color: '#7FBA00',
    items: ['Backstage portal management', 'Terraform modules & GitOps', 'DORA metrics & observability', 'Copilot analytics'],
  },
  {
    title: 'Business Leaders', color: '#FFB900',
    items: ['AI maturity scoring', 'Cost dashboards & optimization', 'Compliance (SOC 2, PCI-DSS, CIS)', 'Measurable DORA improvements'],
  },
];

const FAQ_ITEMS = [
  { q: 'What is Open Horizons?', a: 'Open Horizons is an Agentic DevOps Platform accelerator built on Backstage, deployed on Azure AKS. It provides Golden Path templates, AI agents, and a unified developer portal for the entire SDLC.' },
  { q: 'How do the AI Agents work?', a: 'The agents are built on Microsoft Agent Framework. AI Chat provides conversational SDLC assistance, while AI Impact measures real Agentic DevOps impact with KPIs, score breakdown, and RAG-powered insights.' },
  { q: 'What is the difference between H1, H2, and H3?', a: 'H1 Foundation covers core infrastructure (AKS, networking, security). H2 Enhancement adds platform engineering (ArgoCD, Backstage, observability). H3 Innovation brings AI agents, MCP servers, and intelligent automation.' },
  { q: 'What are Golden Paths?', a: 'Golden Paths are self-service Backstage templates that let developers scaffold new projects following platform standards. We provide 22 templates covering infrastructure, microservices, APIs, AI/ML, and more.' },
  { q: 'How long does deployment take?', a: 'Full deployment takes 75-105 minutes for development environments. You can use agent-guided deployment, automated scripts, or step-by-step manual deployment.' },
  { q: 'How do I connect to the AKS cluster?', a: 'Use `az aks get-credentials --resource-group $RG --name $CLUSTER` to get kubectl access. Ensure your IP is in the authorized ranges if using API server access control.' },
  { q: 'Pods are in CrashLoopBackOff — what do I do?', a: 'Check logs with `kubectl logs <pod> --previous`, verify exit codes, ensure resource limits are adequate, and check liveness probe configuration.' },
  { q: 'How do I get started?', a: 'Fork the repository, configure your Azure credentials and environment variables, then run the automated deployment script. The platform will be ready in under 2 hours.' },
];

const MATURITY_PILLARS = [
  {
    id: 'P1', title: 'Developer Productivity', color: '#0078D4', caps: 8,
    items: ['AI Coding Assistants & Copilot', 'Dev Environment Standardization', 'Code Review Automation', 'Testing & Test Generation', 'Knowledge Management', 'Developer Experience', 'Onboarding & Time to Productivity', 'Code Quality & Technical Debt'],
  },
  {
    id: 'P2', title: 'DevOps Lifecycle', color: '#2E7D32', caps: 10,
    items: ['CI/CD Pipeline Automation', 'Test Automation & Quality Gates', 'Security Scanning & Compliance', 'Release Management & Deployment', 'Observability & Monitoring', 'Incident Response & Management', 'Infrastructure as Code & GitOps', 'DORA Metrics & Performance', 'Agentic DevOps & SRE Automation', 'Deployment Frequency & Velocity'],
  },
  {
    id: 'P3', title: 'Application Platform', color: '#7B1FA2', caps: 10,
    items: ['Cloud Architecture & Infrastructure', 'Platform Engineering & IDP', 'AI/ML Operations (MLOps)', 'Model Evaluation & AI Safety', 'RAG Systems & Knowledge Retrieval', 'AI Agents & Orchestration', 'Data Management & Governance', 'API Management & Service Mesh', 'Disaster Recovery & BC', 'Cost Optimization & FinOps'],
  },
];

const MATURITY_LEVELS = [
  { level: 'L0', name: 'Traditional', color: '#9E9E9E', desc: 'Manual, ad-hoc, no AI tools', width: 15 },
  { level: 'L1', name: 'AI-Assisted', color: '#78909C', desc: 'Piloting AI tools, limited standardization', width: 30 },
  { level: 'L2', name: 'AI-Enhanced', color: '#0288D1', desc: 'Significant AI integration, managed processes', width: 50 },
  { level: 'L3', name: 'AI-Optimized', color: '#2E7D32', desc: 'AI agents, predictive capabilities', width: 70 },
  { level: 'L4', name: 'Agentic', color: '#7B1FA2', desc: 'Multi-agent systems, self-healing, autonomous', width: 90 },
];

const TECH_LOGOS = [
  { name: 'Azure', color: '#0078D4' },
  { name: 'GitHub', color: '#24292E' },
  { name: 'Backstage', color: '#36BAA2' },
  { name: 'Terraform', color: '#7B42BC' },
  { name: 'ArgoCD', color: '#EF7B4D' },
  { name: 'Prometheus', color: '#E6522C' },
  { name: 'Grafana', color: '#F46800' },
  { name: 'Kubernetes', color: '#326CE5' },
];

// ─── Styles ──────────────────────────────────────────────────────────────────
const useStyles = makeStyles({
  '@global': {
    '@import': "url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap')",
    'html': { scrollBehavior: 'smooth' },
  },
  root: {
    width: '100%',
    background: '#F3F2F1',
    color: '#171717',
    overflowX: 'hidden',
    position: 'relative',
    fontFamily: '"Inter", sans-serif',
    scrollBehavior: 'smooth' as const,
    '&::before': {
      content: '""',
      position: 'fixed',
      top: 0,
      left: 0,
      width: '100%',
      height: 4,
      zIndex: 1000,
      background: 'linear-gradient(to right, #F25022 0%, #F25022 25%, #7FBA00 25%, #7FBA00 50%, #00A4EF 50%, #00A4EF 75%, #FFB900 75%, #FFB900 100%)',
    },
  },
  // Scroll reveal
  section: {
    opacity: 0,
    transform: 'translateY(30px)',
    transition: 'opacity 0.6s ease-out, transform 0.6s ease-out',
  },
  sectionVisible: {
    opacity: 1,
    transform: 'translateY(0)',
  },
  container: {
    width: '100%',
    maxWidth: 1100,
    margin: '0 auto',
    padding: '0 24px',
  },

  // ── Navbar ──
  navbar: {
    position: 'fixed' as const, top: 4, left: 0, width: '100%', zIndex: 100,
    display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 32px', height: 56,
    background: 'rgba(243, 242, 241, 0.85)', backdropFilter: 'blur(16px)', WebkitBackdropFilter: 'blur(16px)',
  },
  navInner: { display: 'flex', alignItems: 'center', width: '100%', maxWidth: 1200 },
  navLogo: { height: 28, marginRight: 16 },
  navBrand: { fontWeight: 800, fontSize: 16, color: '#171717', letterSpacing: '-0.02em' },
  navLinks: { display: 'flex', gap: 32, marginLeft: 'auto' },
  navLink: {
    fontSize: 14, fontWeight: 500, color: '#616161', textDecoration: 'none', transition: 'color 0.2s',
    '&:hover': { color: '#171717' },
  },
  navSpacer: { flex: 1 },
  navCta: {
    fontSize: 13, fontWeight: 700, color: '#fff', background: '#24292E', border: 'none',
    padding: '10px 24px', borderRadius: 24, cursor: 'pointer', transition: 'all 0.2s',
    '&:hover': { background: '#1B1F23', transform: 'translateY(-1px)' },
  },

  // ── Hero ──
  hero: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '100px 48px 64px',
    maxWidth: 1200,
    margin: '0 auto',
    gap: 72,
  },
  heroLeft: {
    flex: '0 0 48%',
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'flex-start',
  },
  heroRight: {
    flex: 1,
    display: 'flex',
    alignItems: 'flex-start',
    justifyContent: 'flex-end',
    paddingTop: 16,
  },
  heroLogo: { height: 36, marginBottom: 28 },
  heroTagline: {
    display: 'inline-flex', alignItems: 'center', gap: 8, fontSize: 13, color: '#0078D4', fontWeight: 600,
    letterSpacing: '0.08em', textTransform: 'uppercase' as const, marginBottom: 20,
    padding: '6px 16px', borderRadius: 20, background: 'rgba(0, 120, 212, 0.06)', border: '1px solid rgba(0, 120, 212, 0.12)',
  },
  heroTitle: {
    fontSize: 54, fontWeight: 800, letterSpacing: '-0.03em', color: '#171717',
    marginBottom: 20, lineHeight: 1.1, textAlign: 'left' as const,
  },
  heroAccent: { color: '#0078D4' },
  heroSubtitle: {
    fontSize: 17, color: '#616161', fontWeight: 400, marginBottom: 36,
    lineHeight: 1.75, textAlign: 'left' as const, maxWidth: 440,
  },
  heroBtns: { display: 'flex', gap: 16, marginBottom: 48 },
  signInButton: {
    height: 54, borderRadius: 27, border: 'none', color: '#ffffff', padding: '0 36px',
    fontSize: 16, fontWeight: 700, textTransform: 'none' as const, background: '#24292E',
    boxShadow: '0 4px 20px rgba(0, 0, 0, 0.15)', gap: 10, transition: 'all 0.2s ease',
    '&:hover': { background: '#1B1F23', boxShadow: '0 8px 32px rgba(0, 0, 0, 0.2)', transform: 'translateY(-2px)' },
  },
  heroSecondaryBtn: {
    height: 54, borderRadius: 27, padding: '0 32px', fontSize: 16, fontWeight: 600,
    textTransform: 'none' as const, background: 'transparent', color: '#171717',
    border: '2px solid #E1E1E1', cursor: 'pointer', transition: 'all 0.2s', textDecoration: 'none',
    display: 'inline-flex', alignItems: 'center', gap: 8, fontFamily: '"Inter", sans-serif',
    '&:hover': { borderColor: '#171717', transform: 'translateY(-2px)' },
  },
  heroStats: { display: 'flex', gap: 40 },
  heroStatValue: { fontSize: 32, fontWeight: 900, color: '#0078D4', letterSpacing: '-0.02em', lineHeight: 1 },
  heroStatLabel: { fontSize: 11, fontWeight: 700, color: '#8E8E8E', textTransform: 'uppercase' as const, letterSpacing: '0.12em', marginTop: 6 },
  errorText: { marginTop: 16, color: '#ba1a1a', fontSize: 14, fontWeight: 500 },

  // ── Floating Cards (right side) ──
  floatingMetrics: {
    position: 'absolute' as const, top: 0, right: 0, width: 340,
    background: '#ffffff', borderRadius: 20, padding: '24px 28px',
    boxShadow: '0 20px 60px rgba(0, 0, 0, 0.08), 0 1px 3px rgba(0, 0, 0, 0.04)',
    zIndex: 2,
  },
  fmHeader: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  fmTitle: { fontSize: 15, fontWeight: 700, color: '#171717' },
  fmBadge: { fontSize: 11, fontWeight: 600, color: '#8E8E8E' },
  fmStatsRow: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 20 },
  fmStat: {
    textAlign: 'center' as const, padding: '12px 8px', borderRadius: 12,
    background: '#F8F9FB',
  },
  fmStatLabel: { fontSize: 10, fontWeight: 700, color: '#8E8E8E', textTransform: 'uppercase' as const, letterSpacing: '0.08em' },
  fmStatValue: { fontSize: 22, fontWeight: 800, color: '#171717', marginTop: 4 },
  fmStatTrend: { fontSize: 11, fontWeight: 600, marginTop: 2 },
  fmBars: { display: 'flex', alignItems: 'flex-end', gap: 8, height: 64 },
  fmBar: { flex: 1, borderRadius: '6px 6px 0 0', transition: 'height 0.5s ease' },

  // ── Terminal Animation ──
  terminal: {
    width: '100%', maxWidth: 480, borderRadius: 16, overflow: 'hidden',
    boxShadow: '0 24px 64px rgba(0, 0, 0, 0.12), 0 2px 6px rgba(0, 0, 0, 0.04)',
    fontFamily: '"Cascadia Code", "Fira Code", "Consolas", monospace',
  },
  termHeader: {
    background: '#2c3136', padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 8,
  },
  termDot: { width: 12, height: 12, borderRadius: '50%' },
  termTitle: { fontSize: 12, color: 'rgba(255,255,255,0.5)', marginLeft: 8, fontFamily: '"Inter", sans-serif', fontWeight: 600 },
  termBody: {
    background: '#1e1e1e', padding: '16px 18px 20px', fontSize: 12, lineHeight: 1.9, color: '#d4d4d4', minHeight: 160,
  },
  termLine: { whiteSpace: 'pre' as const },
  termPrompt: { color: '#7FBA00' },
  termAgent: { color: '#00A4EF', fontWeight: 700 },
  termCmd: { color: '#d4d4d4' },
  termOutput: { color: '#8E8E8E' },
  termSuccess: { color: '#7FBA00' },
  termCursor: {
    display: 'inline-block', width: 8, height: 16, background: '#d4d4d4', marginLeft: 2,
    animation: '$blink 1s step-end infinite', verticalAlign: 'text-bottom',
  },
  '@keyframes blink': {
    '0%, 100%': { opacity: 1 },
    '50%': { opacity: 0 },
  },

  // ── Video Player Chrome ──
  videoPlayerChrome: {
    width: '100%', maxWidth: 1080, margin: '0 auto', borderRadius: 12, overflow: 'hidden',
    boxShadow: '0 24px 80px rgba(0, 0, 0, 0.22), 0 8px 24px rgba(0, 0, 0, 0.10)',
    background: '#1e1e1e', border: '1px solid rgba(255,255,255,0.06)',
  },
  videoPlayerTitleBar: {
    display: 'flex', alignItems: 'center', height: 36, padding: '0 12px',
    background: '#2b2b2b', borderBottom: '1px solid rgba(255,255,255,0.06)',
    gap: 8,
  },
  videoPlayerDot: {
    width: 10, height: 10, borderRadius: '50%', display: 'inline-block',
  },
  videoPlayerTitle: {
    flex: 1, textAlign: 'center' as const, fontSize: 12, fontWeight: 500,
    color: 'rgba(255,255,255,0.5)', letterSpacing: '0.02em',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
  },
  videoWrap: {
    width: '100%', background: '#000',
  },
  videoIframe: { width: '100%', height: 'auto', border: 'none', display: 'block' },
  videoPlayerControls: {
    display: 'flex', alignItems: 'center', height: 40, padding: '0 16px',
    background: '#2b2b2b', borderTop: '1px solid rgba(255,255,255,0.06)',
    gap: 12,
  },
  videoPlayerProgressTrack: {
    flex: 1, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.12)', overflow: 'hidden',
  },
  videoPlayerProgressFill: {
    width: '35%', height: '100%', borderRadius: 2,
    background: 'linear-gradient(90deg, #ff6611 0%, #ff8833 100%)',
  },
  videoPlayerTime: {
    fontSize: 11, fontWeight: 500, color: 'rgba(255,255,255,0.45)',
    fontFamily: 'SF Mono, Menlo, monospace', letterSpacing: '0.03em',
  },
  videoPlayerIcon: {
    width: 16, height: 16, opacity: 0.45, cursor: 'default',
  },
  videoPlaceholder: {
    width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center',
    background: 'linear-gradient(135deg, #2c3136 0%, #171c21 100%)', color: '#ffffff', fontSize: 48,
    aspectRatio: '1920/1168',
  },

  // ── Stats ──
  statsSection: { padding: '80px 24px', background: '#ffffff' },
  statsGrid: { display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 32, textAlign: 'center' },
  statValue: { fontSize: 48, fontWeight: 900, letterSpacing: '-0.02em', lineHeight: 1 },
  statLabel: { fontSize: 13, fontWeight: 600, color: '#616161', marginTop: 8, textTransform: 'uppercase' as const, letterSpacing: '0.1em' },

  // ── Section titles ──
  sectionTitle: { fontSize: 40, fontWeight: 800, letterSpacing: '-0.02em', color: '#171717', textAlign: 'center', marginBottom: 8 },
  sectionSubtitle: { fontSize: 16, color: '#616161', textAlign: 'center', marginBottom: 48, maxWidth: 600, margin: '0 auto 48px' },

  // ── Evolution ──
  evoSection: { padding: '80px 24px' },
  evoGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, maxWidth: 1100, margin: '0 auto' },
  evoCard: {
    background: '#ffffff', borderRadius: 16, padding: '32px 24px', transition: 'all 0.3s ease',
    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 16px 48px rgba(0, 0, 0, 0.1)' },
  },
  evoGen: { fontSize: 12, fontWeight: 800, letterSpacing: '0.15em', textTransform: 'uppercase' as const, marginBottom: 8 },
  evoTitle: { fontSize: 24, fontWeight: 800, color: '#171717', marginBottom: 12 },
  evoDesc: { fontSize: 14, color: '#616161', lineHeight: 1.7 },

  // ── Horizons ──
  hzSection: { padding: '80px 24px', background: '#ffffff' },
  hzGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, maxWidth: 1100, margin: '0 auto' },
  hzCard: {
    borderRadius: 16, padding: '32px 24px', background: '#F3F2F1', transition: 'all 0.3s ease',
    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 12px 32px rgba(0, 0, 0, 0.08)' },
  },
  hzBadge: {
    width: 44, height: 44, borderRadius: '50%', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    color: '#fff', fontSize: 18, fontWeight: 800, marginBottom: 16,
  },
  hzTitle: { fontSize: 22, fontWeight: 800, color: '#171717', marginBottom: 8 },
  hzDesc: { fontSize: 14, color: '#616161', lineHeight: 1.7, marginBottom: 16 },
  hzTags: { display: 'flex', flexWrap: 'wrap' as const, gap: 8 },
  hzTag: { fontSize: 11, fontWeight: 700, padding: '4px 10px', borderRadius: 20, letterSpacing: '0.03em' },

  // ── Agentic Intelligence ──
  aiSection: { padding: '80px 24px' },
  aiGrid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 32, maxWidth: 1100, margin: '0 auto' },
  aiCard: {
    background: '#ffffff', borderRadius: 16, padding: '40px 32px', transition: 'all 0.3s ease',
    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 16px 48px rgba(0, 0, 0, 0.1)' },
  },
  aiIcon: { fontSize: 40, marginBottom: 16 },
  aiTitle: { fontSize: 22, fontWeight: 800, color: '#171717', marginBottom: 8 },
  aiDesc: { fontSize: 14, color: '#616161', lineHeight: 1.7 },
  aiBadge: { display: 'inline-block', fontSize: 11, fontWeight: 700, padding: '4px 12px', borderRadius: 20, marginTop: 16 },

  // ── AI Maturity ──
  matSection: { padding: '80px 24px', background: '#ffffff' },
  matPillars: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, maxWidth: 1100, margin: '0 auto 40px' },
  matPillar: {
    borderRadius: 16, padding: '24px 20px', color: '#fff', transition: 'all 0.3s ease',
    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 12px 32px rgba(0,0,0,0.15)' },
  },
  matPillarId: { fontSize: 13, fontWeight: 900, opacity: 0.7, marginBottom: 4 },
  matPillarTitle: { fontSize: 18, fontWeight: 800, marginBottom: 4 },
  matPillarCaps: { fontSize: 12, fontWeight: 600, opacity: 0.7 },
  matPillarItems: { marginTop: 16, display: 'flex', flexDirection: 'column' as const, gap: 4 },
  matPillarItem: { fontSize: 12, fontWeight: 500, opacity: 0.85, paddingLeft: 12, position: 'relative' as const, '&::before': { content: '"›"', position: 'absolute' as const, left: 0, opacity: 0.5 } },
  matLevels: { maxWidth: 800, margin: '0 auto', display: 'flex', flexDirection: 'column' as const, gap: 8 },
  matLevel: {
    display: 'flex', alignItems: 'center', gap: 16, padding: '14px 20px',
    borderRadius: 12, background: '#F8F9FB', transition: 'all 0.3s ease',
    '&:hover': { background: '#F0F4FB', transform: 'translateX(4px)' },
  },
  matLevelBadge: {
    width: 36, height: 36, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
    color: '#fff', fontSize: 13, fontWeight: 800, flexShrink: 0,
  },
  matLevelName: { fontSize: 16, fontWeight: 800, color: '#171717', minWidth: 130 },
  matLevelDesc: { fontSize: 13, color: '#616161', flex: 1 },
  matLevelBar: { height: 8, borderRadius: 4, flexShrink: 0 },

  // ── Differentiators ──
  diffSection: { padding: '80px 24px', background: '#ffffff' },
  diffGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, maxWidth: 1100, margin: '0 auto' },
  diffCard: {
    borderRadius: 16, padding: '32px 24px', background: '#F3F2F1', transition: 'all 0.3s ease',
    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 12px 32px rgba(0, 0, 0, 0.08)' },
  },
  diffIcon: { fontSize: 32, marginBottom: 16 },
  diffTitle: { fontSize: 18, fontWeight: 800, color: '#171717', marginBottom: 8 },
  diffDesc: { fontSize: 14, color: '#616161', lineHeight: 1.7 },

  // ── Architecture ──
  archSection: { padding: '80px 24px' },
  archStack: { maxWidth: 800, margin: '0 auto', display: 'flex', flexDirection: 'column' as const, gap: 4 },
  archLayer: {
    display: 'flex', alignItems: 'center', padding: '16px 24px', borderRadius: 12, color: '#ffffff',
    transition: 'all 0.3s ease',
    '&:hover': { transform: 'scale(1.02)', boxShadow: '0 8px 24px rgba(0, 0, 0, 0.15)' },
  },
  archName: { fontSize: 15, fontWeight: 800, minWidth: 220 },
  archItems: { fontSize: 13, fontWeight: 500, opacity: 0.9 },

  // ── Teams ──
  teamsSection: { padding: '80px 24px', background: '#ffffff' },
  teamsGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, maxWidth: 1100, margin: '0 auto' },
  teamCard: {
    borderRadius: 16, padding: '32px 24px', background: '#F3F2F1', transition: 'all 0.3s ease',
    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 12px 32px rgba(0, 0, 0, 0.08)' },
  },
  teamTitle: { fontSize: 20, fontWeight: 800, marginBottom: 16 },
  teamItem: { fontSize: 14, color: '#616161', lineHeight: 2, paddingLeft: 16, position: 'relative' as const, '&::before': { content: '"→"', position: 'absolute' as const, left: 0, color: '#8E8E8E' } },

  // ── FAQ ──
  faqSection: { padding: '80px 24px' },
  faqList: { maxWidth: 800, margin: '0 auto' },
  faqItem: { borderBottom: '1px solid #E1E1E1', overflow: 'hidden' },
  faqQuestion: {
    width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    padding: '20px 0', background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left' as const,
    fontFamily: '"Inter", sans-serif', fontSize: 16, fontWeight: 700, color: '#171717', transition: 'color 0.2s',
    '&:hover': { color: '#0078D4' },
  },
  faqArrow: { fontSize: 20, color: '#8E8E8E', transition: 'transform 0.3s' },
  faqArrowOpen: { transform: 'rotate(180deg)' },
  faqAnswer: { fontSize: 14, color: '#616161', lineHeight: 1.7, padding: '0 0 20px', maxHeight: 0, overflow: 'hidden', transition: 'max-height 0.3s ease, padding 0.3s ease' },
  faqAnswerOpen: { maxHeight: 300, padding: '0 0 20px' },

  // ── Tech Logos ──
  techSection: { padding: '48px 24px', background: '#ffffff' },
  techGrid: { display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 40, flexWrap: 'wrap' as const },
  techBadge: { fontSize: 14, fontWeight: 800, padding: '8px 20px', borderRadius: 24, color: '#ffffff', letterSpacing: '0.03em' },

  // ── Getting Started ──
  gsSection: { padding: '80px 24px' },
  gsGrid: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, maxWidth: 1100, margin: '0 auto' },
  gsCard: {
    background: '#ffffff', borderRadius: 16, padding: '40px 24px', textAlign: 'center' as const, transition: 'all 0.3s ease',
    '&:hover': { transform: 'translateY(-4px)', boxShadow: '0 12px 32px rgba(0, 0, 0, 0.1)' },
  },
  gsNumber: { width: 56, height: 56, borderRadius: '50%', background: '#0078D4', color: '#fff', fontSize: 24, fontWeight: 900, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 20 },
  gsTitle: { fontSize: 20, fontWeight: 800, color: '#171717', marginBottom: 8 },
  gsDesc: { fontSize: 14, color: '#616161', lineHeight: 1.7 },

  // ── CTA Footer ──
  ctaSection: { padding: '80px 24px', background: '#2c3136', textAlign: 'center' as const },
  ctaTitle: { fontSize: 32, fontWeight: 800, color: '#ffffff', marginBottom: 8 },
  ctaSub: { fontSize: 14, color: 'rgba(255,255,255,0.6)', marginBottom: 32 },
  ctaBtns: { display: 'flex', justifyContent: 'center', gap: 16, flexWrap: 'wrap' as const },
  ctaBtn: {
    padding: '14px 28px', borderRadius: 28, fontSize: 14, fontWeight: 700, textDecoration: 'none', transition: 'all 0.2s',
    '&:hover': { transform: 'translateY(-2px)' },
  },
  ctaPrimary: { background: '#0078D4', color: '#fff', border: 'none', cursor: 'pointer', '&:hover': { background: '#005faa', transform: 'translateY(-2px)' } },
  ctaOutline: { background: 'transparent', color: '#fff', border: '2px solid rgba(255,255,255,0.3)', cursor: 'pointer', '&:hover': { borderColor: '#fff', transform: 'translateY(-2px)' } },
  footer: { fontSize: 12, color: 'rgba(255,255,255,0.4)', fontWeight: 500, letterSpacing: '0.05em', marginTop: 48 },
  backToTop: {
    display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 32,
    fontSize: 13, fontWeight: 600, color: 'rgba(255,255,255,0.5)', background: 'none', border: 'none',
    cursor: 'pointer', fontFamily: '"Inter", sans-serif', transition: 'color 0.2s',
    '&:hover': { color: '#ffffff' },
  },
  // ── Bottom Footer ──
  bottomFooter: {
    background: '#F8F9FB', borderTop: '1px solid #E1E1E1', padding: '20px 24px',
  },
  bottomFooterInner: {
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    maxWidth: 1200, margin: '0 auto', width: '100%',
  },
  bottomFooterLeft: {
    display: 'flex', alignItems: 'center', gap: 12,
  },
  bottomFooterLogo: { height: 20, opacity: 0.6 },
  bottomFooterText: { fontSize: 12, color: '#8E8E8E', fontWeight: 400 },
  bottomFooterRight: { fontSize: 12, color: '#8E8E8E', fontWeight: 400 },
  bottomFooterLink: { color: '#0078D4', textDecoration: 'none', fontWeight: 600, '&:hover': { textDecoration: 'underline' } },

  '@keyframes fadeIn': {
    from: { opacity: 0, transform: 'translateY(20px)' },
    to: { opacity: 1, transform: 'translateY(0)' },
  },
  heroAnim: { animation: '$fadeIn 0.6s ease-out' },
});

// ─── GitHub Icon ─────────────────────────────────────────────────────────────
const GitHubIcon = ({ size = 24 }: { size?: number }) => (
  <svg viewBox="0 0 24 24" fill="currentColor" width={size} height={size} aria-hidden>
    <path d="M12 0C5.373 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.6.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.51 11.51 0 0112 5.8c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.431.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.8 24 17.302 24 12c0-6.627-5.373-12-12-12z" />
  </svg>
);

// ─── Component ───────────────────────────────────────────────────────────────
const CustomSignInPage = ({ onSignInSuccess }: SignInPageProps) => {
  const classes = useStyles();
  const githubAuthApi = useApi(githubAuthApiRef);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | undefined>();
  const [openFaq, setOpenFaq] = useState<number | null>(null);
  const [termLines, setTermLines] = useState<number>(0);
  const sectionsRef = useRef<(HTMLDivElement | null)[]>([]);

  const TERM_LINES = [
    { type: 'prompt', text: '$ @deploy platform --env prod' },
    { type: 'output', text: '  Initializing deployment agent...' },
    { type: 'agent', text: '  @deploy → Provisioning AKS cluster' },
    { type: 'output', text: '  Applying 16 Terraform modules...' },
    { type: 'output', text: '  Key Vault, Networking, Defender...' },
    { type: 'success', text: '  ✓ H1 Foundation — 32m 14s' },
    { type: 'agent', text: '  @deploy → H2 Enhancement' },
    { type: 'output', text: '  ArgoCD, Backstage, Prometheus' },
    { type: 'output', text: '  Loading 22 Golden Path templates' },
    { type: 'success', text: '  ✓ H2 Enhancement — 28m 47s' },
    { type: 'agent', text: '  @deploy → H3 Innovation' },
    { type: 'output', text: '  AI Agents, MCP Servers, RAG' },
    { type: 'success', text: '  ✓ H3 Innovation — 18m 22s' },
    { type: 'success', text: '  ✓ Ready → ohorizons.ai' },
  ];

  // Terminal typing animation
  useEffect(() => {
    if (termLines < TERM_LINES.length) {
      const delay = TERM_LINES[termLines]?.type === 'prompt' ? 1200 : termLines === 0 ? 800 : 600 + Math.random() * 400;
      const timer = setTimeout(() => setTermLines(l => l + 1), delay);
      return () => clearTimeout(timer);
    }
    // Loop
    const restart = setTimeout(() => setTermLines(0), 4000);
    return () => clearTimeout(restart);
  }, [termLines, TERM_LINES.length]);

  // Scroll reveal
  useEffect(() => {
    const observer = new IntersectionObserver(
      entries => entries.forEach(e => { if (e.isIntersecting) e.target.classList.add(classes.sectionVisible); }),
      { threshold: 0.1 },
    );
    sectionsRef.current.forEach(el => el && observer.observe(el));
    return () => observer.disconnect();
  }, [classes.sectionVisible]);

  const setSectionRef = (i: number) => (el: HTMLDivElement | null) => { sectionsRef.current[i] = el; };

  const handleSignIn = useCallback(async () => {
    try {
      setError(undefined);
      setLoading(true);
      const identityResponse = await githubAuthApi.getBackstageIdentity({ instantPopup: true });
      if (!identityResponse) throw new Error('Could not resolve Backstage identity from GitHub sign-in');
      const profile = await githubAuthApi.getProfile();
      onSignInSuccess(UserIdentity.create({ identity: identityResponse.identity, profile, authApi: githubAuthApi }));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'GitHub sign-in failed');
    } finally {
      setLoading(false);
    }
  }, [githubAuthApi, onSignInSuccess]);

  return (
    <Box className={classes.root}>
      {/* ── Navbar ── */}
      <div className={classes.navbar}>
        <div className={classes.navInner}>
          <img src="/logo-msft-github.png" alt="Microsoft + GitHub" className={classes.navLogo} />
          <span className={classes.navBrand}>Open Horizons</span>
          <div className={classes.navLinks}>
            <a href="#platform" className={classes.navLink}>Platform</a>
            <a href="#differentiators" className={classes.navLink}>Differentiators</a>
            <a href="#architecture" className={classes.navLink}>Architecture</a>
            <a href="#faq" className={classes.navLink}>FAQ</a>
          </div>
        </div>
      </div>

      {/* ── Hero (split layout) ── */}
      <div className={`${classes.hero} ${classes.heroAnim}`}>
        <div className={classes.heroLeft}>
          <div className={classes.heroTagline}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#7FBA00' }} />
            Agentic DevOps Platform — Open Horizons
          </div>
          <Typography component="h1" className={classes.heroTitle}>
            The platform that<br />accelerates the<br /><span className={classes.heroAccent}>Agentic SDLC</span>
          </Typography>
          <Typography className={classes.heroSubtitle}>
            AI-powered developer portal with Golden Paths, intelligent agents, and full observability — built on Backstage, Azure, and GitHub.
          </Typography>

          <div className={classes.heroBtns}>
            <Button className={classes.signInButton} onClick={handleSignIn} disabled={loading}
              startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <GitHubIcon size={20} />}>
              {loading ? 'Authenticating...' : 'Sign in with GitHub'}
            </Button>
            <a href="#platform" className={classes.heroSecondaryBtn}>
              Explore Platform →
            </a>
          </div>
          {error && <Typography className={classes.errorText}>{error}</Typography>}

          <div className={classes.heroStats}>
            {[
              { value: '22', label: 'Golden Paths' },
              { value: '17', label: 'AI Agents' },
              { value: '15', label: 'MCP Servers' },
              { value: 'AI', label: 'Insights' },
            ].map(s => (
              <div key={s.label}>
                <div className={classes.heroStatValue}>{s.value}</div>
                <div className={classes.heroStatLabel}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>

        <div className={classes.heroRight}>
          <div className={classes.terminal}>
            <div className={classes.termHeader}>
              <div className={classes.termDot} style={{ background: '#FF5F56' }} />
              <div className={classes.termDot} style={{ background: '#FFBD2E' }} />
              <div className={classes.termDot} style={{ background: '#27C93F' }} />
              <span className={classes.termTitle}>GitHub Copilot CLI — @deploy agent</span>
            </div>
            <div className={classes.termBody}>
              {TERM_LINES.slice(0, termLines).map((line, i) => (
                <div key={i} className={classes.termLine}>
                  <span className={
                    line.type === 'prompt' ? classes.termPrompt :
                    line.type === 'agent' ? classes.termAgent :
                    line.type === 'success' ? classes.termSuccess :
                    classes.termOutput
                  }>{line.text}</span>
                </div>
              ))}
              {termLines < TERM_LINES.length && <span className={classes.termCursor} />}
            </div>
          </div>
        </div>
      </div>

      {/* ── Evolution ── */}
      <div id="platform" className={`${classes.evoSection} ${classes.section}`} ref={setSectionRef(1)}>
        <Typography className={classes.sectionTitle}>The Evolution of DevOps</Typography>
        <Typography className={classes.sectionSubtitle}>From manual pipelines to autonomous AI agents — three generations of engineering excellence.</Typography>
        <div className={classes.evoGrid}>
          {EVOLUTIONS.map(e => (
            <div key={e.gen} className={classes.evoCard} style={{ borderTop: `4px solid ${e.color}` }}>
              <div className={classes.evoGen} style={{ color: e.color }}>Generation {e.gen}</div>
              <div className={classes.evoTitle}>{e.title}</div>
              <div className={classes.evoDesc}>{e.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* ── Video ── */}
      <div className={`${classes.section}`} ref={setSectionRef(10)} style={{ padding: '80px 24px', background: 'linear-gradient(180deg, #f8f9fa 0%, #ffffff 100%)' }}>
        <div className={classes.videoPlayerChrome}>
          {/* Title bar */}
          <div className={classes.videoPlayerTitleBar}>
            <span className={classes.videoPlayerDot} style={{ background: '#ff5f57' }} />
            <span className={classes.videoPlayerDot} style={{ background: '#febc2e' }} />
            <span className={classes.videoPlayerDot} style={{ background: '#28c840' }} />
            <span className={classes.videoPlayerTitle}>Open Horizons — Agentic DevOps Platform Demo</span>
            <span style={{ width: 38 }} />
          </div>
          {/* Video */}
          <div className={classes.videoWrap}>
            {VIDEO_URL ? (
              <video className={classes.videoIframe} src={VIDEO_URL} autoPlay loop muted playsInline />
            ) : (
              <div className={classes.videoPlaceholder}>▶</div>
            )}
          </div>
          {/* Controls bar */}
          <div className={classes.videoPlayerControls}>
            <svg className={classes.videoPlayerIcon} viewBox="0 0 24 24" fill="white"><path d="M8 5v14l11-7z"/></svg>
            <svg className={classes.videoPlayerIcon} viewBox="0 0 24 24" fill="white"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
            <span className={classes.videoPlayerTime}>0:35</span>
            <div className={classes.videoPlayerProgressTrack}>
              <div className={classes.videoPlayerProgressFill} />
            </div>
            <span className={classes.videoPlayerTime}>1:51</span>
            <svg className={classes.videoPlayerIcon} viewBox="0 0 24 24" fill="white"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0 0 14 8.5v7a4.47 4.47 0 0 0 2.5-3.5zM14 3.23v2.06A6.99 6.99 0 0 1 19 12a6.99 6.99 0 0 1-5 6.71v2.06A9.01 9.01 0 0 0 21 12a9.01 9.01 0 0 0-7-8.77z"/></svg>
            <svg className={classes.videoPlayerIcon} viewBox="0 0 24 24" fill="white"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>
          </div>
        </div>
      </div>

      {/* ── Horizons ── */}
      <div className={`${classes.hzSection} ${classes.section}`} ref={setSectionRef(2)}>
        <Typography className={classes.sectionTitle}>The Open Horizons Model</Typography>
        <Typography className={classes.sectionSubtitle}>A structured maturity journey from foundational infrastructure to AI-powered innovation.</Typography>
        <div className={classes.hzGrid}>
          {HORIZONS.map(h => (
            <div key={h.badge} className={classes.hzCard} style={{ borderTop: `4px solid ${h.color}` }}>
              <div className={classes.hzBadge} style={{ background: h.color }}>{h.badge}</div>
              <div className={classes.hzTitle}>{h.title}</div>
              <div className={classes.hzDesc}>{h.desc}</div>
              <div className={classes.hzTags}>
                {h.tags.map(t => (
                  <span key={t} className={classes.hzTag} style={{ background: `${h.color}20`, color: h.color }}>{t}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── Agentic Intelligence ── */}
      <div className={`${classes.aiSection} ${classes.section}`} ref={setSectionRef(3)}>
        <Typography className={classes.sectionTitle}>Agentic Intelligence</Typography>
        <Typography className={classes.sectionSubtitle}>AI-powered agents built on Microsoft Agent Framework, integrated directly into your developer portal.</Typography>
        <div className={classes.aiGrid}>
          <div className={classes.aiCard}>
            <div className={classes.aiIcon}>💬</div>
            <div className={classes.aiTitle}>AI Chat</div>
            <div className={classes.aiDesc}>
              Conversational AI assistant for your entire SDLC. Get context-aware answers about your infrastructure, pipelines,
              services, and platform — powered by Microsoft Agent Framework with full GitHub and Azure integration.
            </div>
            <span className={classes.aiBadge} style={{ background: '#00A4EF20', color: '#00A4EF' }}>Microsoft Agent Framework</span>
          </div>
          <div className={classes.aiCard}>
            <div className={classes.aiIcon}>📊</div>
            <div className={classes.aiTitle}>AI Impact</div>
            <div className={classes.aiDesc}>
              Measure the real impact of Agentic DevOps on your SDLC. KPI dashboards, score breakdowns, RAG-powered insights,
              and on-demand analysis — understand how AI agents are accelerating your engineering outcomes.
            </div>
            <span className={classes.aiBadge} style={{ background: '#7FBA0020', color: '#7FBA00' }}>Impact Analytics</span>
          </div>
        </div>
      </div>

      {/* ── AI Maturity Framework ── */}
      <div className={`${classes.matSection} ${classes.section}`} ref={setSectionRef(11)}>
        <Typography className={classes.sectionTitle}>AI Maturity Framework</Typography>
        <Typography className={classes.sectionSubtitle}>28 capabilities across 3 pillars measuring AI adoption in software delivery — from Traditional (L0) to Agentic (L4).</Typography>

        <div className={classes.matPillars}>
          {MATURITY_PILLARS.map(p => (
            <div key={p.id} className={classes.matPillar} style={{ background: p.color }}>
              <div className={classes.matPillarId}>{p.id}</div>
              <div className={classes.matPillarTitle}>{p.title}</div>
              <div className={classes.matPillarCaps}>{p.caps} Capabilities</div>
              <div className={classes.matPillarItems}>
                {p.items.map(item => (
                  <div key={item} className={classes.matPillarItem}>{item}</div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className={classes.matLevels}>
          {MATURITY_LEVELS.map(l => (
            <div key={l.level} className={classes.matLevel}>
              <div className={classes.matLevelBadge} style={{ background: l.color }}>{l.level}</div>
              <span className={classes.matLevelName}>{l.name}</span>
              <span className={classes.matLevelDesc}>{l.desc}</span>
              <div className={classes.matLevelBar} style={{ width: `${l.width}px`, background: l.color }} />
            </div>
          ))}
        </div>
      </div>

      {/* ── Differentiators ── */}
      <div id="differentiators" className={`${classes.diffSection} ${classes.section}`} ref={setSectionRef(4)}>
        <Typography className={classes.sectionTitle}>Key Differentiators</Typography>
        <Typography className={classes.sectionSubtitle}>What makes Open Horizons unique in the Agentic DevOps landscape.</Typography>
        <div className={classes.diffGrid}>
          {DIFFERENTIATORS.map(d => (
            <div key={d.title} className={classes.diffCard}>
              <div className={classes.diffIcon}>{d.icon}</div>
              <div className={classes.diffTitle}>{d.title}</div>
              <div className={classes.diffDesc}>{d.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* ── Architecture ── */}
      <div id="architecture" className={`${classes.archSection} ${classes.section}`} ref={setSectionRef(5)}>
        <Typography className={classes.sectionTitle}>Architecture Layers</Typography>
        <Typography className={classes.sectionSubtitle}>Eight composable layers from security foundations to application platform.</Typography>
        <div className={classes.archStack}>
          {ARCH_LAYERS.map(l => (
            <div key={l.name} className={classes.archLayer} style={{ background: l.color }}>
              <span className={classes.archName}>{l.name}</span>
              <span className={classes.archItems}>{l.items}</span>
            </div>
          ))}
        </div>
      </div>

      {/* ── Teams ── */}
      <div className={`${classes.teamsSection} ${classes.section}`} ref={setSectionRef(6)}>
        <Typography className={classes.sectionTitle}>Built for Every Team</Typography>
        <Typography className={classes.sectionSubtitle}>From individual developers to business leaders — Open Horizons serves the entire organization.</Typography>
        <div className={classes.teamsGrid}>
          {TEAMS.map(t => (
            <div key={t.title} className={classes.teamCard} style={{ borderTop: `4px solid ${t.color}` }}>
              <div className={classes.teamTitle}>{t.title}</div>
              {t.items.map(item => (
                <div key={item} className={classes.teamItem}>{item}</div>
              ))}
            </div>
          ))}
        </div>
      </div>

      {/* ── FAQ ── */}
      <div id="faq" className={`${classes.faqSection} ${classes.section}`} ref={setSectionRef(7)}>
        <Typography className={classes.sectionTitle}>Frequently Asked Questions</Typography>
        <Typography className={classes.sectionSubtitle}>Everything you need to know about the Open Horizons platform.</Typography>
        <div className={classes.faqList}>
          {FAQ_ITEMS.map((faq, i) => (
            <div key={i} className={classes.faqItem}>
              <button className={classes.faqQuestion} onClick={() => setOpenFaq(openFaq === i ? null : i)}>
                {faq.q}
                <span className={`${classes.faqArrow} ${openFaq === i ? classes.faqArrowOpen : ''}`}>▼</span>
              </button>
              <div className={`${classes.faqAnswer} ${openFaq === i ? classes.faqAnswerOpen : ''}`}>{faq.a}</div>
            </div>
          ))}
        </div>
      </div>

      {/* ── Tech Logos ── */}
      <div className={`${classes.techSection} ${classes.section}`} ref={setSectionRef(8)}>
        <div className={classes.techGrid}>
          {TECH_LOGOS.map(t => (
            <span key={t.name} className={classes.techBadge} style={{ background: t.color }}>{t.name}</span>
          ))}
        </div>
      </div>

      {/* ── Getting Started ── */}
      <div className={`${classes.gsSection} ${classes.section}`} ref={setSectionRef(9)}>
        <Typography className={classes.sectionTitle}>Get Started in 3 Steps</Typography>
        <Typography className={classes.sectionSubtitle}>From zero to a fully operational Agentic DevOps platform in under 2 hours.</Typography>
        <div className={classes.gsGrid}>
          {[
            { n: '1', title: 'Fork', desc: 'Clone the Open Horizons repository from GitHub and configure your environment variables.' },
            { n: '2', title: 'Configure', desc: 'Set up your Azure credentials, GitHub App, and customize the platform for your organization.' },
            { n: '3', title: 'Deploy', desc: 'Run the automated deployment script. Your full platform will be ready in 75-105 minutes.' },
          ].map(s => (
            <div key={s.n} className={classes.gsCard}>
              <div className={classes.gsNumber}>{s.n}</div>
              <div className={classes.gsTitle}>{s.title}</div>
              <div className={classes.gsDesc}>{s.desc}</div>
            </div>
          ))}
        </div>
      </div>

      {/* ── CTA Footer ── */}
      <div className={classes.ctaSection}>
        <Typography className={classes.ctaTitle}>Ready to Transform Your SDLC?</Typography>
        <Typography className={classes.ctaSub}>Deploy Open Horizons and bring Agentic DevOps to your organization.</Typography>
        <div className={classes.ctaBtns}>
          <a href="https://github.com/Ohorizons/open-horizons-platform" target="_blank" rel="noopener noreferrer"
            className={`${classes.ctaBtn} ${classes.ctaPrimary}`}>Deploy Now</a>
          <a href="https://github.com/Ohorizons/open-horizons-platform#readme" target="_blank" rel="noopener noreferrer"
            className={`${classes.ctaBtn} ${classes.ctaOutline}`}>Documentation</a>
          <a href="https://github.com/Ohorizons/open-horizons-platform" target="_blank" rel="noopener noreferrer"
            className={`${classes.ctaBtn} ${classes.ctaOutline}`}>GitHub Repository</a>
        </div>
        <div className={classes.footer}>Open Horizons — Agentic DevOps Platform Accelerator · Microsoft · GitHub · Open Source</div>
        <button className={classes.backToTop} onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
          ↑ Back to Top
        </button>
      </div>

      {/* ── Bottom Footer ── */}
      <div className={classes.bottomFooter}>
       <div className={classes.bottomFooterInner}>
        <div className={classes.bottomFooterLeft}>
          <img src="/logo-msft-github.png" alt="Open Horizons" className={classes.bottomFooterLogo} />
          <span className={classes.bottomFooterText}>Open Horizons — Agentic DevOps Platform</span>
        </div>
        <div className={classes.bottomFooterRight}>
          © 2026 Open Horizons. Developed by{' '}
          <a href="https://github.com/paulanunes85" target="_blank" rel="noopener noreferrer" className={classes.bottomFooterLink}>@paulanunes85</a>
          {' & '}
          <a href="https://github.com/example-org" target="_blank" rel="noopener noreferrer" className={classes.bottomFooterLink}>@example-org</a>
        </div>
       </div>
      </div>
    </Box>
  );
};

export default CustomSignInPage;
