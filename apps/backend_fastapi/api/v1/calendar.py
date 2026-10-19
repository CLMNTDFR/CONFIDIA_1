from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from api.deps import get_calendar_service, get_identity_service
from application.dto.calendar_dto import (
    CalendarEventCreateDTO,
    CalendarEventDTO,
    CalendarEventListResponse,
    CalendarEventUpdateDTO,
)
from application.services.calendar_service import CalendarService
from application.services.identity_service import IdentityService
from core.security import TokenPayload, decode_token

router = APIRouter()


async def _workspace(
    token: TokenPayload,
    identity: IdentityService,
) -> tuple[UUID, str]:
    stored = await identity.ensure_from_token_claims(token.raw)
    if stored.organization_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun espace de travail n'est associé à ce compte",
        )
    return stored.organization_id, stored.id


def _parse_event_id(event_id: str) -> UUID:
    try:
        return UUID(event_id)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        ) from exc


@router.get("/events", response_model=CalendarEventListResponse)
async def list_events(
    start: datetime | None = Query(None),
    end: datetime | None = Query(None),
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    organization_id, _ = await _workspace(token, identity)
    try:
        return await calendar.list_events(organization_id, start, end)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.get("/events/{event_id}", response_model=CalendarEventDTO)
async def get_event(
    event_id: str,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    organization_id, _ = await _workspace(token, identity)
    event = await calendar.get_event(organization_id, _parse_event_id(event_id))
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found")
    return event


@router.post("/events", response_model=CalendarEventDTO, status_code=status.HTTP_201_CREATED)
async def create_event(
    data: CalendarEventCreateDTO,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    organization_id, owner_id = await _workspace(token, identity)
    try:
        return await calendar.create_event(organization_id, owner_id, data)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc


@router.patch("/events/{event_id}", response_model=CalendarEventDTO)
async def update_event(
    event_id: str,
    data: CalendarEventUpdateDTO,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    organization_id, _ = await _workspace(token, identity)
    try:
        event = await calendar.update_event(
            organization_id, _parse_event_id(event_id), data
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found")
    return event


@router.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_event(
    event_id: str,
    token: TokenPayload = Depends(decode_token),
    identity: IdentityService = Depends(get_identity_service),
    calendar: CalendarService = Depends(get_calendar_service),
):
    organization_id, _ = await _workspace(token, identity)
    deleted = await calendar.delete_event(organization_id, _parse_event_id(event_id))
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found")
