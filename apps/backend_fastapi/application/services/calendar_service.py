from datetime import datetime, timedelta

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventListResponse,
    CalendarEventUpdateDTO,
    EventType,
    WeekCalendarScope,
)


class CalendarService:
    """Calendar service with mock data. Ready for future CalDAV/sync integration."""

    def __init__(self):
        self._events = self._generate_mock_events()

    def _week_day(self, weekday: int, hour: int = 9, minute: int = 0) -> datetime:
        """weekday: 0 = lundi, 6 = dimanche."""
        now = datetime.now()
        monday = now - timedelta(days=now.weekday())
        return monday.replace(hour=hour, minute=minute, second=0, microsecond=0) + timedelta(days=weekday)

    def _generate_mock_events(self) -> list[CalendarEventDTO]:
        now = datetime.now()
        week = self._week_events()
        legacy = [
            CalendarEventDTO(
                id="evt-001",
                title="Échéance assurance habitation",
                description="Renouvellement contrat AXA",
                start=now + timedelta(days=3),
                end=now + timedelta(days=3, hours=1),
                event_type=EventType.DEADLINE,
                color="#d20050",
                document_id=1,
                calendar_scope=WeekCalendarScope.FAMILY,
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
                calendar_scope=WeekCalendarScope.PERSONAL,
            ),
            CalendarEventDTO(
                id="evt-003",
                title="Réunion budget familial",
                description="Revue des dépenses mensuelles",
                start=now + timedelta(days=14, hours=19),
                end=now + timedelta(days=14, hours=20, minutes=30),
                event_type=EventType.MEETING,
                color="#af73f7",
                calendar_scope=WeekCalendarScope.FAMILY,
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
                calendar_scope=WeekCalendarScope.FAMILY,
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
                calendar_scope=WeekCalendarScope.PERSONAL,
            ),
        ]
        return week + legacy

    def _week_events(self) -> list[CalendarEventDTO]:
        """Semaine courante — données alignées sur le widget tableau de bord."""
        specs: list[tuple[int, EventType, WeekCalendarScope, str, int]] = [
            # Lundi — chargée (8)
            (0, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Stand-up équipe", 9),
            (0, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Revue client", 10),
            (0, EventType.DEADLINE, WeekCalendarScope.FAMILY, "Paiement loyer", 11),
            (0, EventType.APPOINTMENT, WeekCalendarScope.PERSONAL, "Médecin", 14),
            (0, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Point projet", 15),
            (0, EventType.REMINDER, WeekCalendarScope.PERSONAL, "Renouvellement CNI", 16),
            (0, EventType.DEADLINE, WeekCalendarScope.FAMILY, "Facture EDF", 17),
            (0, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Comité direction", 18),
            # Mardi — moyenne (4)
            (1, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Réunion fournisseur", 10),
            (1, EventType.DEADLINE, WeekCalendarScope.FAMILY, "Cotisation MAIF", 11),
            (1, EventType.APPOINTMENT, WeekCalendarScope.PERSONAL, "Dentiste", 15),
            (1, EventType.REMINDER, WeekCalendarScope.PERSONAL, "Relance assurance", 17),
            # Mercredi — chargée (9)
            (2, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Sprint planning", 9),
            (2, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Atelier UX", 10),
            (2, EventType.DEADLINE, WeekCalendarScope.FAMILY, "Déclaration CAF", 11),
            (2, EventType.APPOINTMENT, WeekCalendarScope.PERSONAL, "Notaire", 13),
            (2, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Revue CONFIDIA", 14),
            (2, EventType.DEADLINE, WeekCalendarScope.FAMILY, "Taxe foncière", 15),
            (2, EventType.REMINDER, WeekCalendarScope.PERSONAL, "Passeport", 16),
            (2, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Call investisseur", 17),
            (2, EventType.APPOINTMENT, WeekCalendarScope.PERSONAL, "Coiffeur", 18),
            # Jeudi — calme (2)
            (3, EventType.APPOINTMENT, WeekCalendarScope.PERSONAL, "Courses", 11),
            (3, EventType.REMINDER, WeekCalendarScope.FAMILY, "Anniversaire", 18),
            # Vendredi — moyenne (6)
            (4, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Bilan hebdo", 9),
            (4, EventType.DEADLINE, WeekCalendarScope.FAMILY, "Paiement internet", 10),
            (4, EventType.MEETING, WeekCalendarScope.PROFESSIONAL, "Point RH", 11),
            (4, EventType.APPOINTMENT, WeekCalendarScope.PERSONAL, "Sport", 17),
            (4, EventType.REMINDER, WeekCalendarScope.PERSONAL, "Contrat Orange", 18),
            (4, EventType.MEETING, WeekCalendarScope.FAMILY, "Réunion parents", 19),
            # Samedi — calme (1)
            (5, EventType.APPOINTMENT, WeekCalendarScope.FAMILY, "Marché", 10),
            # Dimanche — calme (0)
        ]

        events: list[CalendarEventDTO] = []
        for index, (day, event_type, scope, title, hour) in enumerate(specs):
            start = self._week_day(day, hour=hour)
            events.append(
                CalendarEventDTO(
                    id=f"evt-week-{index:03d}",
                    title=title,
                    start=start,
                    end=start + timedelta(hours=1),
                    event_type=event_type,
                    calendar_scope=scope,
                )
            )
        return events

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

    async def update_event(self, event_id: str, data: CalendarEventUpdateDTO) -> CalendarEventDTO | None:
        for i, event in enumerate(self._events):
            if event.id != event_id:
                continue
            updated = event.model_copy(update=data.model_dump(exclude_unset=True))
            self._events[i] = updated
            return updated
        return None

    async def delete_event(self, event_id: str) -> bool:
        before = len(self._events)
        self._events = [e for e in self._events if e.id != event_id]
        return len(self._events) < before
