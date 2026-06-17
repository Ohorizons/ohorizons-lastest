import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents, fetchUrl } from "../shared/github-fetcher.js";
import { htmlToText } from "../shared/html-utils.js";
import { textResult } from "../shared/types.js";

const COMMUNITY_OWNER = "backstage";
const COMMUNITY_REPO = "community-plugins";
const CORE_OWNER = "backstage";
const CORE_REPO = "backstage";
const PLUGIN_DIRECTORY_URL = "https://backstage.io/plugins/";

export function registerBackstagePluginsTools(server: McpServer): void {
  // ── Plugin Directory ──────────────────────────────────────────────────────

  server.tool(
    "backstageplugins_list_directory",
    "List all Backstage plugins from backstage.io/plugins/ — 5 core features + 198+ active community plugins with names, owners, categories, and descriptions. Use backstageplugins_get_community_plugin or backstageplugins_get_core_plugin for details.",
    {},
    async () => {
      const html = await fetchUrl(PLUGIN_DIRECTORY_URL);
      const text = htmlToText(html);
      return textResult(`# Backstage Plugin Directory\nSource: ${PLUGIN_DIRECTORY_URL}\n\n${text}`);
    }
  );

  // ── Community Plugins ─────────────────────────────────────────────────────

  server.tool(
    "backstageplugins_list_community",
    "List all 105 workspaces in github.com/backstage/community-plugins — the official community plugin repository. Returns workspace names for use with backstageplugins_get_community_plugin.",
    {},
    async () => {
      const items = await listContents(COMMUNITY_OWNER, COMMUNITY_REPO, "workspaces");
      const dirs = items.filter((i) => i.type === "dir").map((i) => i.name);
      const lines = [
        `# Community Plugins — ${dirs.length} Workspaces`,
        `Source: github.com/${COMMUNITY_OWNER}/${COMMUNITY_REPO}/tree/main/workspaces\n`,
        ...dirs.map((d) => `- ${d}`),
      ];
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "backstageplugins_get_community_plugin",
    "Get README and package details for a specific community plugin workspace (e.g. 'argocd', 'datadog', 'tech-insights', 'kubernetes', 'rbac'). Use backstageplugins_list_community to discover names.",
    {
      workspace: z
        .string()
        .describe("Workspace name (e.g. 'argocd', 'tech-insights', 'datadog')"),
    },
    async ({ workspace }) => {
      const basePath = `workspaces/${workspace}`;
      let readme = "";
      try {
        readme = await fetchRaw(COMMUNITY_OWNER, COMMUNITY_REPO, `${basePath}/README.md`);
      } catch {
        readme = "(No README found at workspace root)";
      }
      // Try to list plugins inside the workspace
      let pluginList = "";
      try {
        const contents = await listContents(COMMUNITY_OWNER, COMMUNITY_REPO, `${basePath}/plugins`);
        const plugins = contents.filter((i) => i.type === "dir").map((i) => i.name);
        pluginList = plugins.length
          ? `\n\n## Plugin packages in this workspace\n${plugins.map((p) => `- ${p}`).join("\n")}`
          : "";
      } catch {
        /* no plugins dir */
      }
      return textResult(
        `# Community Plugin: ${workspace}\nSource: github.com/${COMMUNITY_OWNER}/${COMMUNITY_REPO}/tree/main/workspaces/${workspace}\n\n${readme}${pluginList}`
      );
    }
  );

  server.tool(
    "backstageplugins_search_community",
    "Search community plugins by keyword across workspace names and README files. Returns matching workspaces with excerpts.",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
    },
    async ({ query }) => {
      const queryLower = query.toLowerCase();
      const items = await listContents(COMMUNITY_OWNER, COMMUNITY_REPO, "workspaces");
      const dirs = items.filter((i) => i.type === "dir").map((i) => i.name);

      // First check names
      const nameMatches = dirs.filter((d) => d.toLowerCase().includes(queryLower));

      // Then check READMEs for non-name matches (up to 15 total)
      const results: string[] = [];
      for (const d of nameMatches.slice(0, 8)) {
        results.push(`### ${d} (name match)\ngithub.com/${COMMUNITY_OWNER}/${COMMUNITY_REPO}/tree/main/workspaces/${d}`);
      }
      if (results.length < 15) {
        const toCheck = dirs.filter((d) => !d.toLowerCase().includes(queryLower));
        for (const d of toCheck) {
          if (results.length >= 15) break;
          try {
            const readme = await fetchRaw(COMMUNITY_OWNER, COMMUNITY_REPO, `workspaces/${d}/README.md`);
            if (!readme.toLowerCase().includes(queryLower)) continue;
            const excerpt = readme
              .split("\n")
              .find((l) => l.toLowerCase().includes(queryLower))
              ?.trim() ?? "";
            results.push(`### ${d}\n> ${excerpt}\ngithub.com/${COMMUNITY_OWNER}/${COMMUNITY_REPO}/tree/main/workspaces/${d}`);
          } catch {
            /* skip */
          }
        }
      }

      if (results.length === 0) {
        return textResult(`No community plugins found matching "${query}".`);
      }
      return textResult(
        `# Community Plugin Search: "${query}" (${results.length} results)\n\n${results.join("\n\n")}`
      );
    }
  );

  // ── Core Plugins ──────────────────────────────────────────────────────────

  server.tool(
    "backstageplugins_list_core",
    "List all 154 core plugin packages in github.com/backstage/backstage/plugins — the official Backstage monorepo plugins (auth providers, catalog, scaffolder, techdocs, kubernetes, search, etc.).",
    {},
    async () => {
      const items = await listContents(CORE_OWNER, CORE_REPO, "plugins", "master");
      const entries = items
        .filter((i) => i.type === "dir" && i.name !== "README.md")
        .map((i) => `- ${i.name}`);
      const lines = [
        `# Backstage Core Plugins — ${entries.length} packages`,
        `Source: github.com/${CORE_OWNER}/${CORE_REPO}/tree/master/plugins\n`,
        ...entries,
      ];
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "backstageplugins_get_core_plugin",
    "Get README for a specific core Backstage plugin from the main monorepo (e.g. 'catalog', 'scaffolder', 'techdocs', 'auth-backend-module-github-provider', 'kubernetes'). Use backstageplugins_list_core to discover names.",
    {
      plugin: z
        .string()
        .describe(
          "Plugin directory name (e.g. 'catalog', 'scaffolder', 'kubernetes', 'auth-backend-module-github-provider')"
        ),
    },
    async ({ plugin }) => {
      let readme = "";
      try {
        readme = await fetchRaw(CORE_OWNER, CORE_REPO, `plugins/${plugin}/README.md`, "master");
      } catch {
        // try package.json for description at least
        try {
          const pkg = await fetchRaw(CORE_OWNER, CORE_REPO, `plugins/${plugin}/package.json`, "master");
          const parsed = JSON.parse(pkg);
          readme = `# ${parsed.name}\n\n**Description:** ${parsed.description ?? "n/a"}\n**Version:** ${parsed.version ?? "n/a"}`;
        } catch {
          readme = `(No README or package.json found for plugin: ${plugin})`;
        }
      }
      return textResult(
        `# Core Plugin: ${plugin}\nSource: github.com/${CORE_OWNER}/${CORE_REPO}/tree/master/plugins/${plugin}\n\n${readme}`
      );
    }
  );
}
