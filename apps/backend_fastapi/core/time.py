"""Calendar instants are stored in UTC. A civil day uses the user timezone."""

from datetime import UTC, date, datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

DEFAULT_TIMEZONE = "Europe/Paris"


def resolve_zone(name: str | None) -> ZoneInfo:
    try:
        return ZoneInfo(name or DEFAULT_TIMEZONE)
    except ZoneInfoNotFoundError:
        return ZoneInfo(DEFAULT_TIMEZONE)


def as_utc(value: datetime) -> datetime:
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("Le fuseau horaire est requis")
    return value.astimezone(UTC)


def civil_now(zone_name: str | None = None) -> datetime:
    return datetime.now(resolve_zone(zone_name))


def civil_date(value: datetime, zone_name: str | None = None) -> date:
    return as_utc(value).astimezone(resolve_zone(zone_name)).date()
