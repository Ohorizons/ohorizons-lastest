import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listTree, fetchUrl } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "backstage";
const REPO = "backstage";
const BRANCH = "master";
const BASE_PATH = "docs";
const API_BASE = "https://backstage.io/api/stable";

async function listDocFiles(): Promise<Array<{ path: string }>> {
  const allFiles = await listTree(OWNER, REPO, BRANCH, `${BASE_PATH}/`);
  return allFiles
    .filter((f) => f.path.endsWith(".md"))
    .map((f) => ({ path: f.path }));
}

async function fetchSection(
  sectionPath: string
): Promise<string> {
  const files = await listDocFiles();
  const sectionFiles = files.filter((f) =>
    f.path.startsWith(`${BASE_PATH}/${sectionPath}/`)
  );
  const contents: string[] = [];
  for (const file of sectionFiles) {
    try {
      const content = await fetchRaw(OWNER, REPO, file.path, BRANCH);
      const name = file.path.replace(`${BASE_PATH}/`, "");
      contents.push(`\n---\n## ${name}\n\n${content}`);
    } catch {
      /* skip files that can't be fetched */
    }
  }
  return contents.join("\n");
}

export function registerBackstageDocsTools(server: McpServer): void {
  server.tool(
    "backstagedocs_list_sections",
    "List all Backstage documentation sections and pages with slugs — covers getting started, catalog, templates, TechDocs, plugins, auth, permissions, deployment, integrations, and more. Use slugs with backstagedocs_get_page.",
    {},
    async () => {
      const files = await listDocFiles();
      const sections: Record<string, string[]> = {};

      for (const file of files) {
        const rel = file.path.replace(`${BASE_PATH}/`, "");
        const parts = rel.split("/");
        const section = parts.length > 1 ? parts[0] : "root";
        if (!sections[section]) sections[section] = [];
        const slug = rel.replace(/\.md$/, "");
        sections[section].push(`  - ${parts.at(-1)} -> slug: ${slug}`);
      }

      const lines: string[] = [
        `# Backstage Documentation (${files.length} pages)\n`,
        `Source: github.com/${OWNER}/${REPO}/tree/${BRANCH}/${BASE_PATH}\n`,
      ];

      for (const [section, pages] of Object.entries(sections)) {
        lines.push(`\n## ${section}/`, ...pages);
      }

      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "backstagedocs_get_page",
    "Get a specific Backstage documentation page by path slug (e.g. 'overview/what-is-backstage', 'features/software-catalog/software-catalog-overview', 'plugins/create-a-plugin')",
    {
      slug: z.string().describe(
        "Page path relative to docs/ (e.g. 'overview/what-is-backstage', 'getting-started/index'). Use backstagedocs_list_sections to discover slugs."
      ),
    },
    async ({ slug }) => {
      const cleanSlug = slug.replace(/\.md$/, "");
      const path = `${BASE_PATH}/${cleanSlug}.md`;
      try {
        const content = await fetchRaw(OWNER, REPO, path, BRANCH);
        return textResult(content);
      } catch {
        try {
          const content = await fetchRaw(
            OWNER,
            REPO,
            `${BASE_PATH}/${cleanSlug}/index.md`,
            BRANCH
          );
          return textResult(content);
        } catch {
          return textResult(
            `Page not found: ${path}\n\nUse backstagedocs_list_sections to see available pages.`
          );
        }
      }
    }
  );

  server.tool(
    "backstagedocs_search",
    "Search across all Backstage documentation for a keyword or phrase — covers catalog, scaffolder, TechDocs, plugins, auth, deployment, and more",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
    },
    async ({ query }) => {
      const files = await listDocFiles();
      const queryLower = query.toLowerCase();
      const matches: string[] = [];
      for (const file of files) {
        if (matches.length >= 10) break;
        try {
          const content = await fetchRaw(OWNER, REPO, file.path, BRANCH);
          if (!content.toLowerCase().includes(queryLower)) continue;
          const matchingLines = content
            .split("\n")
            .filter((line) => line.toLowerCase().includes(queryLower))
            .slice(0, 3)
            .map((l) => `  > ${l.trim()}`);
          const slug = file.path
            .replace(`${BASE_PATH}/`, "")
            .replace(/\.md$/, "");
          const header = `### ${file.path}\nSlug: ${slug}`;
          matches.push(`${header}\n${matchingLines.join("\n")}`);
        } catch {
          /* skip files that can't be fetched */
        }
      }
      if (matches.length === 0) {
        return textResult(
          `No results found for "${query}" in Backstage docs.`
        );
      }
      return textResult(
        `# Search results for "${query}" (${matches.length} pages)\n\n${matches.join("\n\n")}`
      );
    }
  );

  server.tool(
    "backstagedocs_get_catalog",
    "Get Backstage Software Catalog documentation — entities, YAML format, descriptor format, processors, relations, lifecycle, and catalog customization",
    {},
    async () => {
      const content = await fetchSection("features/software-catalog");
      return textResult(
        `# Backstage - Software Catalog Documentation\n${content}`
      );
    }
  );

  server.tool(
    "backstagedocs_get_software_templates",
    "Get Backstage Software Templates (scaffolder) documentation — template YAML, actions, custom actions, input forms, Golden Paths, secrets schema",
    {},
    async () => {
      const content = await fetchSection("features/software-templates");
      return textResult(
        `# Backstage - Software Templates Documentation\n${content}`
      );
    }
  );

  server.tool(
    "backstagedocs_get_plugins",
    "Get Backstage plugin development documentation — creating plugins, plugin API, frontend/backend plugins, composability, testing, internationalization, and proxying",
    {},
    async () => {
      const content = await fetchSection("plugins");
      return textResult(
        `# Backstage - Plugin Development Documentation\n${content}`
      );
    }
  );

  server.tool(
    "backstagedocs_get_api_reference",
    "Get Backstage TypeDoc API reference — list all ~130 packages or get details for a specific package (classes, interfaces, functions, type aliases)",
    {
      module: z
        .string()
        .optional()
        .describe(
          "Package name without @backstage/ prefix (e.g. 'core-plugin-api', 'catalog-model', 'plugin-scaffolder'). Omit to list all modules."
        ),
    },
    async ({ module }) => {
      if (!module) {
        const content = await fetchUrl(`${API_BASE}/modules.html`);
        return textResult(
          `# Backstage API Reference — All Modules\n\n${content}`
        );
      }
      const slug = `_backstage_${module}`;
      const url = `${API_BASE}/modules/${slug}.html`;
      try {
        const content = await fetchUrl(url);
        return textResult(
          `# @backstage/${module} — API Reference\n\n${content}`
        );
      } catch {
        return textResult(
          `Module not found: @backstage/${module}\n\nURL tried: ${url}\n\nUse backstagedocs_get_api_reference (without module param) to list all available modules.`
        );
      }
    }
  );
}
