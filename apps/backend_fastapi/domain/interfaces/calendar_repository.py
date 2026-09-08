from abc import ABC, abstractmethod
from datetime import datetime
from uuid import UUID

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventUpdateDTO,
)


class CalendarRepository(ABC):
    @abstractmethod
    async def list_events(
        self,
        organization_id: UUID,
        start: datetime | None,
        end: datetime | None,
    ) -> list[CalendarEventDTO]:
        ...

    @abstractmethod
    async def get_event(
        self, organization_id: UUID, event_id: UUID
    ) -> CalendarEventDTO | None:
        ...

    @abstractmethod
    async def create_event(
        self,
        *,
        organization_id: UUID,
        owner_id: str,
        data: CalendarEventCreateDTO,
    ) -> CalendarEventDTO:
        ...

    @abstractmethod
    async def update_event(
        self,
        organization_id: UUID,
        event_id: UUID,
        data: CalendarEventUpdateDTO,
    ) -> CalendarEventDTO | None:
        ...

    @abstractmethod
    async def delete_event(self, organization_id: UUID, event_id: UUID) -> bool:
        ...
