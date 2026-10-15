from __future__ import annotations

import json
import sqlite3
from collections import Counter

from .time_utils import period_start, to_iso


def statistics_for_period(db: sqlite3.Connection, period: str) -> dict:
    """Return checkpoint-session statistics for the selected period.

    One row in ``ppe_events`` represents one completed checkpoint session.
    Compliance is therefore calculated from event counts, not from how long a
    camera's latest SAFE/NOT_SAFE state remained active.
    """

    start = period_start(period)
    start_iso = to_iso(start) if start else None

    clauses: list[str] = []
    values: list[object] = []
    if start_iso:
        clauses.append("captured_at >= ?")
        values.append(start_iso)

    where_sql = f"WHERE {' AND '.join(clauses)}" if clauses else ""
    rows = db.execute(
        f"SELECT status, missing_ppe FROM ppe_events {where_sql}",
        values,
    ).fetchall()

    safe_events = sum(1 for row in rows if row["status"] == "SAFE")
    not_safe_events = sum(1 for row in rows if row["status"] == "NOT_SAFE")
    event_count = safe_events + not_safe_events

    missing_counts: Counter[str] = Counter()
    for row in rows:
        if row["status"] != "NOT_SAFE":
            continue
        try:
            items = json.loads(row["missing_ppe"] or "[]")
        except (json.JSONDecodeError, TypeError):
            continue
        if isinstance(items, list):
            missing_counts.update(str(item) for item in items if str(item).strip())

    compliance = round((safe_events / event_count * 100), 2) if event_count else 0.0

    return {
        "period": period,
        "event_count": event_count,
        "inspection_count": event_count,
        "safe_event_count": safe_events,
        "not_safe_event_count": not_safe_events,
        "compliance_rate": compliance,
        "missing_ppe_counts": dict(missing_counts),
    }
