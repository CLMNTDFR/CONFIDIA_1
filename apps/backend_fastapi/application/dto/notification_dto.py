from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class NotificationType(str, Enum):
    INFO = "info"
    WARNING = "warning"
    SUCCESS = "success"
    ERROR = "error"
    DOCUMENT = "document"
    CALENDAR = "calendar"
    SYSTEM = "system"


class NotificationDTO(BaseModel):
    id: str
    title: str
    message: str
    notification_type: NotificationType = NotificationType.INFO
    read: bool = False
    created_at: datetime
    action_url: str | None = None
    metadata: dict = Field(default_factory=dict)


class NotificationListResponse(BaseModel):
    items: list[NotificationDTO]
    total: int
    unread_count: int
