/**
 * ChatPage — Multi-Agent AI Chat for Open Horizons.
 *
 * Redesigned UI with:
 * - Fixed header with agent status chips
 * - Scrollable message area (only section that scrolls)
 * - Fixed input bar with Send button
 * - Bottom capability tags
 * - Agent badges with model names
 * - Tool call blocks with blue left border
 * - @mention highlighting in user messages
 */

import React, { useState, useRef, useEffect, useCallback } from 'react';
import { makeStyles, Theme } from '@material-ui/core/styles';
import {
  Typography,
  TextField,
  IconButton,
  Paper,
  Chip,
  CircularProgress,
  Tooltip,
  Button,
} from '@material-ui/core';
import SendIcon from '@material-ui/icons/Send';
import RefreshIcon from '@material-ui/icons/Refresh';
import FiberManualRecordIcon from '@material-ui/icons/FiberManualRecord';
import HelpOutlineIcon from '@material-ui/icons/HelpOutline';
import {
  Page,
  Content,
} from '@backstage/core-components';

import {
  sendMessage,
  resetConversation,
  fetchSystemInfo,
  checkHealth,
  type ChatMessage,
  type ChatChunk,
  type ToolCall,
  type AgentInfo,
} from './ChatService';
import ReactMarkdown from 'react-markdown';

// ── Agent Configuration ────────────────────────────────────────────
const AGENT_COLORS: Record<string, string> = {
  pipeline: '#2196F3',
  sentinel: '#4CAF50',
  compass: '#FF9800',
  guardian: '#E91E63',
  lighthouse: '#00BCD4',
  forge: '#795548',
  orchestrator: '#8B5CF6',
};

const AGENT_INITIALS: Record<string, string> = {
  pipeline: 'PI',
  sentinel: 'SE',
  compass: 'CO',
  guardian: 'GU',
  lighthouse: 'LH',
  forge: 'FO',
  orchestrator: 'OH',
};

const AGENT_DESCRIPTIONS: Record<string, string> = {
  pipeline: 'CI/CD diagnostics: workflow runs, job failures, deployment status',
  sentinel: 'Test & coverage: check runs, PR reviews, quality gates',
  compass: 'Planning & stories: epics, user stories, GitHub Issues',
  guardian: 'Security & compliance: vulnerabilities, secret scanning, CVEs',
  lighthouse: 'Observability & SRE: metrics, alerts, dashboards, health',
  forge: 'Infrastructure & cloud: Kubernetes pods, deployments, services',
};

