from datetime import datetime
from uuid import UUID

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventListResponse,
    CalendarEventUpdateDTO,
)
from core.time import as_utc
from domain.interfaces.calendar_repository import CalendarRepository


class CalendarService:
    def __init__(self, repository: CalendarRepository):
        self._repository = repository

    async def list_events(
        self,
        organization_id: UUID,
        start: datetime | None = None,
        end: datetime | None = None,
    ) -> CalendarEventListResponse:
        if start is not None:
            start = as_utc(start)
        if end is not None:
            end = as_utc(end)
        items = await self._repository.list_events(organization_id, start, end)
        return CalendarEventListResponse(items=items, total=len(items))

    async def get_event(
        self, organization_id: UUID, event_id: UUID
    ) -> CalendarEventDTO | None:
        return await self._repository.get_event(organization_id, event_id)

    async def create_event(
        self,
        organization_id: UUID,
        owner_id: str,
        data: CalendarEventCreateDTO,
    ) -> CalendarEventDTO:
        title = data.title.strip()
        if not title:
            raise ValueError("Le titre est requis")
        start = as_utc(data.start)
        end = as_utc(data.end)
        if end < start:
            raise ValueError("La fin doit être après le début")
        payload = data.model_copy(update={"title": title, "start": start, "end": end})
        return await self._repository.create_event(
            organization_id=organization_id,
            owner_id=owner_id,
            data=payload,
        )

    async def update_event(
        self,
        organization_id: UUID,
        event_id: UUID,
        data: CalendarEventUpdateDTO,
    ) -> CalendarEventDTO | None:
        payload = data
        if data.title is not None:
            title = data.title.strip()
            if not title:
                raise ValueError("Le titre est requis")
            payload = data.model_copy(update={"title": title})
        times: dict[str, datetime] = {}
        if payload.start is not None:
            times["start"] = as_utc(payload.start)
        if payload.end is not None:
            times["end"] = as_utc(payload.end)
        if times:
            payload = payload.model_copy(update=times)
            current = await self._repository.get_event(organization_id, event_id)
            if current is None:
                return None
            start = payload.start if payload.start is not None else as_utc(current.start)
            end = payload.end if payload.end is not None else as_utc(current.end)
            if end < start:
                raise ValueError("La fin doit être après le début")
        return await self._repository.update_event(organization_id, event_id, payload)

    async def delete_event(self, organization_id: UUID, event_id: UUID) -> bool:
        return await self._repository.delete_event(organization_id, event_id)
