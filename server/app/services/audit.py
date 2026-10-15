from __future__ import annotations

import json
import sqlite3
from typing import Any
from uuid import uuid4

from .time_utils import to_iso, utc_now


def write_audit(
    db: sqlite3.Connection,
    *,
    action: str,
    target_type: str,
    target_id: str | None = None,
    actor: dict | None = None,
    detail: dict[str, Any] | None = None,
) -> None:
    db.execute(
        '''INSERT INTO audit_logs (
            id, actor_user_id, actor_username, action, target_type, target_id, detail_json, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        (
            str(uuid4()),
            actor.get('id') if actor else None,
            actor.get('username') if actor else None,
            action,
            target_type,
            target_id,
            json.dumps(detail or {}, ensure_ascii=False),
            to_iso(utc_now()),
        ),
    )