// ── Styles ─────────────────────────────────────────────────────────
const useStyles = makeStyles((theme: Theme) => ({
  /* Override Backstage Content/Page — ChatPage manages its own layout */
  '@global': {
    '.BackstageContent-root': {
      padding: '0 !important',
      overflow: 'hidden !important',
    },
    'main[class*="BackstagePage"]': {
      overflow: 'hidden !important' as any,
      display: 'block !important' as any,
    },
    '.BackstagePage-root': {
      overflow: 'hidden !important' as any,
      display: 'block !important' as any,
    },
  },
  /* Fixed-height container — uses viewport-based positioning */
  pageContainer: {
    display: 'flex',
    flexDirection: 'column',
    height: 'calc(100vh - 52px)',
    maxHeight: 'calc(100vh - 52px)',
    width: '100%',
    overflow: 'hidden',
    position: 'relative',
  },

  /* ── Fixed Header (does NOT scroll) ──────────────────────────── */
  header: {
    flexShrink: 0,
    borderBottom: `1px solid ${theme.palette.grey[200]}`,
    backgroundColor: '#fff',
    zIndex: 10,
  },
  headerTop: {
    padding: theme.spacing(2.5, 3, 1.5),
  },
  title: {
    fontSize: 22,
    fontWeight: 700,
    color: '#1a1a1a',
    lineHeight: 1.2,
  },
  subtitle: {
    fontSize: 12,
    color: theme.palette.grey[500],
    marginTop: 4,
  },
  agentBar: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: theme.spacing(1, 3),
    borderTop: `1px solid ${theme.palette.grey[100]}`,
    flexWrap: 'wrap',
    gap: 8,
  },
  agentBarLeft: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    flexWrap: 'wrap',
  },
  agentStatusChip: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    padding: '5px 14px',
    borderRadius: 16,
    border: `1px solid ${theme.palette.grey[200]}`,
    backgroundColor: '#fff',
    fontSize: 12,
  },
  agentStatusName: {
    fontWeight: 600,
    color: '#333',
  },
  agentBarRight: {
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    fontSize: 12,
    color: theme.palette.grey[400],
    '& code': {
      backgroundColor: theme.palette.grey[100],
      padding: '1px 6px',
      borderRadius: 4,
      fontFamily: '"Cascadia Code", "Fira Code", monospace',
      fontSize: 11,
    },
  },

  /* ── Error Banner ─────────────────────────────────────────────── */
  errorBanner: {
    background: '#FFF3E0',
    border: '1px solid #FFB74D',
    borderRadius: 8,
    padding: theme.spacing(1.5, 2),
    margin: theme.spacing(2, 3),
    fontSize: 13,
    color: '#E65100',
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    flexShrink: 0,
  },

  /* ── Scrollable Messages (ONLY part that scrolls) ────────────── */
  messageList: {
    flex: 1,
    padding: theme.spacing(3),
    overflowY: 'auto',
    '&::-webkit-scrollbar': {
      width: 6,
    },
    '&::-webkit-scrollbar-thumb': {
      backgroundColor: theme.palette.grey[300],
      borderRadius: 3,
    },
  },

  /* ── Message Row ──────────────────────────────────────────────── */
  messageRow: {
    display: 'flex',
    gap: theme.spacing(1.5),
    marginBottom: theme.spacing(2.5),
  },
  userRow: {
    flexDirection: 'row-reverse',
    marginLeft: 'auto',
  },
  avatar: {
    width: 38,
    height: 38,
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
    fontSize: 13,
    fontWeight: 700,
    color: '#fff',
    letterSpacing: 0.5,
  },
  userAvatar: {
    background: theme.palette.grey[300],
    color: theme.palette.grey[700],
    fontSize: 18,
  },

  /* ── Agent Badge ──────────────────────────────────────────────── */
  agentBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    marginBottom: 6,
  },
  agentBadgeDot: {
    fontSize: 10,
  },
  agentBadgeName: {
    fontSize: 12,
    fontWeight: 700,
    textTransform: 'uppercase' as const,
    letterSpacing: 0.5,
  },

  /* ── Bubbles ──────────────────────────────────────────────────── */
  bubble: {
    padding: theme.spacing(2, 2.5),
    borderRadius: 12,
    fontSize: 14,
    lineHeight: 1.65,
    '& p': { margin: '6px 0' },
    '& p:first-child': { marginTop: 0 },
    '& p:last-child': { marginBottom: 0 },
    '& strong': { fontWeight: 600 },
    '& code': {
      background: theme.palette.grey[100],
      padding: '2px 6px',
      borderRadius: 4,
      fontFamily: '"Cascadia Code", "Fira Code", monospace',
      fontSize: 12,
    },
    '& pre': {
      background: theme.palette.grey[100],
      padding: theme.spacing(1.5),
      borderRadius: 8,
      overflow: 'auto',
      '& code': { background: 'none', padding: 0 },
    },
    '& ul, & ol': { paddingLeft: 20, margin: '6px 0' },
    '& li': { marginBottom: 3 },
    '& a': { color: theme.palette.primary.main },
    '& h1, & h2, & h3, & h4': {
      fontSize: 15,
      fontWeight: 600,
      margin: '10px 0 4px',
    },
    '& table': {
      borderCollapse: 'collapse',
      width: '100%',
      fontSize: 12,
      margin: '8px 0',
    },
    '& th, & td': {
      border: `1px solid ${theme.palette.grey[300]}`,
      padding: '6px 10px',
      textAlign: 'left',
    },
    '& th': { background: theme.palette.grey[100], fontWeight: 600 },
  },
  aiBubble: {
    background: '#f8f9fa',
    border: `1px solid ${theme.palette.grey[200]}`,
    color: theme.palette.text.primary,
  },
  userBubble: {
    background: '#0078D4',
    color: '#fff',
    '& .mention-highlight': {
      display: 'inline',
      background: 'rgba(255,255,255,0.2)',
      borderRadius: 4,
      padding: '0 4px',
      fontWeight: 600,
    },
  },


  /* ── Welcome Content ──────────────────────────────────────────── */
  welcomeAgentLine: {
    margin: '6px 0',
    fontSize: 14,
    lineHeight: 1.6,
  },
  welcomeAgentName: {
    fontWeight: 700,
    cursor: 'default',
  },

  /* ── Suggestion Chips ─────────────────────────────────────────── */
  suggestions: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: theme.spacing(1),
    marginTop: theme.spacing(1.5),
  },
  suggestion: {
    fontSize: 12,
    height: 32,
    borderColor: theme.palette.grey[300],
    borderRadius: 16,
    '&:hover': {
      background: '#0078D4',
      color: '#fff',
      borderColor: '#0078D4',
    },
  },

  /* ── Fixed Input Area (does NOT scroll) ──────────────────────── */
  inputArea: {
    flexShrink: 0,
    padding: theme.spacing(2, 3),
    borderTop: `1px solid ${theme.palette.grey[200]}`,
    backgroundColor: '#fff',
  },
  inputRow: {
    display: 'flex',
    gap: theme.spacing(1.5),
    alignItems: 'center',
  },
  textField: {
    flex: 1,
    '& .MuiOutlinedInput-root': {
      borderRadius: 24,
      fontSize: 13,
      backgroundColor: '#f8f9fa',
      '& fieldset': { borderColor: theme.palette.grey[200] },
    },
  },
  sendButton: {
    background: '#0078D4',
    color: '#fff',
    borderRadius: 20,
    padding: '8px 22px',
    textTransform: 'none' as const,
    fontWeight: 600,
    fontSize: 13,
    minWidth: 'auto',
    '&:hover': { background: '#106EBE' },
    '&.Mui-disabled': {
      background: theme.palette.grey[200],
      color: theme.palette.grey[400],
    },
  },

  /* ── Bottom Capability Tags ───────────────────────────────────── */
  bottomTags: {
    display: 'flex',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 6,
    marginTop: theme.spacing(1.5),
  },
  capTag: {
    fontSize: 11,
    height: 24,
    borderRadius: 12,
    backgroundColor: theme.palette.grey[100],
    color: theme.palette.grey[600],
  },

  /* ── Typing Indicator ─────────────────────────────────────────── */
  typing: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: theme.spacing(1, 2),
    color: theme.palette.grey[500],
    fontSize: 13,
  },
}));

