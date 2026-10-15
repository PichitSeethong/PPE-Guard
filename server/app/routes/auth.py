from __future__ import annotations

import sqlite3
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from ..config import settings
from ..database import get_db
from ..security import create_access_token, hash_password, require_user, validate_password, verify_password
from ..services.audit import write_audit
from ..services.serializers import user_to_dict
from ..services.time_utils import parse_iso, to_iso, utc_now

router = APIRouter(prefix='/api/v1/auth', tags=['auth'])


class LoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=80)
    password: str = Field(min_length=1, max_length=256)


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=8, max_length=256)


def _login_failure(db: sqlite3.Connection, row: sqlite3.Row) -> None:
    attempts = int(row['failed_login_attempts'] or 0) + 1
    locked_until = None
    if attempts >= settings.login_max_attempts:
        locked_until = to_iso(utc_now() + timedelta(minutes=settings.login_lock_minutes))
        attempts = 0
    db.execute(
        'UPDATE users SET failed_login_attempts = ?, locked_until = ?, updated_at = ? WHERE id = ?',
        (attempts, locked_until, to_iso(utc_now()), row['id']),
    )
    db.commit()


@router.post('/login')
def login(payload: LoginRequest, db: sqlite3.Connection = Depends(get_db)) -> dict:
    row = db.execute('SELECT * FROM users WHERE username = ?', (payload.username.strip(),)).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง')

    if not bool(row['is_active']):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='บัญชีนี้ถูกปิดการใช้งาน โปรดติดต่อ จป. หรือผู้ดูแลระบบ')

    locked_until = parse_iso(row['locked_until'])
    if locked_until and locked_until > utc_now():
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail='บัญชีถูกล็อกชั่วคราวจากการใส่รหัสผิดหลายครั้ง กรุณาลองใหม่ภายหลัง')

    if not verify_password(payload.password, row['password_hash']):
        _login_failure(db, row)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง')

    now = to_iso(utc_now())
    db.execute(
        '''UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login_at = ?, updated_at = ?
           WHERE id = ?''',
        (now, now, row['id']),
    )
    row = db.execute('SELECT * FROM users WHERE id = ?', (row['id'],)).fetchone()
    user = user_to_dict(row)
    write_audit(db, actor=user, action='login', target_type='user', target_id=user['id'])
    db.commit()
    return {'access_token': create_access_token(user), 'token_type': 'bearer', 'user': user}


@router.get('/me')
def me(user: dict = Depends(require_user)) -> dict:
    return user


@router.post('/change-password')
def change_password(
    payload: ChangePasswordRequest,
    user: dict = Depends(require_user),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    row = db.execute('SELECT * FROM users WHERE id = ?', (user['id'],)).fetchone()
    if row is None or not verify_password(payload.current_password, row['password_hash']):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='รหัสผ่านปัจจุบันไม่ถูกต้อง')
    try:
        validate_password(payload.new_password)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    if verify_password(payload.new_password, row['password_hash']):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม')

    now = to_iso(utc_now())
    db.execute(
        '''UPDATE users SET password_hash = ?, must_change_password = 0, token_version = token_version + 1,
           failed_login_attempts = 0, locked_until = NULL, updated_at = ? WHERE id = ?''',
        (hash_password(payload.new_password), now, user['id']),
    )
    updated = db.execute('SELECT * FROM users WHERE id = ?', (user['id'],)).fetchone()
    result = user_to_dict(updated)
    write_audit(db, actor=result, action='change_password', target_type='user', target_id=result['id'])
    db.commit()
    return {'access_token': create_access_token(result), 'token_type': 'bearer', 'user': result}
