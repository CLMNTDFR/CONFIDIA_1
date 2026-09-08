from datetime import date, timedelta

from application.dto.calendar_dto import CalendarEventDTO, EventType, WeekCalendarScope
from application.dto.dashboard_dto import (
    WeekDayOverviewDTO,
    WeekOverviewResponse,
    WorkloadLevel,
)

_DAY_LABELS = ["LUNDI", "MARDI", "MERCREDI", "JEUDI", "VENDREDI", "SAMEDI", "DIMANCHE"]
_MONTH_LABELS = [
    "JANV",
    "FÉVR",
    "MARS",
    "AVR",
    "MAI",
    "JUIN",
    "JUIL",
    "AOÛT",
    "SEPT",
    "OCT",
    "NOV",
    "DÉC",
]


class DashboardService:
    """Synthèse hebdomadaire calculée depuis les événements de l'espace."""

    async def get_week_overview(
        self,
        events: list[CalendarEventDTO],
        scopes: list[WeekCalendarScope] | None = None,
        reference: date | None = None,
    ) -> WeekOverviewResponse:
        active_scopes = scopes or list(WeekCalendarScope)
        today = reference or date.today()
        week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=6)
        week_events = [
            event
            for event in events
            if week_start <= event.start.date() <= week_end
            and self._matches_scope(event, active_scopes)
        ]
        days = [
            self._build_day(week_start + timedelta(days=offset), week_events)
            for offset in range(7)
        ]
        return WeekOverviewResponse(
            week_start=week_start,
            week_end=week_end,
            days=days,
            active_scopes=active_scopes,
        )

    def _matches_scope(
        self, event: CalendarEventDTO, scopes: list[WeekCalendarScope]
    ) -> bool:
        return event.calendar_scope in scopes

    def _build_day(
        self, day: date, week_events: list[CalendarEventDTO]
    ) -> WeekDayOverviewDTO:
        day_events = [e for e in week_events if e.start.date() == day]
        meetings = sum(1 for e in day_events if e.event_type == EventType.MEETING)
        deadlines = sum(1 for e in day_events if e.event_type == EventType.DEADLINE)
        tasks = sum(
            1
            for e in day_events
            if e.event_type in (EventType.REMINDER, EventType.APPOINTMENT)
        )
        total = len(day_events)
        score = meetings * 2 + deadlines * 2 + tasks
        level, load_score = self._resolve_workload(score, total)
        return WeekDayOverviewDTO(
            date=day,
            day_label=_DAY_LABELS[day.weekday()],
            date_label=f"{day.day} {_MONTH_LABELS[day.month - 1]}",
            workload_level=level,
            total_appointments=total,
            meeting_count=meetings,
            deadline_count=deadlines,
            task_count=tasks,
            load_score=load_score,
        )

    def _resolve_workload(self, score: int, total: int) -> tuple[WorkloadLevel, float]:
        if score >= 9 or total >= 7:
            return WorkloadLevel.BUSY, min(1.0, 0.72 + total * 0.03)
        if score >= 4 or total >= 3:
            return WorkloadLevel.MEDIUM, min(0.68, 0.38 + total * 0.04)
        return WorkloadLevel.CALM, max(0.12, min(0.32, total * 0.08 + 0.1))
