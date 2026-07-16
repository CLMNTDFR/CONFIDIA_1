from fastapi import APIRouter, Depends, Query

from application.dto.dashboard_dto import WeekCalendarScope, WeekOverviewResponse
from application.dto.serenity_dto import SerenityBriefingResponse
from application.services.dashboard_service import DashboardService
from application.services.serenity_service import SerenityService
from core.security import TokenPayload, decode_token

router = APIRouter()
_dashboard_service = DashboardService()
_serenity_service = SerenityService()


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
