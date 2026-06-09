from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status

from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventListResponse,
)
from application.services.calendar_service import CalendarService
from core.security import TokenPayload, decode_token

router = APIRouter()
_calendar_service = CalendarService()


@router.get("/events", response_model=CalendarEventListResponse)
async def list_events(
    start: datetime | None = Query(None),
    end: datetime | None = Query(None),
    token: TokenPayload = Depends(decode_token),
):
    return await _calendar_service.list_events(start, end)


@router.get("/events/{event_id}", response_model=CalendarEventDTO)
async def get_event(
    event_id: str,
    token: TokenPayload = Depends(decode_token),
):
    event = await _calendar_service.get_event(event_id)
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found")
    return event


@router.post("/events", response_model=CalendarEventDTO, status_code=status.HTTP_201_CREATED)
async def create_event(
    data: CalendarEventCreateDTO,
    token: TokenPayload = Depends(decode_token),
):
    return await _calendar_service.create_event(data)
