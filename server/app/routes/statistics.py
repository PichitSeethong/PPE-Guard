from __future__ import annotations

import sqlite3

from fastapi import APIRouter, Depends, HTTPException, Query

from ..database import get_db
from ..security import require_user
from ..services.statistics import statistics_for_period

router = APIRouter(prefix='/api/v1/statistics', tags=['statistics'])


@router.get('')
def get_statistics(
    period: str = Query(default='today'),
    _: dict = Depends(require_user),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    try:
        return statistics_for_period(db, period)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
