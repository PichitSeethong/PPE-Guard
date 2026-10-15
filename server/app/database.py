from __future__ import annotations

import sqlite3
from collections.abc import Generator

from .config import settings


def get_connection() -> sqlite3.Connection:
    settings.database_path.parent.mkdir(parents=True, exist_ok=True)
    settings.evidence_dir.mkdir(parents=True, exist_ok=True)
    settings.backup_dir.mkdir(parents=True, exist_ok=True)
    settings.web_dist_dir.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(settings.database_path, timeout=20, check_same_thread=False)
    connection.row_factory = sqlite3.Row
    connection.execute('PRAGMA foreign_keys = ON')
    connection.execute('PRAGMA journal_mode = WAL')
    return connection


def get_db() -> Generator[sqlite3.Connection, None, None]:
    connection = get_connection()
    try:
        yield connection
    finally:
        connection.close()


def _ensure_column(connection: sqlite3.Connection, table: str, column: str, definition: str) -> None:
    existing = {row['name'] for row in connection.execute(f'PRAGMA table_info({table})').fetchall()}
    if column not in existing:
        connection.execute(f'ALTER TABLE {table} ADD COLUMN {column} {definition}')


def init_db() -> None:
    connection = get_connection()
    try:
        connection.executescript(
            '''
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                username TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                display_name TEXT NOT NULL,
                role TEXT NOT NULL CHECK(role IN ('admin', 'supervisor', 'viewer')),
                department TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                token_version INTEGER NOT NULL DEFAULT 0,
                must_change_password INTEGER NOT NULL DEFAULT 0,
                failed_login_attempts INTEGER NOT NULL DEFAULT 0,
                locked_until TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                last_login_at TEXT
            );

            CREATE TABLE IF NOT EXISTS cameras (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                location TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'ONLINE',
                last_heartbeat_at TEXT,
                last_status TEXT,
                last_confidence REAL,
                model_version TEXT,
                updated_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS ppe_events (
                id TEXT PRIMARY KEY,
                camera_id TEXT NOT NULL,
                person_track_id TEXT,
                status TEXT NOT NULL CHECK(status IN ('SAFE', 'NOT_SAFE')),
                previous_status TEXT,
                missing_ppe TEXT NOT NULL,
                detected_ppe TEXT NOT NULL,
                confidence REAL NOT NULL,
                person_count INTEGER NOT NULL,
                image_rel_path TEXT NOT NULL,
                captured_at TEXT NOT NULL,
                acknowledged INTEGER NOT NULL DEFAULT 0,
                acknowledged_by TEXT,
                acknowledged_at TEXT,
                resolved_at TEXT,
                duration_seconds INTEGER,
                model_version TEXT,
                violation_id TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY(camera_id) REFERENCES cameras(id)
            );

            CREATE TABLE IF NOT EXISTS status_periods (
                id TEXT PRIMARY KEY,
                camera_id TEXT NOT NULL,
                status TEXT NOT NULL CHECK(status IN ('SAFE', 'NOT_SAFE')),
                started_at TEXT NOT NULL,
                ended_at TEXT,
                source_event_id TEXT NOT NULL,
                FOREIGN KEY(camera_id) REFERENCES cameras(id),
                FOREIGN KEY(source_event_id) REFERENCES ppe_events(id)
            );

            CREATE TABLE IF NOT EXISTS audit_logs (
                id TEXT PRIMARY KEY,
                actor_user_id TEXT,
                actor_username TEXT,
                action TEXT NOT NULL,
                target_type TEXT NOT NULL,
                target_id TEXT,
                detail_json TEXT NOT NULL DEFAULT '{}',
                created_at TEXT NOT NULL
            );

            '''
        )

        # Migrate legacy databases created before user-management was introduced.
        _ensure_column(connection, 'users', 'is_active', 'INTEGER NOT NULL DEFAULT 1')
        _ensure_column(connection, 'users', 'token_version', 'INTEGER NOT NULL DEFAULT 0')
        _ensure_column(connection, 'users', 'must_change_password', 'INTEGER NOT NULL DEFAULT 0')
        _ensure_column(connection, 'users', 'failed_login_attempts', 'INTEGER NOT NULL DEFAULT 0')
        _ensure_column(connection, 'users', 'locked_until', 'TEXT')
        _ensure_column(connection, 'users', 'updated_at', 'TEXT')
        _ensure_column(connection, 'users', 'last_login_at', 'TEXT')
        connection.execute("UPDATE users SET updated_at = COALESCE(updated_at, created_at)")

        # Create indexes only after legacy columns have been added.  Older
        # PPE Guard databases do not have users.is_active yet; creating this
        # index before the migration makes SQLite abort application startup.
        connection.executescript(
            '''
            CREATE INDEX IF NOT EXISTS idx_events_camera_captured ON ppe_events(camera_id, captured_at DESC);
            CREATE INDEX IF NOT EXISTS idx_events_status_captured ON ppe_events(status, captured_at DESC);
            CREATE INDEX IF NOT EXISTS idx_periods_camera_started ON status_periods(camera_id, started_at DESC);
            CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active, role);
            CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at DESC);
            '''
        )
        connection.commit()
    finally:
        connection.close()
