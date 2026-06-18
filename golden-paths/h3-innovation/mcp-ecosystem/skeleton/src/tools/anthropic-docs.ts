import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchUrl } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

/**
 * Anthropic / Claude documentation — complete coverage via the official
 * llms.txt index and llms-full.txt full-text export published at
 * docs.claude.com. This is the Anthropic-recommended way for tools to consume
 * the entire documentation set.
 *
 *  - llms.txt       → curated index of all doc pages (titles + URLs)
 *  - llms-full.txt  → the full text of the documentation in one document
 */
const INDEX_URL = "https://docs.claude.com/llms.txt";
const FULL_URL = "https://docs.claude.com/llms-full.txt";

export function registerAnthropicDocsTools(server: McpServer): void {
  server.tool(
    "anthropicdocs_index",
    "Get the official index of ALL Anthropic/Claude documentation (titles + URLs) from docs.claude.com/llms.txt. Use this to discover what exists, then anthropicdocs_get_page to fetch a specific page.",
    {},
    async () => {
      try {
        return textResult(await fetchUrl(INDEX_URL));
      } catch (e) {
        return textResult(`Anthropic docs index unavailable (${(e as Error).message}).`);
      }
    }
  );

  server.tool(
    "anthropicdocs_get_page",
    "Fetch a specific Anthropic/Claude documentation page as markdown by URL (use a docs.claude.com URL from anthropicdocs_index). Appending '.md' to a docs URL returns clean markdown.",
    {
      url: z
        .string()
        .describe("A docs.claude.com URL (from anthropicdocs_index)"),
    },
    async ({ url }) => {
      const mdUrl = url.endsWith(".md") || url.endsWith(".txt") ? url : `${url}.md`;
      try {
        return textResult(await fetchUrl(mdUrl));
      } catch {
        try {
          return textResult(await fetchUrl(url));
        } catch (e) {
          return textResult(`Page not found: ${url} (${(e as Error).message}).`);
        }
      }
    }
  );

  server.tool(
    "anthropicdocs_search",
    "Search the COMPLETE Anthropic/Claude documentation (docs.claude.com/llms-full.txt) for a keyword or phrase and return the matching sections. Covers the Claude API, agents, tool use, prompt engineering, models, and the Claude Developer Platform.",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
    },
    async ({ query }) => {
      let full: string;
      try {
        full = await fetchUrl(FULL_URL);
      } catch (e) {
        return textResult(`Anthropic full docs unavailable (${(e as Error).message}).`);
      }
      const q = query.toLowerCase();
      // Split on markdown headings to return coherent sections.
      const blocks = full.split(/\n(?=#{1,3}\s)/);
      const matches: string[] = [];
      for (const block of blocks) {
        if (matches.length >= 8) break;
        if (block.toLowerCase().includes(q)) {
          matches.push(block.trim().slice(0, 1200));
        }
      }
      return textResult(
        matches.length
          ? `# Anthropic docs results for "${query}" (${matches.length})\n\n${matches.join("\n\n---\n\n")}`
          : `No results for "${query}" in the Anthropic documentation.`
      );
    }
  );
}
