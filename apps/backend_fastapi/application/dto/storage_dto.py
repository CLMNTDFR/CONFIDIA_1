from datetime import datetime

from pydantic import BaseModel


class FileInfoDTO(BaseModel):
    path: str
    name: str
    size: int
    content_type: str | None = None
    modified: datetime | None = None
    is_directory: bool = False


class ShareLinkDTO(BaseModel):
    url: str
    token: str
    expires_at: datetime | None = None
