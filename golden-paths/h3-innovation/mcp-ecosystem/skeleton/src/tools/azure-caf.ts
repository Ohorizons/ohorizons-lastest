import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

/**
 * Azure Cloud Adoption Framework (CAF) — repo MicrosoftDocs/cloud-adoption-framework,
 * docs/**. Cached, offline-capable copy of CAF (Strategy, Plan, Ready, Adopt,
 * Govern, Manage, Secure, Organize, Scenarios, AI). Complements the live
 * microsoft-learn federation with a scrape-based fallback for the local
 * installation phase.
 */
const OWNER = "MicrosoftDocs";
const REPO = "cloud-adoption-framework";
const BASE = "docs";

async function listMarkdown(
  path: string,
  depth = 0,
  maxDepth = 3
): Promise<Array<{ name: string; path: string }>> {
  if (depth > maxDepth) return [];
  const items = await listContents(OWNER, REPO, path);
  const out: Array<{ name: string; path: string }> = [];
  for (const item of items) {
    if (item.type === "file" && item.name.endsWith(".md")) {
      out.push({ name: item.name, path: item.path });
    } else if (item.type === "dir") {
      out.push(...(await listMarkdown(item.path, depth + 1, maxDepth)));
    }
  }
  return out;
}

export function registerAzureCafTools(server: McpServer): void {
  server.tool(
    "caf_list_sections",
    "List the Cloud Adoption Framework methodologies (strategy, plan, ready, adopt, govern, manage, secure, organize, scenarios, ai, …).",
    {},
    async () => {
      const items = await listContents(OWNER, REPO, BASE);
      const lines = ["# Azure Cloud Adoption Framework — methodologies\n"];
      for (const item of items) {
        if (item.type === "dir") lines.push(`- ${item.name}/`);
        else if (item.name.endsWith(".md"))
          lines.push(`- ${item.name.replace(".md", "")}`);
      }
      lines.push("\nUse caf_list_pages { section } then caf_get_page { slug }.");
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "caf_list_pages",
    "List the pages within a CAF methodology, e.g. 'ready', 'govern', 'secure', 'scenarios'.",
    {
      section: z.string().describe("Methodology name from caf_list_sections, e.g. 'ready'"),
    },
    async ({ section }) => {
      const files = await listMarkdown(`${BASE}/${section}`);
      if (files.length === 0)
        return textResult(`No pages in '${section}'. Use caf_list_sections.`);
      const prefix = `${BASE}/`;
      const lines = [`# CAF — ${section} (${files.length} pages)\n`];
      for (const f of files) {
        const slug = f.path.replace(prefix, "").replace(".md", "");
        lines.push(`- slug: ${slug}`);
      }
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "caf_get_page",
    "Get a specific Cloud Adoption Framework page by slug (path relative to docs/, e.g. 'ready/landing-zone/index').",
    {
      slug: z.string().describe("Page path relative to docs/ (no .md)."),
    },
    async ({ slug }) => {
      const clean = slug.replace(/\.md$/, "");
      try {
        return textResult(await fetchRaw(OWNER, REPO, `${BASE}/${clean}.md`));
      } catch {
        try {
          return textResult(await fetchRaw(OWNER, REPO, `${BASE}/${clean}/index.md`));
        } catch {
          return textResult(`Page not found: ${slug}. Use caf_list_pages.`);
        }
      }
    }
  );

  server.tool(
    "caf_search",
    "Search a CAF methodology for a keyword or phrase. Scope to a section (e.g. 'ready', 'govern', 'secure') for fast results.",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
      section: z
        .string()
        .optional()
        .describe("Optional methodology to scope (recommended), e.g. 'ready'. Defaults to 'ready'."),
    },
    async ({ query, section }) => {
      const scope = section ?? "ready";
      const files = await listMarkdown(`${BASE}/${scope}`);
      const q = query.toLowerCase();
      const prefix = `${BASE}/`;
      const matches: string[] = [];
      for (const f of files) {
        if (matches.length >= 10) break;
        try {
          const content = await fetchRaw(OWNER, REPO, f.path);
          if (content.toLowerCase().includes(q)) {
            const hits = content
              .split("\n")
              .filter((l) => l.toLowerCase().includes(q))
              .slice(0, 3)
              .map((l) => `  > ${l.trim()}`);
            const slug = f.path.replace(prefix, "").replace(".md", "");
            matches.push(`### ${slug}\n${hits.join("\n")}`);
          }
        } catch {
          /* skip */
        }
      }
      return textResult(
        matches.length
          ? `# CAF results for "${query}" in '${scope}' (${matches.length})\n\n${matches.join("\n\n")}`
          : `No results for "${query}" in CAF '${scope}'.`
      );
    }
  );
}
