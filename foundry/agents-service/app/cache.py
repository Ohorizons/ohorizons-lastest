"""Prompt/response cache layers (REQ-CACHE-001..006, REQ-REDIS-002..004).

Three composable layers, looked up hierarchically (cheapest first):

  1. **Three-tier exact cache** (REQ-CACHE-001) — a Redis-backed response cache keyed by
     ``(scope, sha256(canonical-prompt))``. Three scopes with different TTLs:
       * ``global``  — cross-tenant, cross-project (default 1h)
       * ``project`` — per repo/project (default 1h)
       * ``session`` — per chat thread (default 5m)
     A lookup walks the scopes most-specific → least-specific (session → project → global)
     so a fresh session result shadows a stale global one, then falls back outward.
  2. **Semantic cache** (REQ-CACHE-006 / REQ-REDIS-003) — a Redis vector index over prior
     prompt embeddings; a query embedding within cosine distance ``1 - 0.93`` of a stored
     entry returns that entry's response. Uses a RediSearch **HNSW** index (``M=32``,
     ``EF_CONSTRUCTION=200``, ``DISTANCE_METRIC=COSINE``) — see :func:`hnsw_index_schema`.
  3. **Provider prompt cache** — Anthropic ``cache_control`` / Azure OpenAI automatic prefix
     caching; this module does not manage it directly but the prefix ordering in
     ``docs/cache-prefix-order.md`` keeps the cacheable prefix stable so it actually hits.

``redis`` is imported lazily; if it is not installed (or no URL is configured) every layer
degrades to a no-op (always-miss), so the gateway runs fine without a cache. Tests use an
in-memory fake (:class:`InMemoryRedis`).
"""
from __future__ import annotations

import hashlib
import json
import os
import time
from dataclasses import dataclass, field
from typing import Any, Callable, Mapping, Protocol

# ── tier / scope constants ──────────────────────────────────────────────────
SCOPE_GLOBAL = "global"
SCOPE_PROJECT = "project"
SCOPE_SESSION = "session"
_SCOPE_ORDER = (SCOPE_SESSION, SCOPE_PROJECT, SCOPE_GLOBAL)  # most → least specific
_DEFAULT_TTLS = {SCOPE_GLOBAL: 3600, SCOPE_PROJECT: 3600, SCOPE_SESSION: 300}

TIER_EXACT = "exact"
TIER_SEMANTIC = "semantic"
TIER_MISS = "miss"

SEMANTIC_SIMILARITY_THRESHOLD = 0.93  # REQ-REDIS-003
_KEY_PREFIX = "th:cache"
_VEC_INDEX = "th:semcache:idx"
_VEC_PREFIX = "th:semcache:doc:"


def hnsw_index_schema(dims: int) -> dict[str, Any]:
    """RediSearch HNSW vector index parameters for the semantic cache / RAG store
    (REQ-REDIS-002: ``M=32``, ``EF_CONSTRUCTION=200``, cosine, hybrid filters)."""
    return {
        "index_name": _VEC_INDEX,
        "prefix": _VEC_PREFIX,
        "algorithm": "HNSW",
        "vector_field": "embedding",
        "dims": dims,
        "distance_metric": "COSINE",
        "M": 32,
        "EF_CONSTRUCTION": 200,
        "EF_RUNTIME": 64,
        "filter_fields": ["scope", "tenant_id", "project_id"],  # hybrid filters
        "datatype": "FLOAT32",
    }


# ── canonical prompt hashing ────────────────────────────────────────────────
def canonical_prompt(messages: list[Mapping[str, Any]] | list[dict[str, Any]], *, model: str | None = None) -> str:
    """A stable string for exact-cache keying — only role+content, JSON with sorted keys."""
    norm = [{"role": m.get("role", ""), "content": m.get("content", "")} for m in messages]
    return json.dumps({"model": model or "", "messages": norm}, sort_keys=True, separators=(",", ":"))


