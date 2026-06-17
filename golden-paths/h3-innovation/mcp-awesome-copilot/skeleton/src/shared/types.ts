export interface ToolResult {
  content: Array<{ type: "text"; text: string }>;
  structuredContent?: Record<string, unknown>;
}

export interface CacheEntry<T = string> {
  value: T;
  expiresAt: number;
}

export interface GitHubTreeItem {
  name: string;
  path: string;
  type: "blob" | "tree";
  url: string;
}

export interface GitHubContent {
  name: string;
  path: string;
  type: "file" | "dir";
  download_url: string | null;
}

export function textResult(text: string) {
  return { content: [{ type: "text" as const, text }] };
}
