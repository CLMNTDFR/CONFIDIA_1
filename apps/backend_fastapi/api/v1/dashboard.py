from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, Query

from application.dto.dashboard_dto import WeekCalendarScope, WeekOverviewResponse
from application.services.dashboard_service import DashboardService
from core.security import TokenPayload, decode_token

router = APIRouter()
_dashboard_service = DashboardService()


@router.get("/week-overview", response_model=WeekOverviewResponse)
async def week_overview(
    scopes: list[WeekCalendarScope] | None = Query(None),
    token: TokenPayload = Depends(decode_token),
):
    """Synthèse hebdomadaire : charge par jour, répartition réunions / échéances / tâches."""
    return await _dashboard_service.get_week_overview(scopes=scopes)
