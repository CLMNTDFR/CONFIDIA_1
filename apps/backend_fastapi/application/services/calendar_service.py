from datetime import datetime
from uuid import UUID

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventListResponse,
    CalendarEventUpdateDTO,
)
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
        if data.end < data.start:
            raise ValueError("La fin doit être après le début")
        payload = data.model_copy(update={"title": title})
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
        if payload.start is not None and payload.end is not None and payload.end < payload.start:
            raise ValueError("La fin doit être après le début")
        return await self._repository.update_event(organization_id, event_id, payload)

    async def delete_event(self, organization_id: UUID, event_id: UUID) -> bool:
        return await self._repository.delete_event(organization_id, event_id)
