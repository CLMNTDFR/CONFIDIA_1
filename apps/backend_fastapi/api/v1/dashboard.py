from fastapi import APIRouter, Depends, Query

from application.dto.dashboard_dto import WeekCalendarScope, WeekOverviewResponse
from application.dto.serenity_dto import DayBriefingResponse, SerenityBriefingResponse
from application.services.dashboard_service import DashboardService
from application.services.day_briefing_service import DayBriefingService
from application.services.serenity_service import SerenityService
from core.security import TokenPayload, decode_token

router = APIRouter()
_dashboard_service = DashboardService()
_serenity_service = SerenityService()
_day_briefing_service = DayBriefingService(serenity_service=_serenity_service)


@router.get("/week-overview", response_model=WeekOverviewResponse)
async def week_overview(
    scopes: list[WeekCalendarScope] | None = Query(None),
    token: TokenPayload = Depends(decode_token),
):
    """Synthèse hebdomadaire : charge par jour, répartition réunions / échéances / tâches."""
    return await _dashboard_service.get_week_overview(scopes=scopes)


@router.get("/serenity-briefing", response_model=SerenityBriefingResponse)
async def serenity_briefing(token: TokenPayload = Depends(decode_token)):
    """Briefing IA de sérénité : score, facteurs de charge mentale et actions prioritaires."""
    return await _serenity_service.get_briefing(token=token)


@router.get("/day-briefing", response_model=DayBriefingResponse)
async def day_briefing(token: TokenPayload = Depends(decode_token)):
    """Briefing « démarrer la journée » : priorités, agenda, projection de sérénité."""
    return await _day_briefing_service.get_day_briefing(token=token)
