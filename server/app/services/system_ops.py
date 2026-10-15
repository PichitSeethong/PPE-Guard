from __future__ import annotations

import shutil
import sqlite3
import zipfile
from datetime import datetime
from pathlib import Path

from ..config import settings
from .time_utils import to_iso, utc_now


def system_health(db: sqlite3.Connection) -> dict:
    usage = shutil.disk_usage(settings.data_dir)
    camera_count = int(db.execute('SELECT COUNT(*) AS count FROM cameras').fetchone()['count'])
    event_count = int(db.execute('SELECT COUNT(*) AS count FROM ppe_events').fetchone()['count'])
    active_users = int(db.execute('SELECT COUNT(*) AS count FROM users WHERE is_active = 1').fetchone()['count'])
    evidence_count = sum(1 for item in settings.evidence_dir.rglob('*') if item.is_file()) if settings.evidence_dir.exists() else 0
    backup_count = sum(1 for item in settings.backup_dir.glob('*.zip') if item.is_file()) if settings.backup_dir.exists() else 0
    return {
        'ok': True,
        'checked_at': to_iso(utc_now()),
        'server_time': to_iso(utc_now()),
        'database_path': str(settings.database_path),
        'evidence_path': str(settings.evidence_dir),
        'storage': {
            'total_bytes': usage.total,
            'used_bytes': usage.used,
            'free_bytes': usage.free,
            'free_percent': round((usage.free / usage.total * 100), 2) if usage.total else 0.0,
        },
        'counts': {
            'cameras': camera_count,
            'events': event_count,
            'evidence_files': evidence_count,
            'active_users': active_users,
            'backup_files': backup_count,
        },
    }


def create_backup() -> dict:
    """Create a compressed snapshot without deleting any source data."""
    settings.backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output = settings.backup_dir / f'ppe_guard_backup_{timestamp}.zip'
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        if settings.database_path.exists():
            archive.write(settings.database_path, arcname='database/ppe_monitoring.db')
        # Including WAL/SHM keeps a recent SQLite state if a backup is run while the server is live.
        for suffix in ('-wal', '-shm'):
            candidate = Path(f'{settings.database_path}{suffix}')
            if candidate.exists():
                archive.write(candidate, arcname=f'database/{candidate.name}')
        if settings.evidence_dir.exists():
            for file in settings.evidence_dir.rglob('*'):
                if file.is_file():
                    archive.write(file, arcname=str(Path('evidence') / file.relative_to(settings.evidence_dir)))
    return {
        'filename': output.name,
        'path': str(output),
        'size_bytes': output.stat().st_size,
        'created_at': to_iso(utc_now()),
    }