// ── Component ──────────────────────────────────────────────────────
const ChatPage: React.FC = () => {
  const classes = useStyles();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const [streamingContent, setStreamingContent] = useState('');
  const [, setStreamingTools] = useState<ToolCall[]>([]);
  const [streamingAgent, setStreamingAgent] = useState<string>('');
  const [agents, setAgents] = useState<AgentInfo[]>([]);
  const [backendOnline, setBackendOnline] = useState<boolean | null>(null);
  const [, setModelName] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Lock body scroll while ChatPage is mounted — single scrollbar (messageList only)
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  // Fetch agent info on mount
  useEffect(() => {
    let cancelled = false;
    const loadInfo = async () => {
      try {
        const [info] = await Promise.all([
          fetchSystemInfo(),
          checkHealth(),
        ]);
        if (!cancelled) {
          setAgents(info.agents);
          setModelName(info.model);
          setBackendOnline(true);
        }
      } catch {
        if (!cancelled) setBackendOnline(false);
      }
    };
    loadInfo();
    const interval = setInterval(loadInfo, 30_000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  // Auto-scroll
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, streamingContent]);

  // Send message
  const handleSend = useCallback(
    async (text?: string) => {
      const messageText = text || input.trim();
      if (!messageText || isStreaming) return;

      setInput('');

      const userMsg: ChatMessage = {
        id: `user-${Date.now()}`,
        role: 'user',
        content: messageText,
        timestamp: new Date(),
      };
      setMessages(prev => [...prev, userMsg]);
      setIsStreaming(true);
      setStreamingContent('');
      setStreamingTools([]);
      setStreamingAgent('');

      try {
        let currentContent = '';
        const currentTools: ToolCall[] = [];

        const { content, toolCalls, agent } = await sendMessage(
          messageText,
          (chunk: ChatChunk) => {
            if (chunk.agent) setStreamingAgent(chunk.agent);
            switch (chunk.type) {
              case 'text':
                currentContent += chunk.content;
                setStreamingContent(currentContent);
                break;
              case 'tool_use':
                if (chunk.tool_name) {
                  currentTools.push({
                    name: chunk.tool_name,
                    input: chunk.tool_input || {},
                  });
                  setStreamingTools([...currentTools]);
                }
                break;
              case 'tool_result': {
                const tc = currentTools.findLast(
                  t => t.name === chunk.tool_name,
                );
                if (tc) tc.result = chunk.content;
                setStreamingTools([...currentTools]);
                break;
              }
            }
          },
        );

        const assistantMsg: ChatMessage = {
          id: `ai-${Date.now()}`,
          role: 'assistant',
          content,
          toolCalls,
          agent,
          timestamp: new Date(),
        };
        setMessages(prev => [...prev, assistantMsg]);
      } catch (err) {
        const errorMsg: ChatMessage = {
          id: `err-${Date.now()}`,
          role: 'assistant',
          content: `**Error:** ${err instanceof Error ? err.message : 'Failed to reach the AI agent. Is the backend running on port 8008?'}`,
          timestamp: new Date(),
        };
        setMessages(prev => [...prev, errorMsg]);
      } finally {
        setIsStreaming(false);
        setStreamingContent('');
        setStreamingTools([]);
        setStreamingAgent('');
      }
    },
    [input, isStreaming],
  );

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleNewChat = () => {
    setMessages([]);
    resetConversation();
  };

  const suggestions = [
    '@pipeline check the build on ohorizons-demo',
    '@sentinel show test status on ohorizons-demo main',
    '@compass decompose epic: user auth with SSO',
    '@guardian scan security on ohorizons-demo',
    '@lighthouse check deployments on ohorizons-demo',
    '@forge show repo info for todo-app-full-stack',
  ];

  const capabilityTags = [
    '@pipeline CI/CD',
    '@sentinel Tests',
    '@compass Planning',
    '@guardian Security',
    '@lighthouse SRE',
    '@forge Infra',
  ];

  // Resolve display agents — fall back to defaults when backend is offline
  const displayAgents =
    agents.length > 0
      ? agents
          .filter(a => a.name !== 'orchestrator')
          .map(a => ({ name: a.name }))
      : [
          { name: 'pipeline' },
          { name: 'sentinel' },
          { name: 'compass' },
        ];

  return (
    <Page themeId="home">
      <Content>
        <div className={classes.pageContainer}>
          {/* ── Fixed Header ─────────────────────────────────────── */}
          <div className={classes.header}>
            <div className={classes.headerTop}>
              <Typography className={classes.title}>AI Chat</Typography>
            </div>
            <div className={classes.agentBar}>
              <div className={classes.agentBarLeft}>
                {displayAgents.map(a => (
                  <div key={a.name} className={classes.agentStatusChip}>
                    <FiberManualRecordIcon
                      style={{
                        fontSize: 10,
                        color: AGENT_COLORS[a.name] || '#999',
                      }}
                    />
                    <span className={classes.agentStatusName}>@{a.name}</span>
                  </div>
                ))}
              </div>
              <div className={classes.agentBarRight}>
                <HelpOutlineIcon style={{ fontSize: 16 }} />
                <span>
                  Use <code>@mention</code> to invoke a specific agent
                </span>
              </div>
            </div>
          </div>

          {/* ── Connection Error Banner ──────────────────────────── */}
          {backendOnline === false && (
            <div className={classes.errorBanner}>
              ⚠️ Agent backend is not reachable. Make sure the agent-api is
              running on port 8008 and the Backstage proxy is configured.
            </div>
          )}

          {/* ── Scrollable Messages ──────────────────────────────── */}
          <div className={classes.messageList}>
            {messages.length === 0 && !isStreaming && (
              <WelcomeMessage
                classes={classes}
                agents={agents}
                onSuggestion={text => handleSend(text)}
                suggestions={suggestions}
              />
            )}

            {messages.map(msg => (
              <MessageBubble key={msg.id} message={msg} classes={classes} />
            ))}

            {/* Streaming indicator */}
            {isStreaming && (
              <>
                {streamingContent ? (
                  <div className={classes.messageRow}>
                    <div
                      className={classes.avatar}
                      style={{
                        background:
                          AGENT_COLORS[streamingAgent] || '#8B5CF6',
                      }}
                    >
                      {AGENT_INITIALS[streamingAgent] || 'AI'}
                    </div>
                    <div>
                      {streamingAgent && (
                        <div className={classes.agentBadge}>
                          <FiberManualRecordIcon
                            className={classes.agentBadgeDot}
                            style={{
                              color:
                                AGENT_COLORS[streamingAgent] || '#8B5CF6',
                            }}
                          />
                          <span
                            className={classes.agentBadgeName}
                            style={{
                              color:
                                AGENT_COLORS[streamingAgent] || '#8B5CF6',
                            }}
                          >
                            {streamingAgent.toUpperCase()}
                          </span>
                        </div>
                      )}
                      <Paper
                        className={`${classes.bubble} ${classes.aiBubble}`}
                        elevation={0}
                      >
                        <ReactMarkdown>{streamingContent}</ReactMarkdown>
                        <span style={{ opacity: 0.5 }}>▊</span>
                      </Paper>
                    </div>
                  </div>
                ) : (
                  <div className={classes.typing}>
                    <CircularProgress size={14} />
                    {streamingAgent
                      ? `${(streamingAgent || '').toUpperCase()} is thinking...`
                      : 'AI Agent is thinking...'}
                  </div>
                )}
              </>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* ── Fixed Input Area ──────────────────────────────────── */}
          <div className={classes.inputArea}>
            <div className={classes.inputRow}>
              <Tooltip title="New conversation">
                <IconButton
                  onClick={handleNewChat}
                  size="small"
                  style={{ color: '#999' }}
                >
                  <RefreshIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <TextField
                className={classes.textField}
                variant="outlined"
                size="small"
                placeholder="Type @pipeline, @sentinel, or @compass to invoke an agent..."
                value={input}
                onChange={e => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                disabled={isStreaming || backendOnline === false}
                multiline
                maxRows={3}
              />
              <Button
                className={classes.sendButton}
                onClick={() => handleSend()}
                disabled={
                  !input.trim() || isStreaming || backendOnline === false
                }
                startIcon={<SendIcon style={{ fontSize: 16 }} />}
              >
                Send
              </Button>
            </div>
            <div className={classes.bottomTags}>
              {capabilityTags.map(tag => (
                <Chip
                  key={tag}
                  label={tag}
                  size="small"
                  className={classes.capTag}
                />
              ))}
            </div>
          </div>
        </div>
      </Content>
    </Page>
  );
};

// ── Sub-components ─────────────────────────────────────────────────

function WelcomeMessage({
  classes,
  agents,
  onSuggestion,
  suggestions,
}: {
  classes: ReturnType<typeof useStyles>;
  agents: AgentInfo[];
  onSuggestion: (text: string) => void;
  suggestions: string[];
}) {
  return (
    <div className={classes.messageRow}>
      <div
        className={classes.avatar}
        style={{ background: AGENT_COLORS.orchestrator }}
      >
        OH
      </div>
      <div>
        <div className={classes.agentBadge}>
          <FiberManualRecordIcon
            className={classes.agentBadgeDot}
            style={{ color: '#4CAF50' }}
          />
          <span
            className={classes.agentBadgeName}
            style={{ color: AGENT_COLORS.orchestrator }}
          >
            ORCHESTRATOR
          </span>
        </div>
        <Paper
          className={`${classes.bubble} ${classes.aiBubble}`}
          elevation={0}
        >
          <Typography
            variant="body2"
            style={{ lineHeight: 1.65, fontSize: 14 }}
          >
            Hello! I'm the <strong>Open Horizons Assistant</strong>. I
            coordinate{' '}
            {agents.length > 0
              ? agents.filter(a => a.name !== 'orchestrator').length
              : 3}{' '}
            specialized AI agents for your DevOps workflows:
          </Typography>

          {Object.entries(AGENT_DESCRIPTIONS).map(([name, desc]) => (
            <div key={name} className={classes.welcomeAgentLine}>
              <span
                className={classes.welcomeAgentName}
                style={{ color: AGENT_COLORS[name] }}
              >
                @{name}
              </span>
              {' — '}
              {desc}
            </div>
          ))}

          <Typography
            variant="body2"
            style={{ lineHeight: 1.65, marginTop: 10, fontSize: 14 }}
          >
            Use{' '}
            <code
              style={{
                backgroundColor: '#f0f0f0',
                padding: '2px 6px',
                borderRadius: 4,
                fontFamily: '"Cascadia Code", monospace',
                fontSize: 12,
              }}
            >
              @mention
            </code>{' '}
            to call an agent directly, or just describe your problem and I'll
            route it.
          </Typography>
        </Paper>
        <div className={classes.suggestions}>
          {suggestions.map(s => (
            <Chip
              key={s}
              label={s}
              variant="outlined"
              size="small"
              className={classes.suggestion}
              onClick={() => onSuggestion(s)}
              clickable
            />
          ))}
        </div>
      </div>
    </div>
  );
}

function MessageBubble({
  message,
  classes,
}: {
  message: ChatMessage;
  classes: ReturnType<typeof useStyles>;
}) {
  const isUser = message.role === 'user';

  // Highlight @mentions in user messages
  const renderUserContent = (text: string) => {
    const parts = text.split(/(@\w+)/g);
    return parts.map((part, i) => {
      if (part.startsWith('@')) {
        return (
          <span key={i} className="mention-highlight">
            {part}
          </span>
        );
      }
      return part;
    });
  };

  const agentName = message.agent || 'orchestrator';

  return (
    <div className={`${classes.messageRow} ${isUser ? classes.userRow : ''}`}>
      {isUser ? (
        <div className={`${classes.avatar} ${classes.userAvatar}`}>👤</div>
      ) : (
        <div
          className={classes.avatar}
          style={{ background: AGENT_COLORS[agentName] || '#8B5CF6' }}
        >
          {AGENT_INITIALS[agentName] || 'AI'}
        </div>
      )}
      <div>
        {/* Agent badge */}
        {!isUser && (
          <div className={classes.agentBadge}>
            <FiberManualRecordIcon
              className={classes.agentBadgeDot}
              style={{ color: AGENT_COLORS[agentName] || '#8B5CF6' }}
            />
            <span
              className={classes.agentBadgeName}
              style={{ color: AGENT_COLORS[agentName] || '#8B5CF6' }}
            >
              {agentName.toUpperCase()}
            </span>
          </div>
        )}

        {/* Message content */}
        <Paper
          className={`${classes.bubble} ${isUser ? classes.userBubble : classes.aiBubble}`}
          elevation={0}
        >
          {isUser ? (
            <Typography variant="body2" style={{ fontSize: 14 }}>
              {renderUserContent(message.content)}
            </Typography>
          ) : (
            <ReactMarkdown>{message.content}</ReactMarkdown>
          )}
        </Paper>
      </div>
    </div>
  );
}

export default ChatPage;
