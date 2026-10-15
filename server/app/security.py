from __future__ import annotations

import base64
import hashlib
import hmac
import os
import re
import sqlite3
from datetime import timedelta
from uuid import uuid4

import jwt
from fastapi import Depends, Header, HTTPException, Query, status

from .config import settings
from .database import get_db
from .services.serializers import user_to_dict
from .services.time_utils import to_iso, utc_now

_USERNAME_PATTERN = re.compile(r'^[a-zA-Z0-9._-]{3,80}$')
_VALID_ROLES = {'admin', 'supervisor', 'viewer'}


def hash_password(password: str) -> str:
    """Store passwords with PBKDF2-SHA256 using a random per-user salt."""
    iterations = 310_000
    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, iterations)
    return 'pbkdf2_sha256${}${}${}'.format(
        iterations,
        base64.urlsafe_b64encode(salt).decode('ascii'),
        base64.urlsafe_b64encode(digest).decode('ascii'),
    )


def verify_password(password: str, password_hash: str) -> bool:
    try:
        algorithm, raw_iterations, raw_salt, raw_digest = password_hash.split('$', 3)
        if algorithm != 'pbkdf2_sha256':
            return False
        iterations = int(raw_iterations)
        salt = base64.urlsafe_b64decode(raw_salt.encode('ascii'))
        expected = base64.urlsafe_b64decode(raw_digest.encode('ascii'))
        calculated = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, iterations)
        return hmac.compare_digest(calculated, expected)
    except (ValueError, TypeError):
        return False


def validate_username(username: str) -> str:
    normalized = username.strip()
    if not _USERNAME_PATTERN.match(normalized):
        raise ValueError('ชื่อผู้ใช้ต้องมี 3-80 ตัวอักษร และใช้ได้เฉพาะ a-z, A-Z, 0-9, จุด, ขีดกลาง หรือ _')
    return normalized


def validate_password(password: str) -> None:
    if len(password) < 8:
        raise ValueError('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร')
    if len(password) > 256:
        raise ValueError('รหัสผ่านยาวเกินกำหนด')


def create_user(
    db: sqlite3.Connection,
    username: str,
    password: str,
    display_name: str,
    role: str,
    department: str,
    *,
    must_change_password: bool = True,
) -> dict:
    normalized_username = validate_username(username)
    if role not in _VALID_ROLES:
        raise ValueError('role ต้องเป็น admin, supervisor หรือ viewer')
    validate_password(password)
    if not display_name.strip():
        raise ValueError('กรุณาระบุชื่อที่แสดง')
    if not department.strip():
        raise ValueError('กรุณาระบุหน่วยงาน')
    user_id = str(uuid4())
    now = to_iso(utc_now())
    db.execute(
        '''INSERT INTO users (
            id, username, password_hash, display_name, role, department, is_active, token_version,
            must_change_password, failed_login_attempts, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, 1, 0, ?, 0, ?, ?)''',
        (
            user_id,
            normalized_username,
            hash_password(password),
            display_name.strip(),
            role,
            department.strip(),
            int(must_change_password),
            now,
            now,
        ),
    )
    row = db.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    return user_to_dict(row)


def create_access_token(user: dict) -> str:
    expires = utc_now() + timedelta(minutes=settings.jwt_expire_minutes)
    return jwt.encode(
        {
            'sub': user['id'],
            'username': user['username'],
            'role': user['role'],
            'ver': int(user.get('token_version', 0)),
            'exp': expires,
        },
        settings.jwt_secret,
        algorithm='HS256',
    )


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=['HS256'])
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่') from exc
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='โทเค็นไม่ถูกต้อง') from exc


def _extract_bearer(authorization: str | None) -> str:
    if not authorization or not authorization.lower().startswith('bearer '):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='กรุณาเข้าสู่ระบบก่อนใช้งาน')
    return authorization.split(' ', 1)[1].strip()


def _get_user_for_token(db: sqlite3.Connection, token: str) -> dict:
    payload = decode_access_token(token)
    user_id = payload.get('sub')
    row = db.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='ไม่พบบัญชีผู้ใช้')
    user = user_to_dict(row)
    if not user['is_active']:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='บัญชีนี้ถูกปิดการใช้งานแล้ว')
    if int(payload.get('ver', -1)) != int(user['token_version']):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='เซสชันนี้ถูกยกเลิกแล้ว กรุณาเข้าสู่ระบบใหม่')
    return user


def require_user(
    authorization: str | None = Header(default=None),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    return _get_user_for_token(db, _extract_bearer(authorization))


def require_user_or_query_token(
    authorization: str | None = Header(default=None),
    token: str | None = Query(default=None),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    value = token or _extract_bearer(authorization)
    return _get_user_for_token(db, value)


def require_supervisor(user: dict = Depends(require_user)) -> dict:
    if user['role'] not in {'admin', 'supervisor'}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='บัญชีนี้ไม่มีสิทธิ์ดำเนินการนี้')
    return user


def require_admin(user: dict = Depends(require_user)) -> dict:
    if user['role'] != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='เฉพาะผู้ดูแลระบบเท่านั้นที่ดำเนินการนี้ได้')
    return user


def require_camera(x_camera_key: str | None = Header(default=None)) -> None:
    if not settings.camera_api_key:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail='Server ยังไม่ได้ตั้ง CAMERA_API_KEY')
    if x_camera_key is None or not hmac.compare_digest(x_camera_key, settings.camera_api_key):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='X-Camera-Key ไม่ถูกต้อง')
