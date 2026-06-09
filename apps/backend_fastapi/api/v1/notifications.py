from fastapi import APIRouter, Depends, HTTPException, Query, status

from application.dto.notification_dto import NotificationDTO, NotificationListResponse
from application.services.notification_service import NotificationService
from core.security import TokenPayload, decode_token

router = APIRouter()
_notification_service = NotificationService()


@router.get("/", response_model=NotificationListResponse)
async def list_notifications(
    unread_only: bool = Query(False),
    token: TokenPayload = Depends(decode_token),
):
    return await _notification_service.list_notifications(unread_only)


@router.patch("/{notification_id}/read", response_model=NotificationDTO)
async def mark_as_read(
    notification_id: str,
    token: TokenPayload = Depends(decode_token),
):
    notif = await _notification_service.mark_as_read(notification_id)
    if not notif:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    return notif


@router.post("/read-all")
async def mark_all_as_read(token: TokenPayload = Depends(decode_token)):
    count = await _notification_service.mark_all_as_read()
    return {"marked_read": count}
