from pydantic import BaseModel, Field, field_validator


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

    @field_validator("first_name", "last_name")
    @classmethod
    def names_not_blank(cls, value: str | None) -> str | None:
        if value is None:
            return value
        stripped = value.strip()
        if not stripped:
            raise ValueError("Requis")
        return stripped

    @field_validator("phone")
    @classmethod
    def empty_phone_to_none(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None

    @field_validator("organization")
    @classmethod
    def organization_not_blank(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        if not stripped:
            raise ValueError("Le nom de l'espace est requis")
        return stripped

    @field_validator("locale")
    @classmethod
    def normalize_locale(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip().replace("_", "-")


class UserListResponse(BaseModel):
    items: list[UserProfileDTO]
    total: int
