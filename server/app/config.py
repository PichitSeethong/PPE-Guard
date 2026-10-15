from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BASE_DIR / '.env')


@dataclass(frozen=True)
class Settings:
    data_dir: Path
    database_path: Path
    evidence_dir: Path
    backup_dir: Path
    web_dist_dir: Path
    jwt_secret: str
    jwt_expire_minutes: int
    camera_api_key: str
    offline_after_seconds: int
    timezone: str
    allowed_origins: list[str]
    max_image_bytes: int
    required_ppe: tuple[str, ...]
    login_max_attempts: int
    login_lock_minutes: int


def _data_path() -> Path:
    value = os.getenv('PPE_DATA_DIR', '').strip()
    return Path(value).expanduser().resolve() if value else (BASE_DIR / 'data').resolve()


def _optional_path(variable: str, default: Path) -> Path:
    value = os.getenv(variable, '').strip()
    return Path(value).expanduser().resolve() if value else default.resolve()


def get_settings() -> Settings:
    data_dir = _data_path()
    database_path = _optional_path('PPE_DATABASE_PATH', data_dir / 'database' / 'ppe_monitoring.db')
    evidence_dir = _optional_path('PPE_EVIDENCE_DIR', data_dir / 'evidence')
    backup_dir = _optional_path('PPE_BACKUP_DIR', data_dir / 'backups')
    web_dist_dir = _optional_path('PPE_WEB_DIST_DIR', BASE_DIR / 'www')
    origins = [item.strip() for item in os.getenv('ALLOWED_ORIGINS', '*').split(',') if item.strip()]
    required = tuple(item.strip() for item in os.getenv(
        'REQUIRED_PPE', 'helmet,glasses,gloves,shoes,safety-vest'
    ).split(',') if item.strip())
    return Settings(
        data_dir=data_dir,
        database_path=database_path,
        evidence_dir=evidence_dir,
        backup_dir=backup_dir,
        web_dist_dir=web_dist_dir,
        jwt_secret=os.getenv('JWT_SECRET', 'change-this-before-factory-deployment'),
        jwt_expire_minutes=int(os.getenv('JWT_EXPIRE_MINUTES', '480')),
        camera_api_key=os.getenv('CAMERA_API_KEY', ''),
        offline_after_seconds=int(os.getenv('OFFLINE_AFTER_SECONDS', '300')),
        timezone=os.getenv('FACTORY_TIMEZONE', 'Asia/Bangkok'),
        allowed_origins=origins,
        max_image_bytes=int(os.getenv('MAX_IMAGE_BYTES', str(8 * 1024 * 1024))),
        required_ppe=required,
        login_max_attempts=max(1, int(os.getenv('LOGIN_MAX_ATTEMPTS', '5'))),
        login_lock_minutes=max(1, int(os.getenv('LOGIN_LOCK_MINUTES', '15'))),
    )


settings = get_settings()
