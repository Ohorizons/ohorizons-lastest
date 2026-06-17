import type { CacheEntry } from "./types.js";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";

const TTL = parseInt(process.env.CACHE_TTL_MS ?? "3600000", 10);
const CACHE_DIR = process.env.CACHE_DIR ?? join(process.cwd(), "cache");
const CACHE_FILE = join(CACHE_DIR, "cache.json");

const store = new Map<string, CacheEntry>();

function loadFromDisk(): void {
  if (!existsSync(CACHE_FILE)) return;
  try {
    const raw = readFileSync(CACHE_FILE, "utf-8");
    const entries: Record<string, CacheEntry> = JSON.parse(raw);
    const now = Date.now();
    for (const [key, entry] of Object.entries(entries)) {
      if (entry.expiresAt > now) {
        store.set(key, entry);
      }
    }
  } catch {
    // Corrupt cache file — start fresh
  }
}

function saveToDisk(): void {
  try {
    mkdirSync(CACHE_DIR, { recursive: true });
    const obj: Record<string, CacheEntry> = {};
    for (const [key, entry] of store) {
      obj[key] = entry;
    }
    writeFileSync(CACHE_FILE, JSON.stringify(obj), "utf-8");
  } catch {
    // Non-critical — cache will repopulate
  }
}

export function cacheGet(key: string): string | undefined {
  const entry = store.get(key);
  if (!entry) return undefined;
  if (Date.now() > entry.expiresAt) {
    store.delete(key);
    return undefined;
  }
  return entry.value;
}

export function cacheSet(key: string, value: string): void {
  store.set(key, { value, expiresAt: Date.now() + TTL });
  saveToDisk();
}

// Load persisted cache on startup
loadFromDisk();
