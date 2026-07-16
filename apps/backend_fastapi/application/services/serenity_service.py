from datetime import date, datetime, timedelta

from application.dto.calendar_dto import EventType
from application.dto.serenity_dto import (
    SerenityActionDTO,
    SerenityBriefingResponse,
    SerenityDomain,
    SerenityFactorDTO,
    SerenityLevel,
    SerenityMetricDTO,
    SerenityScorePointDTO,
)
from application.services.calendar_service import CalendarService
from application.services.notification_service import NotificationService
from core.security import TokenPayload

# Mock aligné sur l'écosystème Flutter (en attendant services messagerie / paiements).
_MOCK_UNPROCESSED_EMAILS = 6
_MOCK_UNREAD_EMAILS = 3
_MOCK_PENDING_PAYMENTS = 4
_MOCK_PAYMENT_DUE_SOON_DAYS = 5
_MOCK_PAYMENT_DUE_SOON_CREDITOR = "EDF"


class SerenityService:
    """Briefing de sérénité : agrège charge mentale administrative cross-modules."""

    def __init__(
        self,
        calendar_service: CalendarService | None = None,
        notification_service: NotificationService | None = None,
    ):
        self._calendar = calendar_service or CalendarService()
        self._notifications = notification_service or NotificationService()

    async def get_briefing(self, token: TokenPayload | None = None) -> SerenityBriefingResponse:
        first_name = self._resolve_first_name(token)
        now = datetime.now()
        horizon_end = now + timedelta(days=30)

        events = [e for e in self._calendar._events if now <= e.start <= horizon_end]
        busy_days = self._count_busy_days(events, now.date(), horizon_end.date())
        deadlines_7d = sum(
            1
            for e in events
            if e.event_type == EventType.DEADLINE and e.start <= now + timedelta(days=7)
        )
        unread_notifications = len([n for n in self._notifications._notifications if not n.read])

        factors: list[SerenityFactorDTO] = []
        score = 100

        if _MOCK_UNPROCESSED_EMAILS > 0:
            impact = min(18, _MOCK_UNPROCESSED_EMAILS * 3)
            score -= impact
            factors.append(
                SerenityFactorDTO(
                    domain=SerenityDomain.MESSAGING,
                    label="Courriers non traités",
                    detail=f"{_MOCK_UNPROCESSED_EMAILS} e-mails en attente de traitement ou de classement",
                    impact=impact,
                    severity="high" if _MOCK_UNPROCESSED_EMAILS >= 5 else "medium",
                )
            )

        if busy_days > 0:
            impact = min(16, busy_days * 4)
            score -= impact
            factors.append(
                SerenityFactorDTO(
                    domain=SerenityDomain.CALENDAR,
                    label="Jours chargés à venir",
                    detail=f"{busy_days} journée(s) dense(s) prévue(s) sur les 30 prochains jours",
                    impact=impact,
                    severity="high" if busy_days >= 4 else "medium",
                )
            )

        if _MOCK_PENDING_PAYMENTS > 0:
            impact = min(14, _MOCK_PENDING_PAYMENTS * 3)
            score -= impact
            factors.append(
                SerenityFactorDTO(
                    domain=SerenityDomain.PAYMENTS,
                    label="Paiements en attente",
                    detail=f"{_MOCK_PENDING_PAYMENTS} facture(s) à régler",
                    impact=impact,
                    severity="medium",
                )
            )

        if _MOCK_PAYMENT_DUE_SOON_DAYS <= 7:
            impact = 4
            score -= impact
            factors.append(
                SerenityFactorDTO(
                    domain=SerenityDomain.PAYMENTS,
                    label="Échéance proche",
                    detail=f"Facture {_MOCK_PAYMENT_DUE_SOON_CREDITOR} dans {_MOCK_PAYMENT_DUE_SOON_DAYS} jours",
                    impact=impact,
                    severity="medium",
                )
            )

        if deadlines_7d > 0:
            impact = min(10, deadlines_7d * 3)
            score -= impact
            factors.append(
                SerenityFactorDTO(
                    domain=SerenityDomain.CALENDAR,
                    label="Échéances imminentes",
                    detail=f"{deadlines_7d} échéance(s) dans les 7 prochains jours",
                    impact=impact,
                    severity="high" if deadlines_7d >= 2 else "medium",
                )
            )

        if unread_notifications > 0:
            impact = min(6, unread_notifications * 2)
            score -= impact
            factors.append(
                SerenityFactorDTO(
                    domain=SerenityDomain.NOTIFICATIONS,
                    label="Alertes non lues",
                    detail=f"{unread_notifications} notification(s) en attente de lecture",
                    impact=impact,
                    severity="low",
                )
            )

        score = max(0, min(100, score))
        level = self._resolve_level(score)
        calendar_label = self._calendar_load_label(busy_days)
        priority_today = min(3, _MOCK_UNPROCESSED_EMAILS) if _MOCK_UNPROCESSED_EMAILS else 0

        headline = self._serenity_headline(level, score, priority_today)
        summary = self._summary(
            first_name=first_name,
            score=score,
            level=level,
            calendar_label=calendar_label,
            priority_today=priority_today,
            payment_days=_MOCK_PAYMENT_DUE_SOON_DAYS,
            creditor=_MOCK_PAYMENT_DUE_SOON_CREDITOR,
        )

        metrics = [
            SerenityMetricDTO(
                key="unprocessed_emails",
                label="Courriers non traités",
                value=_MOCK_UNPROCESSED_EMAILS,
                domain=SerenityDomain.MESSAGING,
            ),
            SerenityMetricDTO(
                key="busy_days_30d",
                label="Jours chargés (30 j)",
                value=busy_days,
                domain=SerenityDomain.CALENDAR,
            ),
            SerenityMetricDTO(
                key="pending_payments",
                label="Paiements en attente",
                value=_MOCK_PENDING_PAYMENTS,
                domain=SerenityDomain.PAYMENTS,
            ),
            SerenityMetricDTO(
                key="unread_notifications",
                label="Alertes non lues",
                value=unread_notifications,
                domain=SerenityDomain.NOTIFICATIONS,
            ),
        ]

        actions = self._build_actions(factors)
        score_history = self._build_score_history(score, now)

        return SerenityBriefingResponse(
            score=score,
            level=level,
            greeting=f"Bonjour {first_name}.",
            headline=headline,
            summary=summary,
            metrics=metrics,
            factors=sorted(factors, key=lambda f: f.impact, reverse=True),
            actions=actions,
            score_history=score_history,
            generated_at=now,
        )

    def _resolve_first_name(self, token: TokenPayload | None) -> str:
        if token and token.email:
            local = token.email.split("@")[0]
            return local.capitalize() if local else "Amandine"
        return "Amandine"

    def _count_busy_days(self, events, start: date, end: date) -> int:
        by_day: dict[date, int] = {}
        for event in events:
            day = event.start.date()
            if start <= day <= end:
                weight = 2 if event.event_type in (EventType.MEETING, EventType.DEADLINE) else 1
                by_day[day] = by_day.get(day, 0) + weight
        return sum(1 for score in by_day.values() if score >= 4)

    def _build_score_history(self, current_score: int, now: datetime) -> list[SerenityScorePointDTO]:
        today = now.date()
        template = [34, 28, 31, 39, 36, 44, 41, 50, 47, 56, 53, 61, 58]
        points: list[SerenityScorePointDTO] = []
        for i, value in enumerate(template):
            points.append(SerenityScorePointDTO(date=today - timedelta(days=len(template) - i), score=value))
        points.append(SerenityScorePointDTO(date=today, score=current_score))
        return points

    def _resolve_level(self, score: int) -> SerenityLevel:
        if score >= 80:
            return SerenityLevel.EXCELLENT
        if score >= 65:
            return SerenityLevel.GOOD
        if score >= 50:
            return SerenityLevel.MODERATE
        return SerenityLevel.ATTENTION

    def _calendar_load_label(self, busy_days: int) -> str:
        if busy_days >= 4:
            return "agenda chargé"
        if busy_days >= 2:
            return "agenda modérément chargé"
        return "agenda plutôt calme"

    def _serenity_headline(self, level: SerenityLevel, score: int, priority_today: int) -> str:
        base = {
            SerenityLevel.EXCELLENT: "Excellente sérénité administrative",
            SerenityLevel.GOOD: "Bonne sérénité administrative",
            SerenityLevel.MODERATE: "Sérénité modérée",
            SerenityLevel.ATTENTION: "Sérénité fragile",
        }[level]
        suffix = f" · {priority_today} action(s) prioritaire(s)" if priority_today > 0 else ""
        return f"{base} ({score}/100){suffix}"

    def _summary(
        self,
        *,
        first_name: str,
        score: int,
        level: SerenityLevel,
        calendar_label: str,
        priority_today: int,
        payment_days: int,
        creditor: str,
    ) -> str:
        level_labels = {
            SerenityLevel.EXCELLENT: "excellente",
            SerenityLevel.GOOD: "bonne",
            SerenityLevel.MODERATE: "modérée",
            SerenityLevel.ATTENTION: "fragile",
        }
        parts = [
            f"{first_name}, votre indice de sérénité est {score}/100 ({level_labels[level]}).",
            f"Votre {calendar_label} sur les 30 prochains jours.",
        ]
        if payment_days <= 7:
            parts.append(f"Une facture {creditor} arrive à échéance dans {payment_days} jours.")
        if priority_today > 0:
            parts.append(f"{priority_today} courrier(s) mérite(nt) votre attention aujourd'hui.")
        return " ".join(parts)

    def _build_actions(self, factors: list[SerenityFactorDTO]) -> list[SerenityActionDTO]:
        actions: list[SerenityActionDTO] = []
        domains = {f.domain for f in factors}

        if SerenityDomain.MESSAGING in domains:
            actions.append(
                SerenityActionDTO(
                    id="triage-mails",
                    label="Traiter les courriers",
                    description="Cofid-IA classe et propose des actions sur vos e-mails en attente",
                    route="/messaging",
                    icon="mail",
                    ai_powered=True,
                    priority=90,
                )
            )

        if SerenityDomain.CALENDAR in domains:
            actions.append(
                SerenityActionDTO(
                    id="analyze-planning",
                    label="Analyser le planning",
                    description="Détecter les conflits et alléger les journées les plus denses",
                    route="/calendar",
                    icon="calendar_month",
                    ai_powered=True,
                    priority=80,
                )
            )
            actions.append(
                SerenityActionDTO(
                    id="conflict-resolution",
                    label="Résoudre les conflits",
                    description="Vue gouvernance : arbitrage des rôles et des disponibilités",
                    route="/access-control",
                    icon="account_tree",
                    ai_powered=True,
                    priority=70,
                )
            )

        if SerenityDomain.PAYMENTS in domains:
            actions.append(
                SerenityActionDTO(
                    id="settle-payments",
                    label="Régler les factures",
                    description="Visualiser et traiter les paiements en attente",
                    route="/payments",
                    icon="payment",
                    priority=85,
                )
            )

        if SerenityDomain.DOCUMENTS in domains or SerenityDomain.NOTIFICATIONS in domains:
            actions.append(
                SerenityActionDTO(
                    id="review-documents",
                    label="Consulter les documents",
                    description="Retrouver les pièces liées à vos alertes",
                    route="/documents",
                    icon="folder",
                    priority=60,
                )
            )

        return sorted(actions, key=lambda a: a.priority, reverse=True)
