from datetime import date
from enum import Enum

from pydantic import BaseModel, Field

from application.dto.calendar_dto import WeekCalendarScope


class WorkloadLevel(str, Enum):
    CALM = "calm"
    MEDIUM = "medium"
    BUSY = "busy"


class WeekDayOverviewDTO(BaseModel):
    date: date
    day_label: str
    date_label: str
    workload_level: WorkloadLevel
    total_appointments: int
    meeting_count: int
    deadline_count: int
    task_count: int
    load_score: float = Field(ge=0, le=1)


class WeekOverviewResponse(BaseModel):
    week_start: date
    week_end: date
    days: list[WeekDayOverviewDTO]
    active_scopes: list[WeekCalendarScope]
