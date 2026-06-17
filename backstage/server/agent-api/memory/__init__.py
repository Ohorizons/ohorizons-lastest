"""
Memory module for Open Horizons Agent API.

Implements the three-tier context architecture:
  Tier 1 (Hot)  — Constitution + core conventions, always loaded
  Tier 2 (Warm) — Domain specialist context, loaded per-agent
  Tier 3 (Cold) — Knowledge base docs, loaded on-demand via retrieval

Plus the Shared Context Store (CA-MCP) for cross-agent coordination.

Ref: Vasilopoulos (2026) arXiv:2602.20478
Ref: Jayanti et al. (2026) arXiv:2601.11595
"""

from memory.context_store import SharedContextStore, shared_context
from memory.tiers import MemoryManager, memory_manager

__all__ = [
    "SharedContextStore",
    "shared_context",
    "MemoryManager",
    "memory_manager",
]
