import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

/**
 * Azure Well-Architected Framework (WAF) — repo MicrosoftDocs/well-architected,
 * well-architected/** . Cached, offline-capable copy of WAF (the five pillars:
 * Reliability, Security, Cost Optimization, Operational Excellence, Performance
 * Efficiency, plus service guides and workloads). Complements the live
 * microsoft-learn federation with a scrape-based fallback.
 */
const OWNER = "MicrosoftDocs";
const REPO = "well-architected";
const BASE = "well-architected";

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

export function registerAzureWafTools(server: McpServer): void {
  server.tool(
    "waf_list_sections",
    "List the Well-Architected Framework areas (reliability, security, cost-optimization, operational-excellence, performance-efficiency, service-guides, …).",
    {},
    async () => {
      const items = await listContents(OWNER, REPO, BASE);
      const lines = ["# Azure Well-Architected Framework — areas\n"];
      for (const item of items) {
        if (item.type === "dir") lines.push(`- ${item.name}/`);
        else if (item.name.endsWith(".md"))
          lines.push(`- ${item.name.replace(".md", "")}`);
      }
      lines.push("\nUse waf_list_pages { section } then waf_get_page { slug }.");
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "waf_list_pages",
    "List the pages within a WAF area, e.g. 'reliability', 'security', 'cost-optimization'.",
    {
      section: z.string().describe("Area name from waf_list_sections, e.g. 'reliability'"),
    },
    async ({ section }) => {
      const files = await listMarkdown(`${BASE}/${section}`);
      if (files.length === 0)
        return textResult(`No pages in '${section}'. Use waf_list_sections.`);
      const prefix = `${BASE}/`;
      const lines = [`# WAF — ${section} (${files.length} pages)\n`];
      for (const f of files) {
        const slug = f.path.replace(prefix, "").replace(".md", "");
        lines.push(`- slug: ${slug}`);
      }
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "waf_get_page",
    "Get a specific Well-Architected Framework page by slug (path relative to well-architected/, e.g. 'reliability/principles').",
    {
      slug: z.string().describe("Page path relative to well-architected/ (no .md)."),
    },
    async ({ slug }) => {
      const clean = slug.replace(/\.md$/, "");
      try {
        return textResult(await fetchRaw(OWNER, REPO, `${BASE}/${clean}.md`));
      } catch {
        try {
          return textResult(await fetchRaw(OWNER, REPO, `${BASE}/${clean}/index.md`));
        } catch {
          return textResult(`Page not found: ${slug}. Use waf_list_pages.`);
        }
      }
    }
  );

  server.tool(
    "waf_search",
    "Search a WAF area for a keyword or phrase. Scope to a pillar (e.g. 'reliability', 'security', 'cost-optimization') for fast results.",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
      section: z
        .string()
        .optional()
        .describe("Optional pillar to scope (recommended), e.g. 'reliability'. Defaults to 'reliability'."),
    },
    async ({ query, section }) => {
      const scope = section ?? "reliability";
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
          ? `# WAF results for "${query}" in '${scope}' (${matches.length})\n\n${matches.join("\n\n")}`
          : `No results for "${query}" in WAF '${scope}'.`
      );
    }
  );
}
