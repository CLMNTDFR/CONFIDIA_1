from pydantic import BaseModel, Field


class UserProfileDTO(BaseModel):
    id: str
    email: str
    first_name: str
    last_name: str
    roles: list[str] = Field(default_factory=list)
    avatar_url: str | None = None
    phone: str | None = None
    organization: str | None = None
    locale: str = "fr-FR"
    timezone: str = "Europe/Paris"


class UserProfileUpdateDTO(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    phone: str | None = None
    organization: str | None = None
    locale: str | None = None
    timezone: str | None = None


class UserListResponse(BaseModel):
    items: list[UserProfileDTO]
    total: int
