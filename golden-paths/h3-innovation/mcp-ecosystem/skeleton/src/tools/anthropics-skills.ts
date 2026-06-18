import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "anthropics";
const REPO = "skills";

export function registerAnthropicsSkillsTools(server: McpServer): void {
  server.tool(
    "anthropics_list_skills",
    "List all available skills from the anthropics/skills repository",
    {},
    async () => {
      const items = await listContents(OWNER, REPO, "skills");
      const dirs = items.filter((i) => i.type === "dir");
      const list = dirs.map((d) => `- ${d.name}`).join("\n");
      return textResult(
        `Found ${dirs.length} skills in anthropics/skills:\n\n${list}`
      );
    }
  );

  server.tool(
    "anthropics_get_skill",
    "Get the SKILL.md content for a specific Anthropic skill",
    {
      name: z
        .string()
        .describe("Skill folder name (e.g. 'pdf', 'docx', 'xlsx')"),
    },
    async ({ name }) => {
      const content = await fetchRaw(OWNER, REPO, `skills/${name}/SKILL.md`);
      return textResult(content);
    }
  );

  server.tool(
    "anthropics_get_skill_template",
    "Get the template for creating a new Anthropic-style skill (SKILL.md format)",
    {},
    async () => {
      const items = await listContents(OWNER, REPO, "template");
      const skillMd = items.find(
        (i) => i.name === "SKILL.md" || i.name.endsWith(".md")
      );
      if (skillMd) {
        const content = await fetchRaw(OWNER, REPO, skillMd.path);
        return textResult(content);
      }
      return textResult(
        "---\nname: my-skill-name\ndescription: A clear description\n---\n\n# My Skill Name\n\n[instructions here]"
      );
    }
  );

  server.tool(
    "anthropics_search_skills",
    "Search anthropics skills by name keyword",
    { query: z.string().describe("Keyword to filter skill names") },
    async ({ query }) => {
      const items = await listContents(OWNER, REPO, "skills");
      const dirs = items.filter(
        (i) =>
          i.type === "dir" &&
          i.name.toLowerCase().includes(query.toLowerCase())
      );
      if (dirs.length === 0) {
        return textResult(`No skills matching "${query}" found.`);
      }
      return textResult(
        `Skills matching "${query}":\n\n${dirs.map((d) => `- ${d.name}`).join("\n")}`
      );
    }
  );

  server.tool(
    "anthropics_get_spec",
    "Get the Agent Skills specification from anthropics/skills",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      return textResult(readme);
    }
  );
}
