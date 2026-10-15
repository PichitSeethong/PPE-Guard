from __future__ import annotations

import json
import sqlite3

from .time_utils import parse_iso, utc_now
from ..config import settings


def user_to_dict(row: sqlite3.Row) -> dict:
    return {
        'id': row['id'],
        'username': row['username'],
        'display_name': row['display_name'],
        'role': row['role'],
        'department': row['department'],
        'is_active': bool(row['is_active']) if 'is_active' in row.keys() else True,
        'must_change_password': bool(row['must_change_password']) if 'must_change_password' in row.keys() else False,
        'token_version': int(row['token_version']) if 'token_version' in row.keys() else 0,
        'created_at': row['created_at'],
        'updated_at': row['updated_at'] if 'updated_at' in row.keys() else row['created_at'],
        'last_login_at': row['last_login_at'] if 'last_login_at' in row.keys() else None,
    }


def camera_to_dict(row: sqlite3.Row) -> dict:
    heartbeat = parse_iso(row['last_heartbeat_at'])
    online = heartbeat is not None and (utc_now() - heartbeat).total_seconds() <= settings.offline_after_seconds
    return {
        'id': row['id'],
        'name': row['name'],
        'location': row['location'],
        'status': 'ONLINE' if online else 'OFFLINE',
        'last_heartbeat_at': row['last_heartbeat_at'],
        'last_status': row['last_status'],
        'last_confidence': row['last_confidence'],
        'model_version': row['model_version'],
    }


def event_to_dict(row: sqlite3.Row) -> dict:
    image_path = row['image_rel_path']
    return {
        'id': row['id'],
        'camera_id': row['camera_id'],
        'person_track_id': row['person_track_id'],
        'status': row['status'],
        'previous_status': row['previous_status'],
        'missing_ppe': json.loads(row['missing_ppe']),
        'detected_ppe': json.loads(row['detected_ppe']),
        'confidence': row['confidence'],
        'person_count': row['person_count'],
        'image_url': f'/api/v1/evidence/{image_path}' if image_path else None,
        'captured_at': row['captured_at'],
        'acknowledged': bool(row['acknowledged']),
        'acknowledged_by': row['acknowledged_by'],
        'acknowledged_at': row['acknowledged_at'],
        'resolved_at': row['resolved_at'],
        'duration_seconds': row['duration_seconds'],
        'model_version': row['model_version'],
        'violation_id': row['violation_id'],
    }


def audit_to_dict(row: sqlite3.Row) -> dict:
    try:
        detail = json.loads(row['detail_json'] or '{}')
    except json.JSONDecodeError:
        detail = {}
    return {
        'id': row['id'],
        'actor_user_id': row['actor_user_id'],
        'actor_username': row['actor_username'],
        'action': row['action'],
        'target_type': row['target_type'],
        'target_id': row['target_id'],
        'detail': detail,
        'created_at': row['created_at'],
    }
