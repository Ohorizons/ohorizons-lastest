/**
 * ChatService — SSE client for the Open Horizons AI Agent backend.
 *
 * Connects to the FastAPI backend (via Backstage proxy) and streams
 * Claude SDK responses as Server-Sent Events.
 */

export interface ChatChunk {
  type: 'text' | 'tool_use' | 'tool_result' | 'agent' | 'done' | 'error';
  content: string;
  tool_name?: string;
  tool_input?: Record<string, unknown>;
  agent?: string;
  display_name?: string;
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  toolCalls?: ToolCall[];
  agent?: string;
  timestamp: Date;
}

export interface ToolCall {
  name: string;
  input: Record<string, unknown>;
  result?: string;
}

export interface AgentInfo {
  name: string;
  display_name: string;
  description: string;
  tools: string[];
  temperature: number;
}

export interface SystemInfo {
  agents: AgentInfo[];
  total_agents: number;
  model: string;
  version: string;
}

// The Backstage proxy forwards /api/proxy/agent-api/* → http://localhost:8008/*
const AGENT_API_BASE = '/api/proxy/agent-api';

let conversationId: string | null = null;

function getConversationId(): string {
  if (!conversationId) {
    conversationId = `conv-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  }
  return conversationId;
}

/**
 * Fetch system info — agents, tools, model, version.
 */
export async function fetchSystemInfo(): Promise<SystemInfo> {
  const res = await fetch(`${AGENT_API_BASE}/api/agents/info`, { credentials: 'include' });
  if (!res.ok) throw new Error(`Info API error: ${res.status}`);
  return res.json();
}

/**
 * Check agent health.
 */
export async function checkHealth(): Promise<{ status: string; model: string }> {
  const res = await fetch(`${AGENT_API_BASE}/health`, { credentials: 'include' });
  if (!res.ok) throw new Error(`Health check failed: ${res.status}`);
  return res.json();
}

/**
 * Send a message to the AI Agent and stream the response via SSE.
 */
export async function sendMessage(
  message: string,
  onChunk: (chunk: ChatChunk) => void,
): Promise<{ content: string; toolCalls: ToolCall[]; agent?: string }> {
  const response = await fetch(`${AGENT_API_BASE}/api/agents/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({
      message,
      conversation_id: getConversationId(),
    }),
  });

  if (!response.ok) {
    throw new Error(`Agent API error: ${response.status} ${response.statusText}`);
  }

  const reader = response.body?.getReader();
  if (!reader) throw new Error('No response body');

  const decoder = new TextDecoder();
  let fullContent = '';
  const toolCalls: ToolCall[] = [];
  let buffer = '';
  let detectedAgent: string | undefined;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });

    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const line of lines) {
      if (!line.startsWith('data: ')) continue;

      try {
        const chunk: ChatChunk = JSON.parse(line.slice(6));
        if (chunk.agent) detectedAgent = chunk.agent;
        onChunk(chunk);

        switch (chunk.type) {
          case 'agent':
            if (chunk.agent) detectedAgent = chunk.agent;
            break;
          case 'text':
            fullContent += chunk.content;
            break;
          case 'tool_use':
            if (chunk.tool_name) {
              toolCalls.push({
                name: chunk.tool_name,
                input: chunk.tool_input || {},
              });
            }
            break;
          case 'tool_result': {
            const lastCall = toolCalls.findLast(tc => tc.name === chunk.tool_name);
            if (lastCall) lastCall.result = chunk.content;
            break;
          }
          case 'error':
            throw new Error(chunk.content || 'Unknown agent error');
        }
      } catch (e) {
        if (e instanceof SyntaxError) continue;
        throw e;
      }
    }
  }

  return { content: fullContent, toolCalls, agent: detectedAgent };
}

/**
 * Reset conversation (start fresh).
 */
export function resetConversation(): void {
  conversationId = null;
}