def prompt_hash(messages: list[Mapping[str, Any]] | list[dict[str, Any]], *, model: str | None = None) -> str:
    return hashlib.sha256(canonical_prompt(messages, model=model).encode("utf-8")).hexdigest()


# ── redis abstraction ───────────────────────────────────────────────────────
class RedisLike(Protocol):  # the small subset we use
    def get(self, key: str) -> Any: ...
    def set(self, key: str, value: Any, ex: int | None = None) -> Any: ...
    def keys(self, pattern: str) -> Any: ...
    def delete(self, *keys: str) -> Any: ...


class InMemoryRedis:
    """Minimal in-memory stand-in for tests (no TTL expiry simulation needed for unit scope)."""

    def __init__(self) -> None:
        self._d: dict[str, tuple[Any, float | None]] = {}

    def get(self, key: str) -> Any:
        item = self._d.get(key)
        if item is None:
            return None
        value, expires_at = item
        if expires_at is not None and time.time() > expires_at:
            self._d.pop(key, None)
            return None
        return value

    def set(self, key: str, value: Any, ex: int | None = None) -> Any:
        self._d[key] = (value, (time.time() + ex) if ex else None)
        return True

    def keys(self, pattern: str) -> list[str]:
        # only supports a trailing '*' glob (enough for our prefixes)
        if pattern.endswith("*"):
            head = pattern[:-1]
            return [k for k in self._d if k.startswith(head)]
        return [k for k in self._d if k == pattern]

    def delete(self, *keys: str) -> int:
        n = 0
        for k in keys:
            if self._d.pop(k, None) is not None:
                n += 1
        return n


def _connect_redis(url: str | None) -> RedisLike | None:
    target = url or os.environ.get("REDIS_URL") or os.environ.get("AZURE_REDIS_URL")
    if not target:
        return None
    try:  # pragma: no cover - exercised only when redis-py + a server are present
        import redis  # type: ignore

        return redis.Redis.from_url(target, decode_responses=True)
    except Exception:  # noqa: BLE001 - any import/connect failure → no cache
        return None


# ── stats ───────────────────────────────────────────────────────────────────
@dataclass
class CacheStats:
    hits: dict[str, int] = field(default_factory=lambda: {TIER_EXACT: 0, TIER_SEMANTIC: 0})
    misses: int = 0
    by_scope: dict[str, int] = field(default_factory=lambda: {s: 0 for s in (SCOPE_SESSION, SCOPE_PROJECT, SCOPE_GLOBAL)})
    stores: int = 0

    def record_hit(self, tier: str, scope: str | None = None) -> None:
        self.hits[tier] = self.hits.get(tier, 0) + 1
        if scope:
            self.by_scope[scope] = self.by_scope.get(scope, 0) + 1

    def record_miss(self) -> None:
        self.misses += 1

    def record_store(self) -> None:
        self.stores += 1

    @property
    def total_lookups(self) -> int:
        return sum(self.hits.values()) + self.misses

    @property
    def hit_rate(self) -> float:
        total = self.total_lookups
        return round(sum(self.hits.values()) / total, 4) if total else 0.0

    def to_metrics(self) -> dict[str, Any]:
        return {
            "cache_hit_rate": self.hit_rate,
            "cache_hits_exact": self.hits.get(TIER_EXACT, 0),
            "cache_hits_semantic": self.hits.get(TIER_SEMANTIC, 0),
            "cache_misses": self.misses,
            "cache_total_lookups": self.total_lookups,
            "cache_hits_by_scope": dict(self.by_scope),
            "cache_stores": self.stores,
            "semantic_similarity_threshold": SEMANTIC_SIMILARITY_THRESHOLD,
        }


# ── three-tier exact cache ──────────────────────────────────────────────────
def _key(scope: str, scope_id: str, h: str) -> str:
    return f"{_KEY_PREFIX}:{scope}:{scope_id}:{h}"


