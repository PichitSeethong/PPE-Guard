from __future__ import annotations

from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from ..config import settings


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def to_iso(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=ZoneInfo(settings.timezone))
    return value.astimezone(timezone.utc).isoformat()


def parse_iso(value: str | None) -> datetime | None:
    if not value:
        return None
    normalized = value.replace('Z', '+00:00')
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=ZoneInfo(settings.timezone))
    return parsed.astimezone(timezone.utc)


def period_start(period: str) -> datetime | None:
    now = utc_now().astimezone(ZoneInfo(settings.timezone))
    if period == 'today':
        return now.replace(hour=0, minute=0, second=0, microsecond=0).astimezone(timezone.utc)
    if period == 'week':
        return (now - timedelta(days=7)).astimezone(timezone.utc)
    if period == 'month':
        return (now - timedelta(days=30)).astimezone(timezone.utc)
    if period == 'all':
        return None
    raise ValueError('period ต้องเป็น today, week, month หรือ all')
