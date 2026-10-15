from __future__ import annotations

import re
from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile, status

from zoneinfo import ZoneInfo

from ..config import settings


def _safe_camera_id(camera_id: str) -> str:
    return re.sub(r'[^A-Za-z0-9_-]+', '_', camera_id).strip('_') or 'camera'


async def save_evidence(upload: UploadFile, camera_id: str, captured_at, event_status: str) -> str:
    content_type = (upload.content_type or '').lower()
    if content_type not in {'image/jpeg', 'image/jpg', 'image/png'}:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail='รองรับเฉพาะภาพ JPEG หรือ PNG')

    data = await upload.read()
    if not data:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail='ไฟล์รูปหลักฐานว่าง')
    if len(data) > settings.max_image_bytes:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail='รูปหลักฐานมีขนาดใหญ่เกินกำหนด')

    local_time = captured_at.astimezone(ZoneInfo(settings.timezone)).replace(tzinfo=None)
    relative_dir = Path(f'{local_time:%Y}') / f'{local_time:%m}' / f'{local_time:%d}'
    extension = '.png' if content_type == 'image/png' else '.jpg'
    filename = f'{_safe_camera_id(camera_id)}_{local_time:%Y%m%d_%H%M%S}_{event_status.lower()}_{uuid4().hex[:8]}{extension}'
    target = (settings.evidence_dir / relative_dir / filename).resolve()
    evidence_root = settings.evidence_dir.resolve()
    if evidence_root not in target.parents:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='ตำแหน่งเก็บรูปไม่ถูกต้อง')

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    return (relative_dir / filename).as_posix()
