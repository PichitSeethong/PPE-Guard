from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends

from ..database import get_db
from ..security import require_user
from ..services.serializers import camera_to_dict, event_to_dict
from ..services.statistics import statistics_for_period

router = APIRouter(prefix='/api/v1/dashboard', tags=['dashboard'])


@router.get('')
def get_dashboard(_: dict = Depends(require_user), db: sqlite3.Connection = Depends(get_db)) -> dict:
    cameras = db.execute('SELECT * FROM cameras ORDER BY id').fetchall()
    recent = db.execute('SELECT * FROM ppe_events ORDER BY captured_at DESC LIMIT 5').fetchall()
    latest = recent[0] if recent else None
    return {
        'cameras': [camera_to_dict(row) for row in cameras],
        'latest_event': event_to_dict(latest) if latest else None,
        'recent_events': [event_to_dict(row) for row in recent],
        'today_statistics': statistics_for_period(db, 'today'),
    }
