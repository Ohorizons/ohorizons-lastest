import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

/**
 * GitHub Docs — full docs.github.com coverage (repo github/docs, content/**).
 *
 * Covers every theme: get-started, actions, code-security (GHAS, CodeQL,
 * Dependabot, secret scanning), authentication (OIDC), packages (GHCR),
 * codespaces, copilot, repositories, organizations, and more. Critical for the
 * installation phase (OIDC federation, Actions, branch protection, GHAS).
 *
 * The github-copilot-docs module remains the deep, Copilot-specific surface;
 * this module is the broad, whole-site surface.
 */
const OWNER = "github";
const REPO = "docs";
const BASE = "content";

async function listMarkdown(
  path: string,
  depth = 0,
  maxDepth = 3,
  limit = 4000
): Promise<Array<{ name: string; path: string }>> {
  if (depth > maxDepth) return [];
  const items = await listContents(OWNER, REPO, path);
  const out: Array<{ name: string; path: string }> = [];
  for (const item of items) {
    if (out.length >= limit) break;
    if (item.type === "file" && item.name.endsWith(".md")) {
      out.push({ name: item.name, path: item.path });
    } else if (item.type === "dir") {
      out.push(...(await listMarkdown(item.path, depth + 1, maxDepth, limit)));
    }
  }
  return out;
}

export function registerGitHubDocsTools(server: McpServer): void {
  server.tool(
    "ghdocs_list_sections",
    "List the top-level GitHub documentation sections (actions, code-security, authentication, packages, codespaces, get-started, copilot, …) with the slug to use in ghdocs_get_page.",
    {},
    async () => {
      const items = await listContents(OWNER, REPO, BASE);
      const lines = ["# GitHub Documentation — sections (docs.github.com)\n"];
      for (const item of items) {
        if (item.type === "dir") lines.push(`- ${item.name}/`);
        else if (item.name.endsWith(".md"))
          lines.push(`- ${item.name.replace(".md", "")}`);
      }
      lines.push(
        "\nUse ghdocs_list_pages { section } to see pages, then ghdocs_get_page { slug }."
      );
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "ghdocs_list_pages",
    "List the documentation pages (slugs) within a GitHub docs section, e.g. 'actions', 'code-security', 'authentication', 'packages'.",
    {
      section: z
        .string()
        .describe("Top-level section name from ghdocs_list_sections, e.g. 'actions'"),
    },
    async ({ section }) => {
      const files = await listMarkdown(`${BASE}/${section}`);
      if (files.length === 0)
        return textResult(
          `No pages found in section '${section}'. Use ghdocs_list_sections.`
        );
      const prefix = `${BASE}/`;
      const lines = [`# GitHub docs — ${section} (${files.length} pages)\n`];
      for (const f of files) {
        const slug = f.path.replace(prefix, "").replace(".md", "");
        lines.push(`- slug: ${slug}`);
      }
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "ghdocs_get_page",
    "Get a specific GitHub documentation page by slug (path relative to content/, e.g. 'actions/security-guides/automatic-token-authentication' or 'authentication/keeping-your-account-and-data-secure/about-authentication-to-github').",
    {
      slug: z
        .string()
        .describe("Page path relative to content/ (no .md). Use ghdocs_list_pages to discover."),
    },
    async ({ slug }) => {
      const clean = slug.replace(/\.md$/, "");
      try {
        return textResult(await fetchRaw(OWNER, REPO, `${BASE}/${clean}.md`));
      } catch {
        try {
          return textResult(
            await fetchRaw(OWNER, REPO, `${BASE}/${clean}/index.md`)
          );
        } catch {
          return textResult(
            `Page not found: ${slug}. Use ghdocs_list_pages { section } to discover slugs.`
          );
        }
      }
    }
  );

  server.tool(
    "ghdocs_search",
    "Search a GitHub documentation section for a keyword or phrase. Scope to a section (e.g. 'actions', 'code-security') for fast, relevant results.",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
      section: z
        .string()
        .optional()
        .describe(
          "Optional section to scope the search (recommended), e.g. 'actions'. Defaults to 'get-started'."
        ),
    },
    async ({ query, section }) => {
      const scope = section ?? "get-started";
      const files = await listMarkdown(`${BASE}/${scope}`);
      const q = query.toLowerCase();
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
            const slug = f.path.replace(`${BASE}/`, "").replace(".md", "");
            matches.push(`### ${slug}\n${hits.join("\n")}`);
          }
        } catch {
          /* skip */
        }
      }
      return textResult(
        matches.length
          ? `# GitHub docs results for "${query}" in '${scope}' (${matches.length})\n\n${matches.join("\n\n")}`
          : `No results for "${query}" in section '${scope}'.`
      );
    }
  );
}
