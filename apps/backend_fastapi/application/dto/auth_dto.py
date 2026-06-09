from pydantic import BaseModel, Field


class TokenRequest(BaseModel):
    username: str
    password: str
    grant_type: str = "password"


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UserInfoResponse(BaseModel):
    sub: str
    email: str
    name: str | None = None
    given_name: str | None = None
    family_name: str | None = None
    roles: list[str] = Field(default_factory=list)
