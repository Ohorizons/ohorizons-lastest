import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { textResult } from "../shared/types.js";
import { callRemoteMcpTool } from "../shared/mcp-client.js";

/**
 * Microsoft Learn — FEDERATED module.
 *
 * Proxies the official Microsoft Learn MCP server, which performs semantic
 * search and retrieval across ALL of Microsoft Learn: Azure, AKS, AI Foundry,
 * the Cloud Adoption Framework (CAF), the Well-Architected Framework (WAF),
 * .NET, Microsoft 365, and every other product. This is the authoritative way
 * to get complete, always-current Microsoft documentation coverage.
 *
 * Upstream tools (verified live): microsoft_docs_search {query},
 * microsoft_code_sample_search {query, language?}, microsoft_docs_fetch {url}.
 *
 * Endpoint is configurable via MSLEARN_MCP_URL.
 */
const MSLEARN_MCP_URL =
  process.env.MSLEARN_MCP_URL ?? "https://learn.microsoft.com/api/mcp";

export function registerMicrosoftLearnTools(server: McpServer): void {
  server.tool(
    "mslearn_search",
    "Search ALL of Microsoft Learn (Azure, AKS, AI Foundry, CAF, WAF, .NET, M365, and every Microsoft product) via the official Microsoft Learn MCP. Returns concise, high-quality documentation excerpts with titles and URLs. Use this first to ground any Microsoft/Azure question.",
    {
      query: z
        .string()
        .describe(
          "Natural-language question or keywords, e.g. 'AKS workload identity federated credentials' or 'Well-Architected reliability pillar'"
        ),
    },
    async ({ query }) => {
      try {
        const out = await callRemoteMcpTool(
          MSLEARN_MCP_URL,
          "microsoft_docs_search",
          { query }
        );
        return textResult(out);
      } catch (e) {
        return textResult(
          `Microsoft Learn MCP unavailable (${(e as Error).message}). Try again or use the cached azure-caf / azure-waf modules.`
        );
      }
    }
  );

  server.tool(
    "mslearn_code_search",
    "Search official Microsoft Learn for CODE SAMPLES (optionally filtered by language). Use when you need a concrete implementation snippet from Microsoft docs.",
    {
      query: z
        .string()
        .describe("What the code should do, e.g. 'DefaultAzureCredential Cosmos DB'"),
      language: z
        .string()
        .optional()
        .describe("Optional language filter, e.g. 'python', 'csharp', 'bicep', 'terraform'"),
    },
    async ({ query, language }) => {
      const args: Record<string, unknown> = { query };
      if (language) args.language = language;
      try {
        const out = await callRemoteMcpTool(
          MSLEARN_MCP_URL,
          "microsoft_code_sample_search",
          args
        );
        return textResult(out);
      } catch (e) {
        return textResult(
          `Microsoft Learn MCP unavailable (${(e as Error).message}).`
        );
      }
    }
  );

  server.tool(
    "mslearn_fetch",
    "Fetch and convert a full Microsoft Learn documentation page to markdown by URL. Use after mslearn_search when you need the complete article (tutorial, prerequisites, full code).",
    {
      url: z
        .string()
        .describe("A learn.microsoft.com URL returned by mslearn_search"),
    },
    async ({ url }) => {
      try {
        const out = await callRemoteMcpTool(
          MSLEARN_MCP_URL,
          "microsoft_docs_fetch",
          { url }
        );
        return textResult(out);
      } catch (e) {
        return textResult(
          `Microsoft Learn MCP unavailable (${(e as Error).message}).`
        );
      }
    }
  );
}
