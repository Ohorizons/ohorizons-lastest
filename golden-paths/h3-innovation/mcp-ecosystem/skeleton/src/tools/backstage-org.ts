import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, fetchUrl } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";
import { cacheGet, cacheSet } from "../shared/cache.js";

const ORG = "backstage";
const GH_TOKEN = process.env.GH_TOKEN ?? "";

const ghHeaders: Record<string, string> = {
  "User-Agent": "mcp-ecosystem/1.0",
  Accept: "application/vnd.github.v3+json",
};
if (GH_TOKEN) ghHeaders["Authorization"] = `Bearer ${GH_TOKEN}`;

async function listOrgRepos(): Promise<Array<{ name: string; description: string; stars: number; topics: string[] }>> {
  const cacheKey = `org:${ORG}:repos`;
  const cached = cacheGet(cacheKey);
  if (cached) return JSON.parse(cached);

  const repos: Array<{ name: string; description: string; stars: number; topics: string[] }> = [];
  let page = 1;
  while (true) {
    const url = `https://api.github.com/orgs/${ORG}/repos?type=public&per_page=100&page=${page}`;
    const res = await fetch(url, { headers: ghHeaders });
    if (!res.ok) break;
    const data = await res.json() as Array<Record<string, unknown>>;
    if (!data.length) break;
    for (const r of data) {
      repos.push({
        name: r.name as string,
        description: (r.description as string) ?? "",
        stars: (r.stargazers_count as number) ?? 0,
        topics: (r.topics as string[]) ?? [],
      });
    }
    if (data.length < 100) break;
    page++;
  }
  repos.sort((a, b) => b.stars - a.stars);
  cacheSet(cacheKey, JSON.stringify(repos));
  return repos;
}

export function registerBackstageOrgTools(server: McpServer): void {
  server.tool(
    "backstageorg_list_repos",
    "List all public repositories in the github.com/backstage organization — sorted by stars. Includes backstage/backstage, backstage/community-plugins, backstage/mkdocs-monorepo-plugin, backstage/backstage-plugins, and more.",
    {},
    async () => {
      const repos = await listOrgRepos();
      const lines = [
        `# github.com/backstage — ${repos.length} Public Repositories\n`,
        ...repos.map(
          (r) =>
            `- **${r.name}** ⭐${r.stars}${r.description ? ` — ${r.description}` : ""}${r.topics.length ? ` [${r.topics.join(", ")}]` : ""}`
        ),
      ];
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "backstageorg_get_repo_readme",
    "Get the README for any repository in the github.com/backstage organization (e.g. 'backstage', 'community-plugins', 'mkdocs-monorepo-plugin', 'canon-redirect'). Use backstageorg_list_repos to discover repo names.",
    {
      repo: z.string().describe("Repository name (e.g. 'backstage', 'community-plugins', 'mkdocs-monorepo-plugin')"),
      branch: z.string().optional().describe("Branch name (default: 'main', backstage/backstage uses 'master')"),
    },
    async ({ repo, branch }) => {
      const defaultBranch = repo === "backstage" ? "master" : "main";
      const targetBranch = branch ?? defaultBranch;
      let readme = "";
      try {
        readme = await fetchRaw(ORG, repo, "README.md", targetBranch);
      } catch {
        return textResult(`README not found for ${ORG}/${repo} on branch '${targetBranch}'.`);
      }
      return textResult(
        `# github.com/${ORG}/${repo}\nBranch: ${targetBranch}\n\n${readme}`
      );
    }
  );

  server.tool(
    "backstageorg_search_repos",
    "Search repositories in the github.com/backstage organization by name or description keyword.",
    {
      query: z.string().describe("Search keyword (case-insensitive)"),
    },
    async ({ query }) => {
      const repos = await listOrgRepos();
      const queryLower = query.toLowerCase();
      const matches = repos.filter(
        (r) =>
          r.name.toLowerCase().includes(queryLower) ||
          r.description.toLowerCase().includes(queryLower) ||
          r.topics.some((t) => t.toLowerCase().includes(queryLower))
      );
      if (matches.length === 0) {
        return textResult(`No repositories found matching "${query}" in github.com/backstage.`);
      }
      const lines = [
        `# Backstage Org — Search: "${query}" (${matches.length} repos)\n`,
        ...matches.map(
          (r) =>
            `- **${r.name}** ⭐${r.stars}${r.description ? ` — ${r.description}` : ""}`
        ),
      ];
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "backstageorg_get_backstage_plugins",
    "List all Backstage MCP and integration plugins from github.com/backstage/backstage-plugins — covers MCP extras (scaffolder, techdocs, catalog), Lightspeed AI, and other Backstage-specific plugins.",
    {},
    async () => {
      // backstage-plugins lives at redhat-developer/backstage-plugins, not backstage org, but backstage org has a mirror
      // Check backstage org first, then fall back to redhat-developer
      let content = "";
      try {
        content = await fetchRaw("redhat-developer", "backstage-plugins", "README.md", "main");
        content = `Source: github.com/redhat-developer/backstage-plugins\n\n${content}`;
      } catch {
        try {
          content = await fetchRaw(ORG, "backstage-plugins", "README.md", "main");
          content = `Source: github.com/${ORG}/backstage-plugins\n\n${content}`;
        } catch {
          content = "README not found. See: github.com/redhat-developer/backstage-plugins";
        }
      }
      return textResult(`# Backstage — Backstage Plugins\n\n${content}`);
    }
  );
}
