"""
Metrics Store — SQLite-based time-series storage for KPI snapshots.

Stores periodic snapshots of all collected metrics so the agent can:
- Compare current vs historical performance
- Calculate trends and deltas
- Identify patterns over time
"""

import json
import sqlite3
import logging
from datetime import datetime
from pathlib import Path

logger = logging.getLogger("memory.metrics_store")

DB_PATH = Path(__file__).parent.parent / "data" / "metrics.db"


def _get_conn() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Create tables if they don't exist."""
    conn = _get_conn()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            collected_at TEXT NOT NULL,
            data JSON NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE INDEX IF NOT EXISTS idx_snapshots_category ON snapshots(category);
        CREATE INDEX IF NOT EXISTS idx_snapshots_collected ON snapshots(collected_at);

        CREATE TABLE IF NOT EXISTS kpi_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kpi_name TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT,
            period TEXT,
            recorded_at TEXT DEFAULT (datetime('now'))
        );
        CREATE INDEX IF NOT EXISTS idx_kpi_name ON kpi_history(kpi_name);
    """)
    conn.close()
    logger.info("Metrics store initialized at %s", DB_PATH)


def save_snapshot(category: str, data: dict):
    """Save a metric snapshot."""
    conn = _get_conn()
    conn.execute(
        "INSERT INTO snapshots (category, collected_at, data) VALUES (?, ?, ?)",
        (category, data.get("collected_at", datetime.utcnow().isoformat()), json.dumps(data)),
    )
    conn.commit()
    conn.close()
    logger.debug("Saved snapshot: %s", category)


def save_kpi(name: str, value: float, unit: str = "", period: str = ""):
    """Save a KPI data point."""
    conn = _get_conn()
    conn.execute(
        "INSERT INTO kpi_history (kpi_name, value, unit, period) VALUES (?, ?, ?, ?)",
        (name, value, unit, period),
    )
    conn.commit()
    conn.close()


def get_latest_snapshot(category: str) -> dict | None:
    """Get the most recent snapshot for a category."""
    conn = _get_conn()
    row = conn.execute(
        "SELECT data FROM snapshots WHERE category = ? ORDER BY collected_at DESC LIMIT 1",
        (category,),
    ).fetchone()
    conn.close()
    return json.loads(row["data"]) if row else None


def get_snapshots(category: str, limit: int = 10) -> list[dict]:
    """Get recent snapshots for a category."""
    conn = _get_conn()
    rows = conn.execute(
        "SELECT data, collected_at FROM snapshots WHERE category = ? ORDER BY collected_at DESC LIMIT ?",
        (category, limit),
    ).fetchall()
    conn.close()
    return [json.loads(r["data"]) for r in rows]


def get_kpi_trend(name: str, limit: int = 30) -> list[dict]:
    """Get KPI history for trend analysis."""
    conn = _get_conn()
    rows = conn.execute(
        "SELECT value, unit, period, recorded_at FROM kpi_history WHERE kpi_name = ? ORDER BY recorded_at DESC LIMIT ?",
        (name, limit),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def compare_snapshots(category: str) -> dict | None:
    """Compare latest vs previous snapshot for a category."""
    snapshots = get_snapshots(category, limit=2)
    if len(snapshots) < 2:
        return None
    return {"current": snapshots[0], "previous": snapshots[1]}
