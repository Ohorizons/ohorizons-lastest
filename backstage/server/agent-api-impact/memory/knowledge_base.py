"""
Knowledge Base — ChromaDB-based RAG for historical insights and patterns.

The agent stores insights it generates and retrieves relevant ones
when analyzing new data, enabling learning over time.
"""

import logging
from pathlib import Path
from datetime import datetime

import chromadb
from chromadb.config import Settings

logger = logging.getLogger("memory.knowledge_base")

CHROMA_PATH = Path(__file__).parent.parent / "data" / "chroma"


def _get_client() -> chromadb.ClientAPI:
    CHROMA_PATH.mkdir(parents=True, exist_ok=True)
    return chromadb.PersistentClient(
        path=str(CHROMA_PATH),
        settings=Settings(anonymized_telemetry=False),
    )


def _get_collection(name: str = "ai_impact_insights"):
    client = _get_client()
    return client.get_or_create_collection(
        name=name,
        metadata={"description": "AI Impact insights and learned patterns"},
    )


def store_insight(insight: str, category: str, metadata: dict | None = None):
    """Store a new insight for future retrieval via RAG."""
    collection = _get_collection()
    doc_id = f"{category}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
    meta = {
        "category": category,
        "created_at": datetime.utcnow().isoformat(),
        **(metadata or {}),
    }
    collection.add(
        documents=[insight],
        metadatas=[meta],
        ids=[doc_id],
    )
    logger.info("Stored insight: %s [%s]", doc_id, category)


def search_insights(query: str, n_results: int = 5, category: str | None = None) -> list[dict]:
    """Search for relevant historical insights using semantic similarity."""
    collection = _get_collection()
    where = {"category": category} if category else None
    try:
        results = collection.query(
            query_texts=[query],
            n_results=n_results,
            where=where,
        )
        insights = []
        for i, doc in enumerate(results["documents"][0]):
            insights.append({
                "insight": doc,
                "metadata": results["metadatas"][0][i] if results["metadatas"] else {},
                "distance": results["distances"][0][i] if results["distances"] else 0,
            })
        return insights
    except Exception as e:
        logger.warning("RAG search failed: %s", e)
        return []


def get_all_insights(category: str | None = None, limit: int = 50) -> list[dict]:
    """Get all stored insights, optionally filtered by category."""
    collection = _get_collection()
    where = {"category": category} if category else None
    try:
        results = collection.get(where=where, limit=limit)
        return [
            {"id": results["ids"][i], "insight": results["documents"][i], "metadata": results["metadatas"][i]}
            for i in range(len(results["ids"]))
        ]
    except Exception as e:
        logger.warning("Failed to get insights: %s", e)
        return []


def count_insights() -> int:
    """Count total stored insights."""
    collection = _get_collection()
    return collection.count()
