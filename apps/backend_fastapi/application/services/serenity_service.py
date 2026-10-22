from datetime import UTC, date, timedelta

from application.dto.calendar_dto import CalendarEventDTO, EventType
from application.dto.serenity_dto import (
    SerenityActionDTO,
    SerenityBriefingResponse,
    SerenityDomain,
    SerenityFactorDTO,
    SerenityLevel,
    SerenityMetricDTO,
    SerenityScorePointDTO,
)
from application.services.identity_service import names_from_claims
from core.security import TokenPayload
from core.time import as_utc, civil_date, civil_now


def first_name_from_token(token: TokenPayload | None) -> str:
    if token is None:
        return ""
    given, _ = names_from_claims(token.raw)
    if given:
        return given
    local = (token.email or "").split("@")[0].strip()
    return local.capitalize() if local else ""


def greet(first_name: str) -> str:
    return f"Bonjour {first_name}." if first_name else "Bonjour."


class SerenityService:
    """Serenity briefing from real workspace events."""

    async def get_briefing(
        self,
        token: TokenPayload | None = None,
        events: list[CalendarEventDTO] | None = None,
        zone: str | None = None,
    ) -> SerenityBriefingResponse:
        first_name = first_name_from_token(token)
        now = civil_now(zone)
        now_utc = now.astimezone(UTC)
        horizon_end = now_utc + timedelta(days=30)
        items = events or []
        upcoming = [e for e in items if now_utc <= as_utc(e.start) <= horizon_end]
        horizon_day = civil_date(horizon_end, zone)
        busy_days = self._count_busy_days(upcoming, now.date(), horizon_day, zone)
        deadlines_7d = sum(
            1
            for e in upcoming
            if e.event_type == EventType.DEADLINE and as_utc(e.start) <= now_utc + timedelta(days=7)
        )

        factors: list[SerenityFactorDTO] = []
        score = 100
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
        score = max(0, min(100, score))
        level = self._resolve_level(score)
        calendar_label = self._calendar_load_label(busy_days)
        metrics = [
            SerenityMetricDTO(
                key="unprocessed_emails",
                label="Courriers non traités",
                value=0,
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
                value=0,
                domain=SerenityDomain.PAYMENTS,
            ),
            SerenityMetricDTO(
                key="unread_notifications",
                label="Alertes non lues",
                value=0,
                domain=SerenityDomain.NOTIFICATIONS,
            ),
        ]
        actions = self._build_actions(factors)
        return SerenityBriefingResponse(
            score=score,
            level=level,
            greeting=greet(first_name),
            headline=self._serenity_headline(level, score),
            summary=self._summary(first_name, score, level, calendar_label),
            metrics=metrics,
            factors=sorted(factors, key=lambda f: f.impact, reverse=True),
            actions=actions,
            score_history=[SerenityScorePointDTO(date=now.date(), score=score)],
            generated_at=now,
        )

    def _count_busy_days(self, events, start: date, end: date, zone: str | None) -> int:
        by_day: dict[date, int] = {}
        for event in events:
            day = civil_date(event.start, zone)
            if start <= day <= end:
                weight = 2 if event.event_type in (EventType.MEETING, EventType.DEADLINE) else 1
                by_day[day] = by_day.get(day, 0) + weight
        return sum(1 for score in by_day.values() if score >= 4)

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

    def _serenity_headline(self, level: SerenityLevel, score: int) -> str:
        base = {
            SerenityLevel.EXCELLENT: "Excellente sérénité administrative",
            SerenityLevel.GOOD: "Bonne sérénité administrative",
            SerenityLevel.MODERATE: "Sérénité modérée",
            SerenityLevel.ATTENTION: "Sérénité fragile",
        }[level]
        return f"{base} ({score}/100)"

    def _summary(
        self,
        first_name: str,
        score: int,
        level: SerenityLevel,
        calendar_label: str,
    ) -> str:
        level_labels = {
            SerenityLevel.EXCELLENT: "excellente",
            SerenityLevel.GOOD: "bonne",
            SerenityLevel.MODERATE: "modérée",
            SerenityLevel.ATTENTION: "fragile",
        }
        prefix = f"{first_name}, votre" if first_name else "Votre"
        return (
            f"{prefix} indice de sérénité est {score}/100 "
            f"({level_labels[level]}). Votre {calendar_label} sur les 30 prochains jours."
        )

    def _build_actions(self, factors: list[SerenityFactorDTO]) -> list[SerenityActionDTO]:
        actions: list[SerenityActionDTO] = []
        domains = {f.domain for f in factors}
        if SerenityDomain.CALENDAR in domains:
            actions.append(
                SerenityActionDTO(
                    id="analyze-planning",
                    label="Analyser le planning",
                    description="Alléger les journées les plus denses",
                    route="/calendar",
                    icon="calendar_month",
                    priority=80,
                )
            )
        actions.append(
            SerenityActionDTO(
                id="import-document",
                label="Importer un document",
                description="Ajoutez une pièce pour construire votre espace",
                route="/documents",
                icon="folder",
                priority=50,
            )
        )
        return sorted(actions, key=lambda a: a.priority, reverse=True)
