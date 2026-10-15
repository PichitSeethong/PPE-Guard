from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse

from ..config import settings
from ..security import require_user_or_query_token

router = APIRouter(prefix='/api/v1/evidence', tags=['evidence'])


@router.get('/{relative_path:path}')
def get_evidence(relative_path: str, _: dict = Depends(require_user_or_query_token)) -> FileResponse:
    target = (settings.evidence_dir / relative_path).resolve()
    root = settings.evidence_dir.resolve()
    if root not in target.parents or not target.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='ไม่พบรูปหลักฐาน')
    return FileResponse(target, headers={'Cache-Control': 'private, max-age=300'})