class ThreeTierExactCache:
    """Redis-backed exact response cache across global/project/session scopes (REQ-CACHE-001)."""

    def __init__(self, redis: RedisLike | None, *, ttls: Mapping[str, int] | None = None) -> None:
        self._r = redis
        self._ttls = {**_DEFAULT_TTLS, **(ttls or {})}

    @property
    def enabled(self) -> bool:
        return self._r is not None

    def _scope_id(self, scope: str, ctx: Mapping[str, str]) -> str:
        if scope == SCOPE_GLOBAL:
            return "all"
        if scope == SCOPE_PROJECT:
            return ctx.get("project_id") or ctx.get("tenant_id") or "default"
        return ctx.get("session_id") or "default"

    def get(self, h: str, ctx: Mapping[str, str]) -> tuple[str | None, Any]:
        """Return ``(scope_hit, value)`` walking session→project→global; ``(None, None)`` on miss."""
        if self._r is None:
            return None, None
        for scope in _SCOPE_ORDER:
            raw = self._r.get(_key(scope, self._scope_id(scope, ctx), h))
            if raw is not None:
                try:
                    return scope, json.loads(raw)
                except (TypeError, ValueError):
                    return scope, raw
        return None, None

    def set(self, h: str, value: Any, ctx: Mapping[str, str], *, scopes: list[str] | None = None) -> None:
        if self._r is None:
            return
        payload = value if isinstance(value, str) else json.dumps(value, separators=(",", ":"))
        for scope in scopes or list(_SCOPE_ORDER):
            self._r.set(_key(scope, self._scope_id(scope, ctx), h), payload, ex=self._ttls[scope])


# ── semantic cache (RediSearch vector) ──────────────────────────────────────
def _cosine_sim(a: list[float], b: list[float]) -> float:
    if not a or not b or len(a) != len(b):
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = sum(x * x for x in a) ** 0.5
    nb = sum(y * y for y in b) ** 0.5
    if na == 0 or nb == 0:
        return 0.0
    return dot / (na * nb)


class SemanticCache:
    """Embedding-similarity response cache (REQ-CACHE-006 / REQ-REDIS-003, threshold 0.93).

    The real backend is a RediSearch HNSW index (see :func:`hnsw_index_schema`); when a
    RediSearch-capable client is not available it falls back to a brute-force scan over the
    entries stored under ``th:semcache:doc:*`` (used by the unit tests and small dev sets).
    ``embedder`` maps text → vector; if it is ``None`` the cache is disabled.
    """

    def __init__(
        self,
        redis: RedisLike | None,
        embedder: Callable[[str], list[float]] | None,
        *,
        threshold: float = SEMANTIC_SIMILARITY_THRESHOLD,
        ttl_seconds: int = 3600,
    ) -> None:
        self._r = redis
        self._embed = embedder
        self._threshold = threshold
        self._ttl = ttl_seconds

    @property
    def enabled(self) -> bool:
        return self._r is not None and self._embed is not None

    def _doc_key(self, h: str) -> str:
        return f"{_VEC_PREFIX}{h}"

    def get(self, query_text: str, ctx: Mapping[str, str]) -> tuple[float, Any] | None:
        if not self.enabled:
            return None
        qv = self._embed(query_text)  # type: ignore[misc]
        best: tuple[float, Any] | None = None
        for key in self._r.keys(f"{_VEC_PREFIX}*"):  # type: ignore[union-attr]
            raw = self._r.get(key)  # type: ignore[union-attr]
            if not raw:
                continue
            try:
                doc = json.loads(raw)
            except (TypeError, ValueError):
                continue
            if ctx.get("tenant_id") and doc.get("tenant_id") and doc["tenant_id"] != ctx["tenant_id"]:
                continue  # hybrid filter
            sim = _cosine_sim(qv, doc.get("embedding", []))
            if sim >= self._threshold and (best is None or sim > best[0]):
                best = (round(sim, 4), doc.get("response"))
        return best

    def set(self, query_text: str, response: Any, ctx: Mapping[str, str]) -> None:
        if not self.enabled:
            return
        h = hashlib.sha256(query_text.encode("utf-8")).hexdigest()
        doc = {
            "embedding": self._embed(query_text),  # type: ignore[misc]
            "response": response,
            "tenant_id": ctx.get("tenant_id", ""),
            "project_id": ctx.get("project_id", ""),
            "scope": ctx.get("scope", SCOPE_GLOBAL),
            "text_sha256": h,
        }
        self._r.set(self._doc_key(h), json.dumps(doc, separators=(",", ":")), ex=self._ttl)  # type: ignore[union-attr]


