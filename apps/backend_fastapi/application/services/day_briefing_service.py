from datetime import date, datetime, timedelta

from application.dto.calendar_dto import EventType
from application.dto.serenity_dto import (
    DayAppointmentDTO,
    DayBriefingResponse,
    DayDocumentDTO,
    DayPriorityDTO,
    DayUrgentPaymentDTO,
    SerenityActionDTO,
    SerenityBriefingResponse,
    SerenityDomain,
)
from application.services.calendar_service import CalendarService
from application.services.serenity_service import SerenityService
from core.security import TokenPayload

# Paiements mock urgents (alignés sur le briefing sérénité).
_MOCK_URGENT_PAYMENTS: list[tuple[str, str, float, int]] = [
    ("pay-edf", "EDF", 87.40, 5),
    ("pay-axa", "Assurance habitation", 42.00, 1),
]

# Documents récents / importants (mock en attendant le dépôt documentaire).
_MOCK_NEW_DOCUMENTS: list[tuple[int, str, str, bool]] = [
    (1, "Facture EDF mars 2026", "facture", True),
    (4, "Attestation employeur", "attestation", False),
    (2, "Avis d'imposition 2025", "impôt", True),
]


class DayBriefingService:
    """Briefing du jour : priorités, agenda et projection de score (mock)."""

    def __init__(
        self,
        serenity_service: SerenityService | None = None,
        calendar_service: CalendarService | None = None,
    ):
        self._serenity = serenity_service or SerenityService()
        self._calendar = calendar_service or self._serenity._calendar

    async def get_day_briefing(self, token: TokenPayload | None = None) -> DayBriefingResponse:
        briefing = await self._serenity.get_briefing(token=token)
        first_name = self._serenity._resolve_first_name(token)
        now = datetime.now()
        today = now.date()

        urgent_payments = self._urgent_payments(today)
        appointments = self._todays_appointments(today)
        new_documents = self._new_documents()
        priorities = self._priorities_from_actions(briefing.actions)
        projected = self._project_score(briefing)
        value_message = self._value_message(urgent_payments)
        summary = self._narrative(
            first_name=first_name,
            current_score=briefing.score,
            projected_score=projected,
            priorities=priorities,
            urgent_payments=urgent_payments,
            appointments=appointments,
            new_documents=new_documents,
        )

        return DayBriefingResponse(
            greeting=f"Bonjour {first_name}.",
            summary=summary,
            priorities=priorities,
            urgent_payments=urgent_payments,
            todays_appointments=appointments,
            new_documents=new_documents,
            current_score=briefing.score,
            projected_score=projected,
            value_message=value_message,
            generated_at=now,
        )

    def _urgent_payments(self, today: date) -> list[DayUrgentPaymentDTO]:
        items: list[DayUrgentPaymentDTO] = []
        for pay_id, creditor, amount, days_until in _MOCK_URGENT_PAYMENTS:
            items.append(
                DayUrgentPaymentDTO(
                    id=pay_id,
                    creditor=creditor,
                    amount=amount,
                    due_date=today + timedelta(days=days_until),
                    days_until_due=days_until,
                )
            )
        return sorted(items, key=lambda p: p.days_until_due)

    def _todays_appointments(self, today: date) -> list[DayAppointmentDTO]:
        appointments: list[DayAppointmentDTO] = []
        for event in self._calendar._events:
            if event.start.date() != today:
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

    def _new_documents(self) -> list[DayDocumentDTO]:
        return [
            DayDocumentDTO(
                id=doc_id,
                title=title,
                document_type=doc_type,
                is_important=important,
            )
            for doc_id, title, doc_type, important in _MOCK_NEW_DOCUMENTS
        ]

    def _priorities_from_actions(self, actions: list[SerenityActionDTO]) -> list[DayPriorityDTO]:
        priorities: list[DayPriorityDTO] = []
        for action in actions[:3]:
            priorities.append(
                DayPriorityDTO(
                    id=action.id,
                    label=action.label,
                    description=action.description,
                    route=action.route,
                    domain=self._domain_for_route(action.route),
                    priority=action.priority,
                )
            )
        return priorities

    def _domain_for_route(self, route: str) -> SerenityDomain:
        if route.startswith("/messaging"):
            return SerenityDomain.MESSAGING
        if route.startswith("/calendar") or route.startswith("/access-control"):
            return SerenityDomain.CALENDAR
        if route.startswith("/payments"):
            return SerenityDomain.PAYMENTS
        if route.startswith("/documents"):
            return SerenityDomain.DOCUMENTS
        return SerenityDomain.NOTIFICATIONS

    def _project_score(self, briefing: SerenityBriefingResponse) -> int:
        """Projection si courriers traités et échéances proches réglées."""
        projected = briefing.score
        for factor in briefing.factors:
            if factor.domain == SerenityDomain.MESSAGING:
                projected += factor.impact
            elif factor.label == "Échéance proche":
                projected += factor.impact
            elif factor.label == "Paiements en attente":
                # Une facture urgente résolue (~3 pts du facteur pending).
                projected += min(3, factor.impact)
        return max(0, min(100, projected))

    def _value_message(self, payments: list[DayUrgentPaymentDTO]) -> str | None:
        if not payments:
            return None
        soonest = payments[0]
        # Heuristique démo : pénalité évitée si règlement autour de l'échéance.
        if soonest.days_until_due <= 2:
            avoided = max(2.0, min(25.0, round(soonest.amount * 0.03, 2)))
        else:
            avoided = max(1.0, min(15.0, round(soonest.amount * 0.02, 2)))
        euros = f"{avoided:.0f}" if avoided == int(avoided) else f"{avoided:.2f}".replace(".", ",")
        return (
            f"En réglant {soonest.creditor} à temps, vous évitez environ {euros} € de pénalités."
        )

    def _narrative(
        self,
        *,
        first_name: str,
        current_score: int,
        projected_score: int,
        priorities: list[DayPriorityDTO],
        urgent_payments: list[DayUrgentPaymentDTO],
        appointments: list[DayAppointmentDTO],
        new_documents: list[DayDocumentDTO],
    ) -> str:
        parts = [
            f"{first_name}, voici le point de départ de votre journée.",
            f"Indice de sérénité actuel : {current_score}/100.",
        ]
        if projected_score > current_score:
            parts.append(
                f"En traitant les priorités du jour, vous pouvez viser {projected_score}/100."
            )
        if priorities:
            labels = ", ".join(p.label.lower() for p in priorities)
            parts.append(f"Priorités suggérées : {labels}.")
        if urgent_payments:
            creditors = ", ".join(p.creditor for p in urgent_payments)
            parts.append(f"Paiement(s) à surveiller : {creditors}.")
        if appointments:
            parts.append(f"{len(appointments)} rendez-vous ou réunion(s) inscrit(s) aujourd'hui.")
        else:
            parts.append("Aucun rendez-vous prévu aujourd'hui.")
        if new_documents:
            important = sum(1 for d in new_documents if d.is_important)
            if important:
                parts.append(f"{important} document(s) important(s) à consulter.")
            else:
                parts.append(f"{len(new_documents)} nouveau(x) document(s) disponible(s).")
        return " ".join(parts)
