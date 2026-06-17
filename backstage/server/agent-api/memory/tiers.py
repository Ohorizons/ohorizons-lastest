"""
Three-Tier Memory Architecture for agent context management.

Tier 1 (Hot Memory / Constitution): Always loaded. ~660 tokens.
  Core conventions, safety guidelines, orchestration protocols.

Tier 2 (Warm Memory / Domain Specialists): Loaded per-agent. ~2000 tokens.
  Agent-specific domain knowledge, tool descriptions, behavioral rules.

Tier 3 (Cold Memory / Knowledge Base): Loaded on-demand. ~1500 tokens.
  Edge cases, policy details, historical context, reference material.
  Retrieved only when semantically relevant (70% of tasks skip this tier).

Ref: Vasilopoulos (2026) "Production Context Architectures" arXiv:2602.20478
"""

from __future__ import annotations

import logging
from pathlib import Path

logger = logging.getLogger("memory.tiers")

CONSTITUTION_PATH = Path(__file__).parent.parent / "CONSTITUTION.md"


class MemoryManager:
    """Manages the three-tier context architecture."""

    def __init__(self) -> None:
        self._tier1_cache: str | None = None
        self._tier3_docs: dict[str, str] = {}

    def get_tier1(self) -> str:
        """Load Tier 1 (Hot Memory): constitution + core conventions.

        Always included in every agent invocation. Cached after first load.
        Cost: ~660 tokens per invocation (fixed).
        """
        if self._tier1_cache is not None:
            return self._tier1_cache

        if CONSTITUTION_PATH.exists():
            self._tier1_cache = CONSTITUTION_PATH.read_text(encoding="utf-8")
            logger.info(
                "Tier 1 loaded: %d chars from CONSTITUTION.md",
                len(self._tier1_cache),
            )
        else:
            self._tier1_cache = (
                "You are an Open Horizons platform agent. "
                "Prioritize: Security > Accuracy > Speed. "
                "Never fabricate data. Respond in the user's language."
            )
            logger.warning("CONSTITUTION.md not found, using fallback Tier 1")

        return self._tier1_cache

    def get_tier2(self, agent_name: str) -> str:
        """Load Tier 2 (Warm Memory): agent-specific domain context.

        Loaded only for the active agent. Each agent's system prompt
        serves as its Tier 2 context. This method provides supplementary
        domain knowledge beyond the system prompt.
        Cost: ~2000 tokens per invocation (varies by agent).
        """
        tier2_dir = Path(__file__).parent.parent / "agents"
        tier2_file = tier2_dir / f"{agent_name}.py"

        if not tier2_file.exists():
            return ""

        # Extract the AGENT_CONFIG docstring or description
        # In practice, Tier 2 is the agent's system prompt itself,
        # loaded by BaseAgent from AgentConfig.system_prompt
        return ""

    def get_tier3(self, query: str, top_k: int = 3) -> list[dict[str, str]]:
        """Load Tier 3 (Cold Memory): on-demand knowledge retrieval.

        Only loaded when the query requires reference material.
        In 70% of tasks, this tier is never accessed.
        Cost: ~1500 tokens per retrieval (when accessed).

        Returns list of {"title": ..., "content": ...} dicts.
        """
        if not self._tier3_docs:
            self._load_knowledge_base()

        if not self._tier3_docs:
            return []

        # Simple keyword matching for cold memory retrieval.
        # In production, replace with semantic search (pgvector, Azure AI Search).
        query_lower = query.lower()
        results = []
        for title, content in self._tier3_docs.items():
            score = sum(1 for word in query_lower.split() if word in title.lower())
            if score > 0:
                results.append({"title": title, "content": content, "score": score})

        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:top_k]

    def get_context_budget(self, agent_name: str) -> dict:
        """Return token budget allocation for the three tiers."""
        return {
            "tier1_hot": 660,
            "tier2_warm": 2000,
            "tier3_cold_max": 1500,
            "total_budget": 4160,
            "agent": agent_name,
        }

    def _load_knowledge_base(self) -> None:
        """Load Tier 3 knowledge base from docs/."""
        docs_dir = Path(__file__).parent.parent.parent.parent.parent / "docs"
        if not docs_dir.exists():
            return

        for md_file in docs_dir.rglob("*.md"):
            try:
                content = md_file.read_text(encoding="utf-8")
                # Limit each doc to 2000 chars for cold memory
                self._tier3_docs[md_file.stem] = content[:2000]
            except (OSError, UnicodeDecodeError):
                continue

        logger.info("Tier 3 loaded: %d documents", len(self._tier3_docs))


# Global singleton
memory_manager = MemoryManager()
