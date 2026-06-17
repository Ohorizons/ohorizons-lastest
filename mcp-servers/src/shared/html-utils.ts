/**
 * Strip HTML tags and decode entities to get clean plain text
 * suitable for AI consumption from SSR/Docusaurus pages.
 */
export function htmlToText(html: string): string {
  return html
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
    .replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, "")
    .replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, "")
    .replace(/<header[^>]*>[\s\S]*?<\/header>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&#\d+;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Extract href links from HTML matching a base pattern.
 */
export function extractLinks(
  html: string,
  basePattern: RegExp
): string[] {
  const matches = html.matchAll(/href="([^"]+)"/g);
  const links = new Set<string>();
  for (const m of matches) {
    if (basePattern.test(m[1])) {
      links.add(m[1]);
    }
  }
  return [...links].sort();
}
