from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class EventType(str, Enum):
    DEADLINE = "deadline"
    MEETING = "meeting"
    REMINDER = "reminder"
    APPOINTMENT = "appointment"


class CalendarEventDTO(BaseModel):
    id: str
    title: str
    description: str | None = None
    start: datetime
    end: datetime
    event_type: EventType = EventType.REMINDER
    location: str | None = None
    all_day: bool = False
    color: str | None = None
    document_id: int | None = None


class CalendarEventCreateDTO(BaseModel):
    title: str
    description: str | None = None
    start: datetime
    end: datetime
    event_type: EventType = EventType.REMINDER
    location: str | None = None
    all_day: bool = False
    document_id: int | None = None


class CalendarEventListResponse(BaseModel):
    items: list[CalendarEventDTO]
    total: int
