from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class DocumentDTO(BaseModel):
    id: str
    title: str
    content: str | None = None
    created: datetime
    modified: datetime
    correspondent: str | None = None
    document_type: str | None = None
    tags: list[str] = Field(default_factory=list)
    category: str | None = None
    mime_type: str | None = None
    file_size: int | None = None
    is_important: bool = False
    deleted_at: datetime | None = None


class DocumentCreateDTO(BaseModel):
    title: str | None = None
    correspondent: str | None = None
    document_type: str | None = None
    tags: list[str] = Field(default_factory=list)
    category: str | None = None


class DocumentUpdateDTO(BaseModel):
    title: str | None = None
    correspondent: str | None = None
    document_type: str | None = None
    category: str | None = None
    is_important: bool | None = None


class DocumentSearchDTO(BaseModel):
    query: str | None = None
    tags: list[str] = Field(default_factory=list)
    category: str | None = None
    correspondent: str | None = None
    date_from: datetime | None = None
    date_to: datetime | None = None


class DocumentListResponse(BaseModel):
    items: list[DocumentDTO]
    total: int
    page: int
    page_size: int


class DocumentEventLink(BaseModel):
    event_id: str
    title: str
    start: datetime
    deleted: bool = False


class DocumentPurgeDecision(BaseModel):
    event_id: UUID
    action: Literal["keep", "delete"]


class DocumentPurgeRequest(BaseModel):
    decisions: list[DocumentPurgeDecision] = Field(default_factory=list)
