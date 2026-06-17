import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "github";
const REPO = "awesome-copilot";

const VALID_TYPES = ["skills", "agents", "prompts"] as const;
type ItemType = (typeof VALID_TYPES)[number];

function typeFolder(type: ItemType): string {
  return type;
}

export function registerAwesomeCopilotTools(server: McpServer): void {
  server.tool(
    "awesome_list_items",
    "List all skills, agents, or prompts from github/awesome-copilot",
    {
      type: z
        .enum(VALID_TYPES)
        .describe("Type of item: 'skills', 'agents', or 'prompts'"),
    },
    async ({ type }) => {
      const items = await listContents(OWNER, REPO, typeFolder(type));
      const names = items.map((i) => `- ${i.name} (${i.type})`).join("\n");
      return textResult(
        `Found ${items.length} ${type} in awesome-copilot:\n\n${names}`
      );
    }
  );

  server.tool(
    "awesome_get_item",
    "Get the content of a specific skill, agent, or prompt from awesome-copilot",
    {
      type: z.enum(VALID_TYPES).describe("Type: 'skills', 'agents', or 'prompts'"),
      name: z.string().describe("Name of the item (folder name or file name)"),
    },
    async ({ type, name }) => {
      if (type === "skills") {
        const content = await fetchRaw(
          OWNER,
          REPO,
          `${typeFolder(type)}/${name}/SKILL.md`
        );
        return textResult(content);
      }
      // agents and prompts are single .md files
      const fileName = name.endsWith(".md") ? name : `${name}.md`;
      const content = await fetchRaw(
        OWNER,
        REPO,
        `${typeFolder(type)}/${fileName}`
      );
      return textResult(content);
    }
  );

  server.tool(
    "awesome_search",
    "Search awesome-copilot items by keyword across all types",
    { query: z.string().describe("Keyword to search for") },
    async ({ query }) => {
      const results: string[] = [];
      for (const type of VALID_TYPES) {
        try {
          const items = await listContents(OWNER, REPO, typeFolder(type));
          const matches = items.filter((i) =>
            i.name.toLowerCase().includes(query.toLowerCase())
          );
          for (const m of matches) {
            results.push(`[${type}] ${m.name}`);
          }
        } catch {
          // Some folders may not exist
        }
      }
      if (results.length === 0) {
        return textResult(`No items matching "${query}" found.`);
      }
      return textResult(
        `Found ${results.length} matches for "${query}":\n\n${results.map((r) => `- ${r}`).join("\n")}`
      );
    }
  );

  server.tool(
    "awesome_get_readme",
    "Get the awesome-copilot main README with full catalog index",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      return textResult(readme);
    }
  );
}
