from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventUpdateDTO,
    EventType,
    WeekCalendarScope,
)
from domain.interfaces.calendar_repository import CalendarRepository
from infrastructure.db.models import Calendar, CalendarEvent


def _aware(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value


def _parse_document_id(raw: str | None) -> UUID | None:
    if not raw:
        return None
    try:
        return UUID(raw)
    except ValueError:
        return None


def _to_dto(row: CalendarEvent) -> CalendarEventDTO:
    scope = WeekCalendarScope.FAMILY
    if row.week_scope:
        try:
            scope = WeekCalendarScope(row.week_scope)
        except ValueError:
            scope = WeekCalendarScope.FAMILY
    return CalendarEventDTO(
        id=str(row.id),
        title=row.title,
        description=row.description,
        start=row.starts_at,
        end=row.ends_at,
        event_type=EventType(row.event_type),
        location=row.location,
        all_day=row.all_day,
        color=row.color,
        document_id=str(row.document_id) if row.document_id else None,
        calendar_scope=scope,
        source=row.source,
    )


class PostgresCalendarRepository(CalendarRepository):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def _default_calendar(self, organization_id: UUID) -> Calendar:
        stmt = (
            select(Calendar)
            .where(
                Calendar.organization_id == organization_id,
                Calendar.deleted_at.is_(None),
            )
            .order_by(Calendar.is_default.desc(), Calendar.created_at)
        )
        row = (await self._session.execute(stmt)).scalars().first()
        if row is not None:
            return row
        calendar = Calendar(
            organization_id=organization_id,
            name="Famille",
            slug="family",
            is_default=True,
        )
        self._session.add(calendar)
        await self._session.flush()
        return calendar

    async def list_events(
        self,
        organization_id: UUID,
        start: datetime | None,
        end: datetime | None,
    ) -> list[CalendarEventDTO]:
        filters = [
            CalendarEvent.organization_id == organization_id,
            CalendarEvent.deleted_at.is_(None),
        ]
        if start is not None:
            filters.append(CalendarEvent.ends_at >= _aware(start))
        if end is not None:
            filters.append(CalendarEvent.starts_at <= _aware(end))
        stmt = select(CalendarEvent).where(*filters).order_by(CalendarEvent.starts_at)
        rows = (await self._session.scalars(stmt)).all()
        return [_to_dto(row) for row in rows]

    async def get_event(
        self, organization_id: UUID, event_id: UUID
    ) -> CalendarEventDTO | None:
        stmt = select(CalendarEvent).where(
            CalendarEvent.id == event_id,
            CalendarEvent.organization_id == organization_id,
            CalendarEvent.deleted_at.is_(None),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return _to_dto(row) if row else None

    async def create_event(
        self,
        *,
        organization_id: UUID,
        owner_id: str,
        data: CalendarEventCreateDTO,
    ) -> CalendarEventDTO:
        calendar = await self._default_calendar(organization_id)
        event_id = uuid4()
        row = CalendarEvent(
            id=event_id,
            calendar_id=calendar.id,
            organization_id=organization_id,
            title=data.title.strip(),
            description=data.description,
            location=data.location,
            starts_at=_aware(data.start),
            ends_at=_aware(data.end),
            all_day=data.all_day,
            event_type=data.event_type.value,
            color=data.color,
            document_id=_parse_document_id(data.document_id),
            source="confidia",
            week_scope=data.calendar_scope.value,
            created_by=owner_id,
        )
        self._session.add(row)
        await self._session.flush()
        return _to_dto(row)

    async def update_event(
        self,
        organization_id: UUID,
        event_id: UUID,
        data: CalendarEventUpdateDTO,
    ) -> CalendarEventDTO | None:
        stmt = select(CalendarEvent).where(
            CalendarEvent.id == event_id,
            CalendarEvent.organization_id == organization_id,
            CalendarEvent.deleted_at.is_(None),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is None:
            return None
        payload = data.model_dump(exclude_unset=True)
        if "title" in payload and payload["title"]:
            row.title = str(payload["title"]).strip()
        if "description" in payload:
            row.description = payload["description"]
        if "location" in payload:
            row.location = payload["location"]
        if "start" in payload and payload["start"] is not None:
            row.starts_at = _aware(payload["start"])
        if "end" in payload and payload["end"] is not None:
            row.ends_at = _aware(payload["end"])
        if "all_day" in payload and payload["all_day"] is not None:
            row.all_day = payload["all_day"]
        if "event_type" in payload and payload["event_type"] is not None:
            value = payload["event_type"]
            row.event_type = value.value if isinstance(value, EventType) else str(value)
        if "color" in payload:
            row.color = payload["color"]
        if "document_id" in payload:
            row.document_id = _parse_document_id(payload["document_id"])
        if "calendar_scope" in payload and payload["calendar_scope"] is not None:
            scope = payload["calendar_scope"]
            row.week_scope = scope.value if isinstance(scope, WeekCalendarScope) else str(scope)
        await self._session.flush()
        return _to_dto(row)

    async def delete_event(self, organization_id: UUID, event_id: UUID) -> bool:
        stmt = select(CalendarEvent).where(
            CalendarEvent.id == event_id,
            CalendarEvent.organization_id == organization_id,
            CalendarEvent.deleted_at.is_(None),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        if row is None:
            return False
        row.deleted_at = datetime.now(UTC)
        await self._session.flush()
        return True
