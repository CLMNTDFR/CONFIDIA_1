from __future__ import annotations

from datetime import datetime
from uuid import UUID, uuid4

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventUpdateDTO,
    WeekCalendarScope,
)
from core.time import as_utc
from domain.interfaces.calendar_repository import CalendarRepository


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
            start_utc = as_utc(start)
            events = [e for e in events if as_utc(e.end) >= start_utc]
        if end is not None:
            end_utc = as_utc(end)
            events = [e for e in events if as_utc(e.start) <= end_utc]
        events.sort(key=lambda e: as_utc(e.start))
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
            start=as_utc(data.start),
            end=as_utc(data.end),
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
        updates = data.model_dump(exclude_unset=True)
        if updates.get("start") is not None:
            updates["start"] = as_utc(updates["start"])
        if updates.get("end") is not None:
            updates["end"] = as_utc(updates["end"])
        updated = existing.model_copy(update=updates)
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
