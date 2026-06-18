import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

/**
 * VS Code documentation — full code.visualstudio.com/docs coverage
 * (repo microsoft/vscode-docs, docs/**).
 *
 * Covers every theme and sub-theme: getstarted, editor, languages, debugtest,
 * sourcecontrol, terminal, copilot, chat, agents, devcontainers, remote,
 * setup, configure, and more.
 */
const OWNER = "microsoft";
const REPO = "vscode-docs";
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

export function registerVsCodeDocsTools(server: McpServer): void {
  server.tool(
    "vscode_list_sections",
    "List the top-level VS Code documentation sections (getstarted, editor, languages, debugtest, sourcecontrol, terminal, copilot, devcontainers, remote, …).",
    {},
    async () => {
      const items = await listContents(OWNER, REPO, BASE);
      const lines = ["# VS Code Documentation — sections (code.visualstudio.com/docs)\n"];
      for (const item of items) {
        if (item.type === "dir") lines.push(`- ${item.name}/`);
        else if (item.name.endsWith(".md"))
          lines.push(`- ${item.name.replace(".md", "")}`);
      }
      lines.push("\nUse vscode_list_pages { section } then vscode_get_page { slug }.");
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "vscode_list_pages",
    "List the documentation pages within a VS Code docs section, e.g. 'copilot', 'editor', 'devcontainers'.",
    {
      section: z
        .string()
        .describe("Section name from vscode_list_sections, e.g. 'copilot'"),
    },
    async ({ section }) => {
      const files = await listMarkdown(`${BASE}/${section}`);
      if (files.length === 0)
        return textResult(`No pages in section '${section}'. Use vscode_list_sections.`);
      const prefix = `${BASE}/`;
      const lines = [`# VS Code docs — ${section} (${files.length} pages)\n`];
      for (const f of files) {
        const slug = f.path.replace(prefix, "").replace(".md", "");
        lines.push(`- slug: ${slug}`);
      }
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "vscode_get_page",
    "Get a specific VS Code documentation page by slug (path relative to docs/, e.g. 'copilot/overview' or 'devcontainers/containers').",
    {
      slug: z
        .string()
        .describe("Page path relative to docs/ (no .md). Use vscode_list_pages to discover."),
    },
    async ({ slug }) => {
      const clean = slug.replace(/\.md$/, "");
      try {
        return textResult(await fetchRaw(OWNER, REPO, `${BASE}/${clean}.md`));
      } catch {
        return textResult(
          `Page not found: ${slug}. Use vscode_list_pages { section } to discover slugs.`
        );
      }
    }
  );

  server.tool(
    "vscode_search",
    "Search a VS Code documentation section for a keyword or phrase. Scope to a section (e.g. 'copilot', 'editor') for fast results.",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
      section: z
        .string()
        .optional()
        .describe("Optional section to scope (recommended), e.g. 'copilot'. Defaults to 'copilot'."),
    },
    async ({ query, section }) => {
      const scope = section ?? "copilot";
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
          ? `# VS Code docs results for "${query}" in '${scope}' (${matches.length})\n\n${matches.join("\n\n")}`
          : `No results for "${query}" in section '${scope}'.`
      );
    }
  );
}
