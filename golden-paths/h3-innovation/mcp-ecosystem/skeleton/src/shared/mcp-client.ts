import { cacheGet, cacheSet } from "./cache.js";

/**
 * Minimal Model Context Protocol (MCP) client over Streamable HTTP.
 *
 * Used to FEDERATE official remote MCP servers (e.g. the Microsoft Learn MCP at
 * https://learn.microsoft.com/api/mcp) so the MCP Ecosystem can re-expose their
 * tools as its own. Each call runs the full handshake
 * (initialize -> notifications/initialized -> tools/call). Because results are
 * cached by (baseUrl, tool, args), the handshake only runs on a cache miss.
 *
 * Remote responses may be raw JSON or Server-Sent Events (text/event-stream);
 * both are handled by extracting the last JSON object from the body.
 */

const PROTOCOL_VERSION = "2025-06-18";

function baseHeaders(sessionId?: string): Record<string, string> {
  const h: Record<string, string> = {
    "Content-Type": "application/json",
    Accept: "application/json, text/event-stream",
    "User-Agent": "mcp-ecosystem/1.0",
    "MCP-Protocol-Version": PROTOCOL_VERSION,
  };
  if (sessionId) h["Mcp-Session-Id"] = sessionId;
  return h;
}

function postJson(
  url: string,
  body: unknown,
  sessionId?: string
): Promise<Response> {
  return fetch(url, {
    method: "POST",
    headers: baseHeaders(sessionId),
    body: JSON.stringify(body),
  });
}

/** Parse an MCP HTTP response body that may be raw JSON or SSE. */
function parseMcpBody(text: string): Record<string, unknown> {
  const trimmed = text.trim();
  if (trimmed.startsWith("{")) {
    return JSON.parse(trimmed) as Record<string, unknown>;
  }
  const lines = trimmed.split("\n");
  for (let i = lines.length - 1; i >= 0; i--) {
    let line = lines[i].trim();
    if (line.startsWith("data:")) line = line.slice(5).trim();
    if (line.startsWith("{")) {
      return JSON.parse(line) as Record<string, unknown>;
    }
  }
  throw new Error("MCP response contained no JSON payload");
}

/** Extract human-readable text from an MCP tools/call result. */
function extractText(result: unknown): string {
  const r = result as { content?: Array<Record<string, unknown>> } | undefined;
  const content = r?.content;
  if (Array.isArray(content)) {
    return content
      .map((c) => (typeof c.text === "string" ? c.text : JSON.stringify(c)))
      .join("\n");
  }
  return JSON.stringify(result ?? {}, null, 2);
}

/**
 * Call a single tool on a remote MCP server and return its text content.
 * Cached by (baseUrl, toolName, args).
 */
export async function callRemoteMcpTool(
  baseUrl: string,
  toolName: string,
  args: Record<string, unknown>
): Promise<string> {
  const cacheKey = `mcp:${baseUrl}:${toolName}:${JSON.stringify(args)}`;
  const cached = cacheGet(cacheKey);
  if (cached) return cached;

  // 1. initialize
  const initRes = await postJson(baseUrl, {
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: {
      protocolVersion: PROTOCOL_VERSION,
      capabilities: {},
      clientInfo: { name: "mcp-ecosystem", version: "1.0" },
    },
  });
  if (!initRes.ok) {
    throw new Error(`MCP initialize failed: ${initRes.status} (${baseUrl})`);
  }
  const sessionId = initRes.headers.get("mcp-session-id") ?? undefined;
  await initRes.text(); // drain

  // 2. initialized notification (only when the server issued a session)
  if (sessionId) {
    await postJson(
      baseUrl,
      { jsonrpc: "2.0", method: "notifications/initialized" },
      sessionId
    );
  }

  // 3. tools/call
  const callRes = await postJson(
    baseUrl,
    {
      jsonrpc: "2.0",
      id: 2,
      method: "tools/call",
      params: { name: toolName, arguments: args },
    },
    sessionId
  );
  if (!callRes.ok) {
    throw new Error(`MCP tools/call failed: ${callRes.status} (${baseUrl})`);
  }

  const parsed = parseMcpBody(await callRes.text());
  if (parsed.error) {
    throw new Error(
      `MCP error from ${baseUrl}: ${JSON.stringify(parsed.error)}`
    );
  }
  const out = extractText(parsed.result);
  cacheSet(cacheKey, out);
  return out;
}
