from __future__ import annotations

import sqlite3
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field

from ..database import get_db
from ..security import create_user, hash_password, require_admin, validate_password
from ..services.audit import write_audit
from ..services.serializers import audit_to_dict, user_to_dict
from ..services.time_utils import to_iso, utc_now

router = APIRouter(prefix='/api/v1/users', tags=['users'])
Role = Literal['admin', 'supervisor', 'viewer']


class CreateUserRequest(BaseModel):
    username: str = Field(min_length=3, max_length=80)
    password: str = Field(min_length=8, max_length=256)
    display_name: str = Field(min_length=1, max_length=120)
    role: Role
    department: str = Field(min_length=1, max_length=120)


class UpdateUserRequest(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=120)
    department: str | None = Field(default=None, min_length=1, max_length=120)
    role: Role | None = None
    is_active: bool | None = None


class ResetPasswordRequest(BaseModel):
    temporary_password: str = Field(min_length=8, max_length=256)


def _user_or_404(db: sqlite3.Connection, user_id: str) -> sqlite3.Row:
    row = db.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='ไม่พบบัญชีผู้ใช้')
    return row


def _active_admin_count(db: sqlite3.Connection) -> int:
    return int(db.execute("SELECT COUNT(*) AS count FROM users WHERE role = 'admin' AND is_active = 1").fetchone()['count'])


@router.get('')
def list_users(
    include_inactive: bool = Query(default=True),
    _: dict = Depends(require_admin),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    where = '' if include_inactive else 'WHERE is_active = 1'
    rows = db.execute(f'SELECT * FROM users {where} ORDER BY is_active DESC, display_name COLLATE NOCASE, username COLLATE NOCASE').fetchall()
    return {'items': [user_to_dict(row) for row in rows]}


@router.post('', status_code=status.HTTP_201_CREATED)
def add_user(
    payload: CreateUserRequest,
    actor: dict = Depends(require_admin),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    try:
        user = create_user(
            db,
            username=payload.username,
            password=payload.password,
            display_name=payload.display_name,
            role=payload.role,
            department=payload.department,
            must_change_password=True,
        )
    except sqlite3.IntegrityError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail='ชื่อผู้ใช้นี้ถูกใช้แล้ว') from exc
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    write_audit(
        db,
        actor=actor,
        action='create_user',
        target_type='user',
        target_id=user['id'],
        detail={'username': user['username'], 'role': user['role'], 'department': user['department']},
    )
    db.commit()
    return user


@router.patch('/{user_id}')
def update_user(
    user_id: str,
    payload: UpdateUserRequest,
    actor: dict = Depends(require_admin),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    target = _user_or_404(db, user_id)
    if not payload.model_fields_set:
        return user_to_dict(target)

    next_role = payload.role or target['role']
    next_active = bool(target['is_active']) if payload.is_active is None else payload.is_active
    would_remove_admin = target['role'] == 'admin' and bool(target['is_active']) and (next_role != 'admin' or not next_active)
    if would_remove_admin and _active_admin_count(db) <= 1:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='ระบบต้องมีผู้ดูแลระบบที่เปิดใช้งานอย่างน้อย 1 บัญชี')
    if user_id == actor['id'] and (next_role != 'admin' or not next_active):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='ไม่สามารถลดสิทธิ์หรือปิดบัญชีของตนเองได้')

    values = {
        'display_name': payload.display_name.strip() if payload.display_name is not None else target['display_name'],
        'department': payload.department.strip() if payload.department is not None else target['department'],
        'role': next_role,
        'is_active': int(next_active),
        'updated_at': to_iso(utc_now()),
    }
    invalidate_sessions = values['role'] != target['role'] or values['is_active'] != int(target['is_active'])
    db.execute(
        '''UPDATE users SET display_name = ?, department = ?, role = ?, is_active = ?, updated_at = ?,
           token_version = token_version + ? WHERE id = ?''',
        (
            values['display_name'], values['department'], values['role'], values['is_active'],
            values['updated_at'], int(invalidate_sessions), user_id,
        ),
    )
    updated = _user_or_404(db, user_id)
    result = user_to_dict(updated)
    write_audit(
        db,
        actor=actor,
        action='update_user',
        target_type='user',
        target_id=user_id,
        detail={
            'from_role': target['role'], 'to_role': result['role'],
            'from_active': bool(target['is_active']), 'to_active': result['is_active'],
            'display_name': result['display_name'], 'department': result['department'],
        },
    )
    db.commit()
    return result


@router.post('/{user_id}/reset-password')
def reset_password(
    user_id: str,
    payload: ResetPasswordRequest,
    actor: dict = Depends(require_admin),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    try:
        validate_password(payload.temporary_password)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    target = _user_or_404(db, user_id)
    if not bool(target['is_active']):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='ไม่สามารถรีเซ็ตรหัสผ่านบัญชีที่ปิดใช้งาน')
    db.execute(
        '''UPDATE users SET password_hash = ?, must_change_password = 1, token_version = token_version + 1,
           failed_login_attempts = 0, locked_until = NULL, updated_at = ? WHERE id = ?''',
        (hash_password(payload.temporary_password), to_iso(utc_now()), user_id),
    )
    updated = _user_or_404(db, user_id)
    result = user_to_dict(updated)
    write_audit(db, actor=actor, action='reset_password', target_type='user', target_id=user_id, detail={'username': result['username']})
    db.commit()
    return result


@router.get('/audit/logs')
def list_audit_logs(
    limit: int = Query(default=100, ge=1, le=500),
    _: dict = Depends(require_admin),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    rows = db.execute('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT ?', (limit,)).fetchall()
    return {'items': [audit_to_dict(row) for row in rows]}
