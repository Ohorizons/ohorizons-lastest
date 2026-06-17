import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "github";
const REPO = "spec-kit";

export function registerSpecKitTools(server: McpServer): void {
  server.tool(
    "speckit_get_phases",
    "Get the Spec-Driven Development phases and workflow from github/spec-kit",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      const phasesMatch = readme.match(
        /## 🌟 Development Phases[\s\S]*?(?=\n## )/
      );
      return textResult(
        phasesMatch?.[0] ?? "Development phases section not found in README."
      );
    }
  );

  server.tool(
    "speckit_get_commands",
    "Get the spec-kit slash commands reference (/speckit.constitution, /speckit.specify, etc.)",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      const commandsMatch = readme.match(
        /### Available Slash Commands[\s\S]*?(?=\n## )/
      );
      return textResult(
        commandsMatch?.[0] ?? "Slash commands section not found in README."
      );
    }
  );

  server.tool(
    "speckit_get_methodology",
    "Get the full Spec-Driven Development methodology document",
    {},
    async () => {
      const doc = await fetchRaw(OWNER, REPO, "spec-driven.md");
      return textResult(doc);
    }
  );

  server.tool(
    "speckit_get_philosophy",
    "Get the core philosophy and experimental goals of Spec-Driven Development",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      const philosophyMatch = readme.match(
        /## 📚 Core Philosophy[\s\S]*?(?=\n## 🔧 Prerequisites)/
      );
      return textResult(
        philosophyMatch?.[0] ?? "Core philosophy section not found."
      );
    }
  );

  server.tool(
    "speckit_search",
    "Search the spec-kit README for a specific topic",
    { query: z.string().describe("The topic to search for in spec-kit docs") },
    async ({ query }) => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      const lines = readme.split("\n");
      const matches = lines.filter((line) =>
        line.toLowerCase().includes(query.toLowerCase())
      );
      if (matches.length === 0) {
        return textResult(`No matches found for "${query}" in spec-kit README.`);
      }
      return textResult(
        `Found ${matches.length} matches for "${query}":\n\n${matches.join("\n")}`
      );
    }
  );
}
