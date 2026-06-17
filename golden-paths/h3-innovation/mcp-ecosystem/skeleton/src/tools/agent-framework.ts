import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "microsoft";
const REPO = "agent-framework";

export function registerAgentFrameworkTools(server: McpServer): void {
  server.tool(
    "agentfw_get_patterns",
    "Get Microsoft Agent Framework highlights, architecture patterns, and key features",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      const highlightsMatch = readme.match(
        /### ✨ Highlights[\s\S]*?(?=\n### 💬)/
      );
      return textResult(
        highlightsMatch?.[0] ??
          "Highlights section not found. Full README:\n\n" + readme.slice(0, 3000)
      );
    }
  );

  server.tool(
    "agentfw_get_sample",
    "Get agent sample code or listing from microsoft/agent-framework",
    {
      language: z
        .enum(["python", "dotnet"])
        .describe("Programming language: 'python' or 'dotnet'"),
      topic: z
        .string()
        .optional()
        .describe("Optional topic filter (e.g. 'workflows', 'providers', 'middleware')"),
    },
    async ({ language, topic }) => {
      const basePath =
        language === "python" ? "python/samples" : "dotnet/samples";
      const items = await listContents(OWNER, REPO, basePath);
      let filtered = items;
      if (topic) {
        filtered = items.filter((i) =>
          i.name.toLowerCase().includes(topic.toLowerCase())
        );
      }
      if (filtered.length === 0) {
        return textResult(
          `No samples found for "${topic ?? "all"}" in ${language}. Available:\n${items.map((i) => `- ${i.name}`).join("\n")}`
        );
      }
      return textResult(
        `${language} samples${topic ? ` matching "${topic}"` : ""}:\n\n${filtered.map((i) => `- ${i.name} (${i.type})`).join("\n")}`
      );
    }
  );

  server.tool(
    "agentfw_search_docs",
    "Search microsoft/agent-framework docs directory",
    { query: z.string().describe("Topic to search in docs") },
    async ({ query }) => {
      const items = await listContents(OWNER, REPO, "docs");
      const matches = items.filter((i) =>
        i.name.toLowerCase().includes(query.toLowerCase())
      );
      if (matches.length === 0) {
        return textResult(
          `No docs matching "${query}". Available:\n${items.map((i) => `- ${i.name}`).join("\n")}`
        );
      }
      return textResult(
        `Docs matching "${query}":\n\n${matches.map((i) => `- ${i.name} (${i.type})`).join("\n")}`
      );
    }
  );

  server.tool(
    "agentfw_get_declarative_agents",
    "List declarative agent samples from agent-samples/ directory",
    {},
    async () => {
      const items = await listContents(OWNER, REPO, "agent-samples");
      return textResult(
        `Declarative agent samples:\n\n${items.map((i) => `- ${i.name} (${i.type})`).join("\n")}`
      );
    }
  );
}
