from datetime import datetime, timedelta

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventListResponse,
    EventType,
)


class CalendarService:
    """Calendar service with mock data. Ready for future CalDAV/sync integration."""

    def __init__(self):
        self._events = self._generate_mock_events()

    def _generate_mock_events(self) -> list[CalendarEventDTO]:
        now = datetime.now()
        return [
            CalendarEventDTO(
                id="evt-001",
                title="Échéance assurance habitation",
                description="Renouvellement contrat AXA",
                start=now + timedelta(days=3),
                end=now + timedelta(days=3, hours=1),
                event_type=EventType.DEADLINE,
                color="#d20050",
                document_id=1,
            ),
            CalendarEventDTO(
                id="evt-002",
                title="Rendez-vous médecin",
                description="Consultation annuelle",
                start=now + timedelta(days=7, hours=10),
                end=now + timedelta(days=7, hours=11),
                event_type=EventType.APPOINTMENT,
                location="Cabinet Dr. Lefebvre",
                color="#4b96b4",
            ),
            CalendarEventDTO(
                id="evt-003",
                title="Réunion budget familial",
                description="Revue des dépenses mensuelles",
                start=now + timedelta(days=14, hours=19),
                end=now + timedelta(days=14, hours=20, minutes=30),
                event_type=EventType.MEETING,
                color="#af73f7",
            ),
            CalendarEventDTO(
                id="evt-004",
                title="Paiement taxe foncière",
                description="Dernier délai de paiement",
                start=now + timedelta(days=21),
                end=now + timedelta(days=21, hours=23, minutes=59),
                event_type=EventType.DEADLINE,
                all_day=True,
                color="#d20050",
                document_id=3,
            ),
            CalendarEventDTO(
                id="evt-005",
                title="Rappel renouvellement passeport",
                description="Expiration dans 6 mois",
                start=now + timedelta(days=30),
                end=now + timedelta(days=30, hours=1),
                event_type=EventType.REMINDER,
                color="#af73f7",
                document_id=5,
            ),
        ]

    async def list_events(
        self,
        start: datetime | None = None,
        end: datetime | None = None,
    ) -> CalendarEventListResponse:
        events = self._events
        if start:
            events = [e for e in events if e.end >= start]
        if end:
            events = [e for e in events if e.start <= end]
        return CalendarEventListResponse(items=events, total=len(events))

    async def get_event(self, event_id: str) -> CalendarEventDTO | None:
        return next((e for e in self._events if e.id == event_id), None)

    async def create_event(self, data: CalendarEventCreateDTO) -> CalendarEventDTO:
        event = CalendarEventDTO(
            id=f"evt-{len(self._events) + 1:03d}",
            **data.model_dump(),
        )
        self._events.append(event)
        return event
