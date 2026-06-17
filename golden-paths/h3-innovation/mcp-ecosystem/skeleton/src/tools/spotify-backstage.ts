import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { fetchUrl } from "../shared/github-fetcher.js";
import { htmlToText, extractLinks } from "../shared/html-utils.js";
import { textResult } from "../shared/types.js";

const BASE = "https://backstage.spotify.com";
const DOCS_BASE = `${BASE}/docs`;

// Known Spotify Backstage doc sections discovered from nav crawl
const KNOWN_SECTIONS: Record<string, string[]> = {
  portal: [
    "getting-started",
    "core-features-and-plugins",
    "core-features-and-plugins/ai-gateway",
    "core-features-and-plugins/aika",
    "core-features-and-plugins/audit-logs",
    "core-features-and-plugins/catalog",
    "core-features-and-plugins/data-experience",
    "core-features-and-plugins/confidence-flags",
    "guides",
    "portal-plugins",
    "security",
    "troubleshooting",
    "changelog",
  ],
  plugins: [
    "getting-started",
    "getting-started/spotify-for-backstage",
    "getting-started/aws-marketplace",
    "soundcheck",
    "insights",
    "rbac",
    "skill-exchange",
  ],
};

async function fetchDocPage(path: string): Promise<string> {
  const url = path.startsWith("http") ? path : `${DOCS_BASE}/${path.replace(/^\/docs\//, "")}`;
  const html = await fetchUrl(url.endsWith("/") ? url : `${url}/`);
  return htmlToText(html);
}

export function registerSpotifyBackstageTools(server: McpServer): void {
  server.tool(
    "spotifybackstage_list_sections",
    "List all known Spotify for Backstage documentation sections at backstage.spotify.com/docs — covers Portal (getting-started, core-features, guides, portal-plugins, security, troubleshooting) and Plugins (soundcheck, insights, rbac, skill-exchange).",
    {},
    async () => {
      const lines = [
        "# Spotify for Backstage — Documentation Sections",
        `Source: ${DOCS_BASE}\n`,
        "## Portal Docs (`/docs/portal/`)",
        ...KNOWN_SECTIONS.portal.map((p) => `  - ${p}  →  slug: portal/${p}`),
        "\n## Plugin Docs (`/docs/plugins/`)",
        ...KNOWN_SECTIONS.plugins.map((p) => `  - ${p}  →  slug: plugins/${p}`),
        "\nUse spotifybackstage_get_page with a slug to fetch content.",
      ];
      return textResult(lines.join("\n"));
    }
  );

  server.tool(
    "spotifybackstage_get_page",
    "Get content from a Spotify for Backstage documentation page by slug (e.g. 'portal/getting-started', 'plugins/soundcheck', 'portal/core-features-and-plugins/catalog'). Use spotifybackstage_list_sections to discover slugs.",
    {
      slug: z
        .string()
        .describe(
          "Doc path slug (e.g. 'portal/getting-started', 'plugins/soundcheck', 'portal/core-features-and-plugins/aika')"
        ),
    },
    async ({ slug }) => {
      const cleanSlug = slug.replace(/^\/docs\//, "").replace(/^\//, "");
      const url = `${DOCS_BASE}/${cleanSlug}/`;
      try {
        const text = await fetchDocPage(url);
        return textResult(
          `# Spotify for Backstage — ${cleanSlug}\nSource: ${url}\n\n${text}`
        );
      } catch {
        return textResult(
          `Page not found: ${url}\n\nUse spotifybackstage_list_sections to see available sections.`
        );
      }
    }
  );

  server.tool(
    "spotifybackstage_get_portal_docs",
    "Get the Portal for Backstage getting-started documentation from backstage.spotify.com — covers licensing, installation, configuration, and initial setup of the commercial Spotify portal.",
    {},
    async () => {
      const text = await fetchDocPage("portal/getting-started");
      return textResult(
        `# Spotify Portal for Backstage — Getting Started\nSource: ${DOCS_BASE}/portal/getting-started/\n\n${text}`
      );
    }
  );

  server.tool(
    "spotifybackstage_get_plugins_docs",
    "Get the Spotify Plugins for Backstage getting-started documentation — covers Soundcheck (standards), Insights (engineering metrics), RBAC (permissions), and Skill Exchange plugins.",
    {},
    async () => {
      const sections = ["getting-started", "soundcheck", "insights", "rbac", "skill-exchange"];
      const contents: string[] = [
        "# Spotify Plugins for Backstage\n",
        `Source: ${DOCS_BASE}/plugins/\n`,
      ];
      for (const section of sections) {
        try {
          const text = await fetchDocPage(`plugins/${section}`);
          contents.push(`\n---\n## ${section}\n\n${text.slice(0, 2000)}`);
        } catch {
          contents.push(`\n---\n## ${section}\n\n(Could not fetch)`);
        }
      }
      return textResult(contents.join("\n"));
    }
  );

  server.tool(
    "spotifybackstage_get_core_features",
    "Get Spotify Portal core features and plugins documentation — covers AI Gateway, Aika (AI assistant), audit logs, catalog, data experience, confidence flags, and more.",
    {
      feature: z
        .string()
        .optional()
        .describe(
          "Specific feature slug (e.g. 'ai-gateway', 'aika', 'catalog', 'audit-logs', 'data-experience'). Omit to get overview."
        ),
    },
    async ({ feature }) => {
      const slug = feature
        ? `portal/core-features-and-plugins/${feature}`
        : "portal/core-features-and-plugins";
      try {
        const text = await fetchDocPage(slug);
        return textResult(
          `# Spotify Portal — ${feature ?? "Core Features & Plugins"}\nSource: ${DOCS_BASE}/${slug}/\n\n${text}`
        );
      } catch {
        return textResult(
          `Feature page not found: ${slug}\n\nAvailable features: ai-gateway, aika, audit-logs, catalog, data-experience, confidence-flags\nUse spotifybackstage_list_sections for the full list.`
        );
      }
    }
  );

  server.tool(
    "spotifybackstage_discover_links",
    "Crawl a Spotify for Backstage docs page and extract all linked doc pages — useful for discovering sub-pages not in the known list.",
    {
      slug: z.string().describe("Starting slug (e.g. 'portal/guides', 'portal/portal-plugins')"),
    },
    async ({ slug }) => {
      const cleanSlug = slug.replace(/^\/docs\//, "").replace(/^\//, "");
      const url = `${DOCS_BASE}/${cleanSlug}/`;
      const html = await fetchUrl(url);
      const links = extractLinks(html, /\/docs\//);
      const docLinks = links
        .filter((l) => l.includes("/docs/") && !l.includes("/assets/") && !l.endsWith(".ico") && !l.endsWith(".css"))
        .map((l) => l.replace(/^https:\/\/backstage\.spotify\.com/, ""))
        .sort();
      return textResult(
        `# Doc links discovered on: ${cleanSlug}\nSource: ${url}\n\n${docLinks.map((l) => `- ${l}`).join("\n")}`
      );
    }
  );
}
