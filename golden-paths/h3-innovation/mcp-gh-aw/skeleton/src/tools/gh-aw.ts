import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { fetchRaw } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "github";
const REPO = "gh-aw";

export function registerGhAwTools(server: McpServer): void {
  server.tool(
    "ghaw_get_workflow_patterns",
    "Get GitHub Agentic Workflows overview — how to write agentic workflows in markdown for GitHub Actions",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      return textResult(readme);
    }
  );

  server.tool(
    "ghaw_get_security_guidelines",
    "Get the Guardrails and security architecture for GitHub Agentic Workflows",
    {},
    async () => {
      const readme = await fetchRaw(OWNER, REPO, "README.md");
      const guardrailsMatch = readme.match(
        /## Guardrails[\s\S]*?(?=\n## Documentation)/
      );
      return textResult(
        guardrailsMatch?.[0] ??
          "Guardrails section not found in README."
      );
    }
  );

  server.tool(
    "ghaw_get_contributing",
    "Get the gh-aw contributing guide and development setup",
    {},
    async () => {
      const contributing = await fetchRaw(OWNER, REPO, "CONTRIBUTING.md");
      return textResult(contributing);
    }
  );

  server.tool(
    "ghaw_get_agents_md",
    "Get the AGENTS.md file from gh-aw repo (example of a real-world AGENTS.md)",
    {},
    async () => {
      const agentsmd = await fetchRaw(OWNER, REPO, "AGENTS.md");
      return textResult(agentsmd);
    }
  );
}
