from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class EventType(str, Enum):
    DEADLINE = "deadline"
    MEETING = "meeting"
    REMINDER = "reminder"
    APPOINTMENT = "appointment"


class WeekCalendarScope(str, Enum):
    PERSONAL = "personal"
    FAMILY = "family"
    PROFESSIONAL = "professional"


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
    calendar_scope: WeekCalendarScope = WeekCalendarScope.PERSONAL


class CalendarEventCreateDTO(BaseModel):
    title: str
    description: str | None = None
    start: datetime
    end: datetime
    event_type: EventType = EventType.REMINDER
    location: str | None = None
    all_day: bool = False
    document_id: int | None = None


class CalendarEventUpdateDTO(BaseModel):
    title: str | None = None
    description: str | None = None
    start: datetime | None = None
    end: datetime | None = None
    event_type: EventType | None = None
    location: str | None = None
    all_day: bool | None = None
    document_id: int | None = None


class CalendarEventListResponse(BaseModel):
    items: list[CalendarEventDTO]
    total: int
