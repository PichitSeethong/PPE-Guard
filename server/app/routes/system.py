from __future__ import annotations

import csv
import io
import json
import sqlite3

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse

from ..database import get_db
from ..security import require_admin, require_user, require_user_or_query_token
from ..services.audit import write_audit
from ..services.system_ops import create_backup, system_health
from ..services.time_utils import period_start, to_iso

router = APIRouter(prefix='/api/v1/system', tags=['system'])
export_router = APIRouter(prefix='/api/v1/export', tags=['export'])


def require_supervisor_or_query_token(
    user: dict = Depends(require_user_or_query_token),
) -> dict:
    """Allow CSV downloads opened by the browser with ?token=... as well as API Bearer auth."""
    if user['role'] not in {'admin', 'supervisor'}:
        raise HTTPException(status_code=403, detail='บัญชีนี้ไม่มีสิทธิ์ดำเนินการนี้')
    return user


@router.get('/health')
def get_system_health(_: dict = Depends(require_user), db: sqlite3.Connection = Depends(get_db)) -> dict:
    return system_health(db)


@router.post('/backup')
def backup_now(actor: dict = Depends(require_admin), db: sqlite3.Connection = Depends(get_db)) -> dict:
    result = create_backup()
    write_audit(db, actor=actor, action='create_backup', target_type='backup', target_id=result['filename'], detail={'size_bytes': result['size_bytes']})
    db.commit()
    return result


@export_router.get('/events.csv')
def export_events_csv(
    period: str = Query(default='month'),
    actor: dict = Depends(require_supervisor_or_query_token),
    db: sqlite3.Connection = Depends(get_db),
) -> StreamingResponse:
    try:
        start = period_start(period)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    clauses: list[str] = []
    values: list[object] = []
    if start:
        clauses.append('captured_at >= ?')
        values.append(to_iso(start))
    where = f'WHERE {" AND ".join(clauses)}' if clauses else ''
    rows = db.execute(f'SELECT * FROM ppe_events {where} ORDER BY captured_at DESC', values).fetchall()
    text = io.StringIO()
    writer = csv.writer(text)
    writer.writerow([
        'event_id', 'captured_at', 'camera_id', 'person_track_id', 'status', 'missing_ppe',
        'detected_ppe', 'confidence', 'person_count', 'acknowledged', 'acknowledged_by',
        'acknowledged_at', 'resolved_at', 'duration_seconds', 'model_version', 'image_path',
    ])
    for row in rows:
        writer.writerow([
            row['id'], row['captured_at'], row['camera_id'], row['person_track_id'] or '', row['status'],
            ', '.join(json.loads(row['missing_ppe'])), ', '.join(json.loads(row['detected_ppe'])),
            row['confidence'], row['person_count'], bool(row['acknowledged']), row['acknowledged_by'] or '',
            row['acknowledged_at'] or '', row['resolved_at'] or '', row['duration_seconds'] or '',
            row['model_version'] or '', row['image_rel_path'],
        ])
    write_audit(db, actor=actor, action='export_events_csv', target_type='report', detail={'period': period, 'row_count': len(rows)})
    db.commit()
    filename = f'ppe_events_{period}.csv'
    return StreamingResponse(
        iter([text.getvalue().encode('utf-8-sig')]),
        media_type='text/csv; charset=utf-8',
        headers={'Content-Disposition': f'attachment; filename="{filename}"'},
    )
