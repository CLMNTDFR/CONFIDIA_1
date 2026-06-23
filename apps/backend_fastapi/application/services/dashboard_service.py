from datetime import date, datetime, timedelta

from application.dto.calendar_dto import CalendarEventDTO, EventType
from application.dto.dashboard_dto import (
    WeekCalendarScope,
    WeekDayOverviewDTO,
    WeekOverviewResponse,
    WorkloadLevel,
)
from application.services.calendar_service import CalendarService


_SCOPE_LABELS = {
    WeekCalendarScope.PERSONAL: "Personnel",
    WeekCalendarScope.FAMILY: "Familial",
    WeekCalendarScope.PROFESSIONAL: "Professionnel",
}

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
    """Tableau de bord  -  synthèse hebdomadaire calculée depuis le calendrier."""

    def __init__(self, calendar_service: CalendarService | None = None):
        self._calendar = calendar_service or CalendarService()

    async def get_week_overview(
        self,
        scopes: list[WeekCalendarScope] | None = None,
        reference: date | None = None,
    ) -> WeekOverviewResponse:
        active_scopes = scopes or list(WeekCalendarScope)
        today = reference or date.today()
        week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=6)

        events = self._calendar._events  # mock interne  -  prêt pour agrégation CalDAV
        week_events = [
            e
            for e in events
            if week_start <= e.start.date() <= week_end and self._event_matches_scope(e, active_scopes)
        ]

        days: list[WeekDayOverviewDTO] = []
        for offset in range(7):
            day = week_start + timedelta(days=offset)
            day_events = [e for e in week_events if e.start.date() == day]
            days.append(self._build_day(day, day_events))

        return WeekOverviewResponse(
            week_start=week_start,
            week_end=week_end,
            days=days,
            active_scopes=active_scopes,
        )

    def _event_matches_scope(self, event: CalendarEventDTO, scopes: list[WeekCalendarScope]) -> bool:
        return event.calendar_scope in scopes

    def _build_day(self, day: date, events: list[CalendarEventDTO]) -> WeekDayOverviewDTO:
        meetings = sum(1 for e in events if e.event_type == EventType.MEETING)
        deadlines = sum(1 for e in events if e.event_type == EventType.DEADLINE)
        tasks = sum(
            1
            for e in events
            if e.event_type in (EventType.REMINDER, EventType.APPOINTMENT)
        )
        total = len(events)
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
