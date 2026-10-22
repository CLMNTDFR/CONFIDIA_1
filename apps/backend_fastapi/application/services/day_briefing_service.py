from datetime import date

from application.dto.calendar_dto import CalendarEventDTO, EventType
from application.dto.serenity_dto import (
    DayAppointmentDTO,
    DayBriefingResponse,
    DayPriorityDTO,
    SerenityActionDTO,
    SerenityDomain,
)
from application.services.serenity_service import SerenityService, first_name_from_token, greet
from core.security import TokenPayload
from core.time import civil_date, civil_now


class DayBriefingService:
    """Day briefing from real events. Payments and mail stay out of the MVP."""

    def __init__(self, serenity_service: SerenityService | None = None):
        self._serenity = serenity_service or SerenityService()

    async def get_day_briefing(
        self,
        token: TokenPayload | None = None,
        events: list[CalendarEventDTO] | None = None,
        zone: str | None = None,
    ) -> DayBriefingResponse:
        items = events or []
        briefing = await self._serenity.get_briefing(token=token, events=items, zone=zone)
        first_name = first_name_from_token(token)
        now = civil_now(zone)
        appointments = self._todays_appointments(items, now.date(), zone)
        priorities = self._priorities_from_actions(briefing.actions)
        summary = self._narrative(
            first_name=first_name,
            current_score=briefing.score,
            priorities=priorities,
            appointments=appointments,
        )
        return DayBriefingResponse(
            greeting=greet(first_name),
            summary=summary,
            priorities=priorities,
            urgent_payments=[],
            todays_appointments=appointments,
            new_documents=[],
            current_score=briefing.score,
            projected_score=briefing.score,
            value_message=None,
            generated_at=now,
        )

    def _todays_appointments(
        self, events: list[CalendarEventDTO], today: date, zone: str | None
    ) -> list[DayAppointmentDTO]:
        appointments: list[DayAppointmentDTO] = []
        for event in events:
            if civil_date(event.start, zone) != today:
                continue
            if event.event_type not in (EventType.APPOINTMENT, EventType.MEETING):
                continue
            appointments.append(
                DayAppointmentDTO(
                    id=event.id,
                    title=event.title,
                    start=event.start,
                    end=event.end,
                    location=event.location,
                    event_type=event.event_type.value,
                )
            )
        return sorted(appointments, key=lambda a: a.start)

    def _priorities_from_actions(self, actions: list[SerenityActionDTO]) -> list[DayPriorityDTO]:
        return [
            DayPriorityDTO(
                id=action.id,
                label=action.label,
                description=action.description,
                route=action.route,
                domain=self._domain_for_route(action.route),
                priority=action.priority,
            )
            for action in actions[:3]
        ]

    def _domain_for_route(self, route: str) -> SerenityDomain:
        if route.startswith("/calendar"):
            return SerenityDomain.CALENDAR
        if route.startswith("/documents"):
            return SerenityDomain.DOCUMENTS
        if route.startswith("/payments"):
            return SerenityDomain.PAYMENTS
        if route.startswith("/messaging"):
            return SerenityDomain.MESSAGING
        return SerenityDomain.NOTIFICATIONS

    def _narrative(
        self,
        *,
        first_name: str,
        current_score: int,
        priorities: list[DayPriorityDTO],
        appointments: list[DayAppointmentDTO],
    ) -> str:
        opening = (
            f"{first_name}, voici le point de départ de votre journée."
            if first_name
            else "Voici le point de départ de votre journée."
        )
        parts = [
            opening,
            f"Indice de sérénité actuel : {current_score}/100.",
        ]
        if priorities:
            labels = ", ".join(p.label.lower() for p in priorities)
            parts.append(f"Priorités suggérées : {labels}.")
        if appointments:
            parts.append(f"{len(appointments)} rendez-vous ou réunion(s) inscrit(s) aujourd'hui.")
        else:
            parts.append("Aucun rendez-vous prévu aujourd'hui.")
        return " ".join(parts)
