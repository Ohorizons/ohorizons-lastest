import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchRaw, listContents } from "../shared/github-fetcher.js";
import { textResult } from "../shared/types.js";

const OWNER = "github";
const REPO = "docs";
const BASE_PATH = "content/copilot";

async function listMarkdownFiles(
  path: string,
  depth = 0,
  maxDepth = 3
): Promise<Array<{ name: string; path: string }>> {
  if (depth > maxDepth) return [];
  const items = await listContents(OWNER, REPO, path);
  const results: Array<{ name: string; path: string }> = [];
  for (const item of items) {
    if (item.type === "file" && item.name.endsWith(".md")) {
      results.push({ name: item.name, path: item.path });
    } else if (item.type === "dir") {
      const subItems = await listMarkdownFiles(item.path, depth + 1, maxDepth);
      results.push(...subItems);
    }
  }
  return results;
}

export function registerGitHubCopilotDocsTools(server: McpServer): void {
  server.tool(
    "copilotdocs_list_sections",
    "List all GitHub Copilot documentation sections and pages with paths for use with copilotdocs_get_page",
    {},
    async () => {
      const topLevel = await listContents(OWNER, REPO, BASE_PATH);
      const lines: string[] = ["# GitHub Copilot Documentation\n"];
      for (const item of topLevel) {
        if (item.type === "file" && item.name.endsWith(".md")) {
          const slug = item.name.replace(".md", "");
          lines.push(`- ${item.name} -> slug: ${slug}`);
        } else if (item.type === "dir") {
          lines.push(`\n## ${item.name}/`);
          const subItems = await listContents(OWNER, REPO, item.path);
          for (const sub of subItems) {
            if (sub.type === "file" && sub.name.endsWith(".md")) {
              const slug = `${item.name}/${sub.name.replace(".md", "")}`;
              lines.push(`  - ${sub.name} -> slug: ${slug}`);
            } else if (sub.type === "dir") {
              lines.push(`  - ${sub.name}/`);
              const subSubItems = await listContents(OWNER, REPO, sub.path);
              for (const subsub of subSubItems) {
                if (subsub.type === "file" && subsub.name.endsWith(".md")) {
                  const slug = `${item.name}/${sub.name}/${subsub.name.replace(".md", "")}`;
                  lines.push(`    - ${subsub.name} -> slug: ${slug}`);
                }
              }
            }
          }
        }
      }
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "copilotdocs_get_page",
    "Get a specific GitHub Copilot documentation page by path slug",
    {
      slug: z.string().describe(
        "Page path relative to content/copilot/ (e.g. 'about-github-copilot/what-is-github-copilot'). Use copilotdocs_list_sections to discover slugs."
      ),
    },
    async ({ slug }) => {
      const cleanSlug = slug.replace(/\.md$/, "");
      const path =
        cleanSlug === "index" || cleanSlug === ""
          ? `${BASE_PATH}/index.md`
          : `${BASE_PATH}/${cleanSlug}.md`;
      try {
        const content = await fetchRaw(OWNER, REPO, path);
        return textResult(content);
      } catch {
        try {
          const content = await fetchRaw(
            OWNER,
            REPO,
            `${BASE_PATH}/${cleanSlug}/index.md`
          );
          return textResult(content);
        } catch {
          return textResult(
            `Page not found: ${path}\n\nUse copilotdocs_list_sections to see available pages.`
          );
        }
      }
    }
  );

  server.tool(
    "copilotdocs_search",
    "Search across all GitHub Copilot documentation for a keyword or phrase",
    {
      query: z.string().describe("Search keyword or phrase (case-insensitive)"),
    },
    async ({ query }) => {
      const files = await listMarkdownFiles(BASE_PATH);
      const queryLower = query.toLowerCase();
      const matches: string[] = [];
      for (const file of files) {
        if (matches.length >= 10) break;
        try {
          const content = await fetchRaw(OWNER, REPO, file.path);
          if (content.toLowerCase().includes(queryLower)) {
            const lines = content.split("\n");
            const matchingLines: string[] = [];
            for (const line of lines) {
              if (line.toLowerCase().includes(queryLower)) {
                matchingLines.push(line.trim());
                if (matchingLines.length >= 3) break;
              }
            }
            const slug = file.path
              .replace(`${BASE_PATH}/`, "")
              .replace(".md", "");
            matches.push(
              `### ${file.path}\nSlug: ${slug}\n${matchingLines.map((l) => `  > ${l}`).join("\n")}`
            );
          }
        } catch {
          /* skip files that can't be fetched */
        }
      }
      if (matches.length === 0) {
        return textResult(
          `No results found for "${query}" in Copilot docs.`
        );
      }
      return textResult(
        `# Search results for "${query}" (${matches.length} pages)\n\n${matches.join("\n\n")}`
      );
    }
  );

  server.tool(
    "copilotdocs_get_customization",
    "Get GitHub Copilot customization docs - custom instructions, agents, skills, prompts. High-value for agent developers.",
    {},
    async () => {
      const files = await listContents(
        OWNER,
        REPO,
        `${BASE_PATH}/customizing-copilot`
      );
      const contents: string[] = [
        "# GitHub Copilot - Customization Documentation\n",
      ];
      for (const file of files) {
        if (file.type === "file" && file.name.endsWith(".md")) {
          try {
            const content = await fetchRaw(OWNER, REPO, file.path);
            contents.push(`\n---\n## ${file.name}\n\n${content}`);
          } catch {
            contents.push(`\n---\n## ${file.name}\n\n(Failed to fetch)`);
          }
        } else if (file.type === "dir") {
          const subFiles = await listContents(OWNER, REPO, file.path);
          for (const sub of subFiles) {
            if (sub.type === "file" && sub.name.endsWith(".md")) {
              try {
                const content = await fetchRaw(OWNER, REPO, sub.path);
                contents.push(
                  `\n---\n## ${file.name}/${sub.name}\n\n${content}`
                );
              } catch {
                contents.push(
                  `\n---\n## ${file.name}/${sub.name}\n\n(Failed to fetch)`
                );
              }
            }
          }
        }
      }
      return textResult(contents.join("\n"));
    }
  );

  server.tool(
    "copilotdocs_get_extensions",
    "Get GitHub Copilot Extensions documentation - building extensions, API reference, extension types",
    {},
    async () => {
      const files = await listContents(
        OWNER,
        REPO,
        `${BASE_PATH}/building-copilot-extensions`
      );
      const contents: string[] = [
        "# GitHub Copilot - Extensions Documentation\n",
      ];
      for (const file of files) {
        if (file.type === "file" && file.name.endsWith(".md")) {
          try {
            const content = await fetchRaw(OWNER, REPO, file.path);
            contents.push(`\n---\n## ${file.name}\n\n${content}`);
          } catch {
            contents.push(`\n---\n## ${file.name}\n\n(Failed to fetch)`);
          }
        } else if (file.type === "dir") {
          const subFiles = await listContents(OWNER, REPO, file.path);
          for (const sub of subFiles) {
            if (sub.type === "file" && sub.name.endsWith(".md")) {
              try {
                const content = await fetchRaw(OWNER, REPO, sub.path);
                contents.push(
                  `\n---\n## ${file.name}/${sub.name}\n\n${content}`
                );
              } catch {
                contents.push(
                  `\n---\n## ${file.name}/${sub.name}\n\n(Failed to fetch)`
                );
              }
            }
          }
        }
      }
      return textResult(contents.join("\n"));
    }
  );
}
