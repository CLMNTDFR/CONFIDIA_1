from datetime import datetime

from pydantic import BaseModel, Field


class DocumentDTO(BaseModel):
    id: int
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


class DocumentCreateDTO(BaseModel):
    title: str | None = None
    correspondent: str | None = None
    document_type: str | None = None
    tags: list[str] = Field(default_factory=list)
    category: str | None = None


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
