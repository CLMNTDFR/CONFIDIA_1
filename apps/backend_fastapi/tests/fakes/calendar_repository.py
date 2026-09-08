from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID, uuid4

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventUpdateDTO,
    WeekCalendarScope,
)
from domain.interfaces.calendar_repository import CalendarRepository


def _aware(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value


class InMemoryCalendarRepository(CalendarRepository):
    def __init__(self) -> None:
        self.rows: dict[UUID, list[CalendarEventDTO]] = {}

    def _bucket(self, organization_id: UUID) -> list[CalendarEventDTO]:
        return self.rows.setdefault(organization_id, [])

    async def list_events(
        self,
        organization_id: UUID,
        start: datetime | None,
        end: datetime | None,
    ) -> list[CalendarEventDTO]:
        events = list(self._bucket(organization_id))
        if start is not None:
            start_aware = _aware(start)
            events = [e for e in events if _aware(e.end) >= start_aware]
        if end is not None:
            end_aware = _aware(end)
            events = [e for e in events if _aware(e.start) <= end_aware]
        events.sort(key=lambda e: e.start)
        return events

    async def get_event(
        self, organization_id: UUID, event_id: UUID
    ) -> CalendarEventDTO | None:
        target = str(event_id)
        for event in self._bucket(organization_id):
            if event.id == target:
                return event
        return None

    async def create_event(
        self,
        *,
        organization_id: UUID,
        owner_id: str,
        data: CalendarEventCreateDTO,
    ) -> CalendarEventDTO:
        event = CalendarEventDTO(
            id=str(uuid4()),
            title=data.title.strip(),
            description=data.description,
            start=_aware(data.start),
            end=_aware(data.end),
            event_type=data.event_type,
            location=data.location,
            all_day=data.all_day,
            color=data.color,
            document_id=data.document_id,
            calendar_scope=data.calendar_scope or WeekCalendarScope.FAMILY,
            source="confidia",
        )
        self._bucket(organization_id).append(event)
        return event

    async def update_event(
        self,
        organization_id: UUID,
        event_id: UUID,
        data: CalendarEventUpdateDTO,
    ) -> CalendarEventDTO | None:
        existing = await self.get_event(organization_id, event_id)
        if existing is None:
            return None
        updated = existing.model_copy(update=data.model_dump(exclude_unset=True))
        bucket = self._bucket(organization_id)
        self.rows[organization_id] = [
            updated if item.id == existing.id else item for item in bucket
        ]
        return updated

    async def delete_event(self, organization_id: UUID, event_id: UUID) -> bool:
        bucket = self._bucket(organization_id)
        target = str(event_id)
        kept = [item for item in bucket if item.id != target]
        if len(kept) == len(bucket):
            return False
        self.rows[organization_id] = kept
        return True
