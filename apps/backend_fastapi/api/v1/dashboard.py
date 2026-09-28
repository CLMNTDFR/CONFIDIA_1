from fastapi import APIRouter, Depends, HTTPException, Query, status

from api.deps import get_calendar_service, get_identity_service
from application.dto.calendar_dto import CalendarEventDTO
from application.dto.dashboard_dto import WeekCalendarScope, WeekOverviewResponse
from application.dto.serenity_dto import DayBriefingResponse, SerenityBriefingResponse
from application.services.calendar_service import CalendarService
from application.services.dashboard_service import DashboardService
from application.services.day_briefing_service import DayBriefingService
from application.services.identity_service import IdentityService
from application.services.serenity_service import SerenityService
from core.security import TokenPayload, decode_token

router = APIRouter()
_dashboard_service = DashboardService()
_serenity_service = SerenityService()
_day_briefing_service = DayBriefingService(serenity_service=_serenity_service)


async def _workspace_events(
    token: TokenPayload,
    identity: IdentityService,
    calendar: CalendarService,
) -> list[CalendarEventDTO]:
    stored = await identity.ensure_from_token_claims(token.raw)
    if stored.organization_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun espace de travail n'est associé à ce compte",
        )
    listed = await calendar.list_events(stored.organization_id)
    return listed.items


@router.get("/week-overview", response_model=WeekOverviewResponse)
async def week_overview(
    scopes: list[WeekCalendarScope] | None = Query(None),
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    """Weekly overview: daily load, meetings, deadlines and tasks."""
    events = await _workspace_events(token, identity, calendar)
    return await _dashboard_service.get_week_overview(events, scopes=scopes)


@router.get("/serenity-briefing", response_model=SerenityBriefingResponse)
async def serenity_briefing(
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    """Serenity briefing: score, calendar load and next actions."""
    events = await _workspace_events(token, identity, calendar)
    return await _serenity_service.get_briefing(token=token, events=events)


@router.get("/day-briefing", response_model=DayBriefingResponse)
async def day_briefing(
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    """Day briefing: priorities and real agenda, no invented payments."""
    events = await _workspace_events(token, identity, calendar)
    return await _day_briefing_service.get_day_briefing(token=token, events=events)
