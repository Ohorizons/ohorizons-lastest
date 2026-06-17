import { cacheGet, cacheSet } from "./cache.js";

const GH_TOKEN = process.env.GH_TOKEN ?? "";

const headers: Record<string, string> = {
  "User-Agent": "${{ values.name }}/1.0",
  Accept: "application/vnd.github.v3+json",
};

if (GH_TOKEN) {
  headers["Authorization"] = `Bearer ${GH_TOKEN}`;
}

export async function fetchRaw(
  owner: string,
  repo: string,
  path: string,
  branch = "main"
): Promise<string> {
  const cacheKey = `raw:${owner}/${repo}/${branch}/${path}`;
  const cached = cacheGet(cacheKey);
  if (cached) return cached;

  const url = `https://raw.githubusercontent.com/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/${encodeURIComponent(branch)}/${path}`;
  const res = await fetch(url, {
    headers: { "User-Agent": "${{ values.name }}/1.0" },
  });
  if (!res.ok) {
    throw new Error(`GitHub raw fetch failed: ${res.status} ${url}`);
  }
  const text = await res.text();
  cacheSet(cacheKey, text);
  return text;
}

export async function listContents(
  owner: string,
  repo: string,
  path: string,
  branch = "main"
): Promise<Array<{ name: string; path: string; type: string; download_url: string | null }>> {
  const cacheKey = `contents:${owner}/${repo}/${branch}/${path}`;
  const cached = cacheGet(cacheKey);
  if (cached) return JSON.parse(cached);

  const url = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/contents/${path}?ref=${branch}`;
  const res = await fetch(url, { headers });
  if (!res.ok) {
    throw new Error(`GitHub contents fetch failed: ${res.status} ${url}`);
  }
  const data = await res.json();
  const items = Array.isArray(data) ? data : [data];
  const result = items.map((item: Record<string, unknown>) => ({
    name: item.name as string,
    path: item.path as string,
    type: item.type as string,
    download_url: (item.download_url as string) ?? null,
  }));
  cacheSet(cacheKey, JSON.stringify(result));
  return result;
}

export async function listTree(
  owner: string,
  repo: string,
  branch = "main",
  pathPrefix = ""
): Promise<Array<{ path: string; type: string }>> {
  const cacheKey = `tree:${owner}/${repo}/${branch}:${pathPrefix}`;
  const cached = cacheGet(cacheKey);
  if (cached) return JSON.parse(cached);

  const url = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/git/trees/${encodeURIComponent(branch)}?recursive=1`;
  const res = await fetch(url, { headers });
  if (!res.ok) {
    throw new Error(`GitHub tree fetch failed: ${res.status} ${url}`);
  }
  const data = (await res.json()) as { tree: Array<{ path: string; type: string }> };
  const items = data.tree
    .filter(
      (item) =>
        item.type === "blob" &&
        (pathPrefix === "" || item.path.startsWith(pathPrefix))
    )
    .map((item) => ({ path: item.path, type: item.type }));
  cacheSet(cacheKey, JSON.stringify(items));
  return items;
}

export async function fetchUrl(url: string): Promise<string> {
  const cacheKey = `url:${url}`;
  const cached = cacheGet(cacheKey);
  if (cached) return cached;

  const res = await fetch(url, {
    headers: { "User-Agent": "${{ values.name }}/1.0" },
  });
  if (!res.ok) {
    throw new Error(`Fetch failed: ${res.status} ${url}`);
  }
  const text = await res.text();
  cacheSet(cacheKey, text);
  return text;
}
