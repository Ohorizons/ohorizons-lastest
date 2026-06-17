import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import express from "express";
import { randomUUID } from "node:crypto";

// Prevent unhandled errors from crashing the process
process.on("uncaughtException", (err) => {
  console.error("[mcp-ecosystem] uncaughtException:", err);
});
process.on("unhandledRejection", (reason) => {
  console.error("[mcp-ecosystem] unhandledRejection:", reason);
});

export function createServer(): McpServer {
  const server = new McpServer(
    {
      name: "mcp-ecosystem",
      version: "1.0.0",
    },
    {
      capabilities: {
        tools: {},
        prompts: {},
        resources: {},
      },
    }
  );

  // Register a minimal prompt so the SDK initializes prompts/list handler
  server.prompt("server-info", "Returns MCP Ecosystem server info", () => ({
    messages: [
      {
        role: "user",
        content: {
          type: "text",
          text: "MCP Ecosystem server v1.0.0 — Backstage docs, Copilot docs, Anthropic docs, Spec-Kit methodology.",
        },
      },
    ],
  }));

  return server;
}

// Each session gets its own McpServer instance to avoid "Already connected" errors.
export async function startHttpServer(
  registerTools: (server: McpServer) => void
): Promise<void> {
  const app = express();
  const PORT = parseInt(process.env.PORT ?? "3100", 10);

  // Parse JSON bodies so req.body is available for the transport
  app.use(express.json());

  const transports = new Map<string, StreamableHTTPServerTransport>();

  app.post("/mcp", async (req, res) => {
    try {
      const sessionId = req.headers["mcp-session-id"] as string | undefined;
      let transport: StreamableHTTPServerTransport;

      if (sessionId && transports.has(sessionId)) {
        transport = transports.get(sessionId)!;
      } else {
        if (sessionId) {
          // Client sent an unknown session ID — session expired or never existed
          res.status(404).json({ error: "Session not found" });
          return;
        }
        const newSessionId = randomUUID();
        transport = new StreamableHTTPServerTransport({
          sessionIdGenerator: () => newSessionId,
        });
        transports.set(newSessionId, transport);
        transport.onclose = () => {
          transports.delete(newSessionId);
        };
        // Create a fresh server instance per session
        const sessionServer = createServer();
        registerTools(sessionServer);
        await sessionServer.connect(transport);
      }

      await transport.handleRequest(req, res, req.body);
    } catch (err) {
      console.error("[mcp-ecosystem] POST /mcp error:", err);
      if (!res.headersSent) {
        res.status(500).json({ error: "Internal server error" });
      }
    }
  });

  app.get("/mcp", async (req, res) => {
    try {
      const sessionId = req.headers["mcp-session-id"] as string | undefined;
      if (!sessionId || !transports.has(sessionId)) {
        res.status(400).json({ error: "No active session. POST first." });
        return;
      }
      const transport = transports.get(sessionId)!;
      await transport.handleRequest(req, res);
    } catch (err) {
      console.error("[mcp-ecosystem] GET /mcp error:", err);
      if (!res.headersSent) {
        res.status(500).json({ error: "Internal server error" });
      }
    }
  });

  app.delete("/mcp", async (req, res) => {
    try {
      const sessionId = req.headers["mcp-session-id"] as string | undefined;
      if (sessionId && transports.has(sessionId)) {
        const transport = transports.get(sessionId)!;
        await transport.handleRequest(req, res);
        transports.delete(sessionId);
      } else {
        res.status(200).end();
      }
    } catch (err) {
      console.error("[mcp-ecosystem] DELETE /mcp error:", err);
      if (!res.headersSent) {
        res.status(500).json({ error: "Internal server error" });
      }
    }
  });

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", sessions: transports.size });
  });

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`mcp-ecosystem listening on http://0.0.0.0:${PORT}/mcp`);
  });
}
