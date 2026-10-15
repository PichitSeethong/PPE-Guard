from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, HTTPException, Query, status

from ..database import get_db
from ..security import require_supervisor, require_user
from ..services.serializers import event_to_dict
from ..services.audit import write_audit
from ..services.time_utils import period_start, to_iso

router = APIRouter(prefix='/api/v1/events', tags=['events'])


def _status_filter(value: str | None) -> str | None:
    if value is None:
        return None
    normalized = value.strip().upper().replace('-', '_').replace(' ', '_')
    if normalized not in {'SAFE', 'NOT_SAFE'}:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail='status ต้องเป็น SAFE หรือ NOT_SAFE')
    return normalized


def _event_or_404(db: sqlite3.Connection, event_id: str) -> sqlite3.Row:
    row = db.execute('SELECT * FROM ppe_events WHERE id = ?', (event_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='ไม่พบเหตุการณ์')
    return row


@router.get('')
def list_events(
    status_filter: str | None = Query(default=None, alias='status'),
    period: str = Query(default='all'),
    limit: int = Query(default=100, ge=1, le=250),
    _: dict = Depends(require_user),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    try:
        start = period_start(period)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    event_status = _status_filter(status_filter)
    clauses: list[str] = []
    values: list[object] = []
    if event_status:
        clauses.append('status = ?')
        values.append(event_status)
    if start:
        clauses.append('captured_at >= ?')
        values.append(to_iso(start))
    where = f'WHERE {" AND ".join(clauses)}' if clauses else ''
    total = db.execute(f'SELECT COUNT(*) AS count FROM ppe_events {where}', values).fetchone()['count']
    rows = db.execute(f'SELECT * FROM ppe_events {where} ORDER BY captured_at DESC LIMIT ?', [*values, limit]).fetchall()
    return {'items': [event_to_dict(row) for row in rows], 'total': total}


@router.get('/{event_id}')
def get_event(event_id: str, _: dict = Depends(require_user), db: sqlite3.Connection = Depends(get_db)) -> dict:
    return event_to_dict(_event_or_404(db, event_id))


@router.post('/{event_id}/acknowledge')
def acknowledge_event(event_id: str, user: dict = Depends(require_supervisor), db: sqlite3.Connection = Depends(get_db)) -> dict:
    row = _event_or_404(db, event_id)
    if row['status'] != 'NOT_SAFE':
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='รับทราบได้เฉพาะเหตุการณ์ NOT_SAFE')
    if not row['acknowledged']:
        from ..services.time_utils import to_iso, utc_now
        db.execute(
            'UPDATE ppe_events SET acknowledged = 1, acknowledged_by = ?, acknowledged_at = ? WHERE id = ?',
            (user['display_name'], to_iso(utc_now()), event_id),
        )
        updated_row = _event_or_404(db, event_id)
        write_audit(
            db, actor=user, action='acknowledge_event', target_type='ppe_event', target_id=event_id,
            detail={'camera_id': updated_row['camera_id'], 'status': updated_row['status']},
        )
        db.commit()
    return event_to_dict(_event_or_404(db, event_id))