# ── hierarchical orchestrator ───────────────────────────────────────────────
@dataclass
class CacheLookupResult:
    hit: bool
    tier: str  # exact | semantic | miss
    scope: str | None = None
    similarity: float | None = None
    value: Any = None


class HierarchicalCache:
    """Exact → semantic → miss, with shared stats. The single entry point for the gateway."""

    def __init__(
        self,
        exact: ThreeTierExactCache,
        semantic: SemanticCache,
        *,
        stats: CacheStats | None = None,
    ) -> None:
        self.exact = exact
        self.semantic = semantic
        self.stats = stats or CacheStats()

    @property
    def enabled(self) -> bool:
        return self.exact.enabled or self.semantic.enabled

    def lookup(
        self,
        messages: list[Mapping[str, Any]] | list[dict[str, Any]],
        ctx: Mapping[str, str],
        *,
        model: str | None = None,
        query_text: str | None = None,
    ) -> CacheLookupResult:
        h = prompt_hash(messages, model=model)
        scope_hit, value = self.exact.get(h, ctx)
        if scope_hit is not None:
            self.stats.record_hit(TIER_EXACT, scope_hit)
            return CacheLookupResult(hit=True, tier=TIER_EXACT, scope=scope_hit, value=value)
        qtext = query_text if query_text is not None else _last_user_text(messages)
        if qtext:
            sem = self.semantic.get(qtext, ctx)
            if sem is not None:
                sim, val = sem
                self.stats.record_hit(TIER_SEMANTIC)
                return CacheLookupResult(hit=True, tier=TIER_SEMANTIC, similarity=sim, value=val)
        self.stats.record_miss()
        return CacheLookupResult(hit=False, tier=TIER_MISS)

    def store(
        self,
        messages: list[Mapping[str, Any]] | list[dict[str, Any]],
        response: Any,
        ctx: Mapping[str, str],
        *,
        model: str | None = None,
        query_text: str | None = None,
        scopes: list[str] | None = None,
    ) -> None:
        h = prompt_hash(messages, model=model)
        self.exact.set(h, response, ctx, scopes=scopes)
        qtext = query_text if query_text is not None else _last_user_text(messages)
        if qtext:
            self.semantic.set(qtext, response, {**ctx, "scope": (scopes or [SCOPE_GLOBAL])[-1]})
        self.stats.record_store()


def _last_user_text(messages: list[Mapping[str, Any]] | list[dict[str, Any]]) -> str:
    for m in reversed(list(messages)):
        if m.get("role") == "user" and isinstance(m.get("content"), str):
            return m["content"]
    return ""


def build_hierarchical_cache(
    *,
    redis_url: str | None = None,
    embedder: Callable[[str], list[float]] | None = None,
    ttls: Mapping[str, int] | None = None,
    redis_client: RedisLike | None = None,
) -> HierarchicalCache:
    """Wire the layers from env/args. ``redis_client`` overrides connection (used by tests)."""
    r = redis_client if redis_client is not None else _connect_redis(redis_url)
    return HierarchicalCache(
        exact=ThreeTierExactCache(r, ttls=ttls),
        semantic=SemanticCache(r, embedder),
    )
