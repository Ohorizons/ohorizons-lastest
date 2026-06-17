"""
Shared Context Store (SCS) for Context-Aware MCP (CA-MCP).

Implements cross-agent shared state so agents avoid redundant work,
detect failures from other agents, and coordinate multi-step workflows.

Ref: Jayanti et al. (2026) "Context-Aware MCP" arXiv:2601.11595.
"""

from __future__ import annotations

import time
import logging
from dataclasses import dataclass, field
from threading import Lock

logger = logging.getLogger("context_store")


@dataclass
class ContextEntry:
    """A single entry in the shared context store."""

    key: str
    value: str
    agent: str
    timestamp: float = field(default_factory=time.time)
    ttl_seconds: float = 3600.0
    tags: list[str] = field(default_factory=list)

    @property
    def is_expired(self) -> bool:
        return (time.time() - self.timestamp) > self.ttl_seconds


class SharedContextStore:
    """Thread-safe shared context store for multi-agent coordination.

    When Agent A discovers that a database connection failed, it writes
    that fact to SCS. Agent B reads SCS before attempting its own query,
    avoids the failed path, and proceeds to a fallback.
    """

    def __init__(self, max_entries: int = 1000) -> None:
        self._store: dict[str, ContextEntry] = {}
        self._lock = Lock()
        self._max_entries = max_entries

    def write(
        self,
        key: str,
        value: str,
        agent: str,
        ttl_seconds: float = 3600.0,
        tags: list[str] | None = None,
    ) -> None:
        """Write a context entry. Overwrites if key exists."""
        with self._lock:
            self._evict_expired()
            if len(self._store) >= self._max_entries:
                self._evict_oldest()
            self._store[key] = ContextEntry(
                key=key,
                value=value,
                agent=agent,
                ttl_seconds=ttl_seconds,
                tags=tags or [],
            )
            logger.debug("SCS write: %s by %s (ttl=%ss)", key, agent, ttl_seconds)

    def read(self, key: str) -> str | None:
        """Read a context entry. Returns None if missing or expired."""
        with self._lock:
            entry = self._store.get(key)
            if entry is None:
                return None
            if entry.is_expired:
                del self._store[key]
                return None
            return entry.value

    def read_by_tag(self, tag: str) -> list[ContextEntry]:
        """Read all non-expired entries matching a tag."""
        with self._lock:
            self._evict_expired()
            return [e for e in self._store.values() if tag in e.tags]

    def read_by_agent(self, agent: str) -> list[ContextEntry]:
        """Read all non-expired entries written by a specific agent."""
        with self._lock:
            self._evict_expired()
            return [e for e in self._store.values() if e.agent == agent]

    def delete(self, key: str) -> bool:
        """Delete a context entry. Returns True if it existed."""
        with self._lock:
            return self._store.pop(key, None) is not None

    def snapshot(self) -> dict[str, str]:
        """Return a snapshot of all non-expired key-value pairs."""
        with self._lock:
            self._evict_expired()
            return {k: v.value for k, v in self._store.items()}

    def summary(self) -> dict:
        """Return store statistics for observability."""
        with self._lock:
            total = len(self._store)
            expired = sum(1 for e in self._store.values() if e.is_expired)
            by_agent = {}
            for e in self._store.values():
                by_agent[e.agent] = by_agent.get(e.agent, 0) + 1
            return {
                "total_entries": total,
                "expired_entries": expired,
                "live_entries": total - expired,
                "by_agent": by_agent,
            }

    def _evict_expired(self) -> None:
        expired_keys = [k for k, v in self._store.items() if v.is_expired]
        for k in expired_keys:
            del self._store[k]

    def _evict_oldest(self) -> None:
        if not self._store:
            return
        oldest_key = min(self._store, key=lambda k: self._store[k].timestamp)
        del self._store[oldest_key]


# Global singleton
shared_context = SharedContextStore()
