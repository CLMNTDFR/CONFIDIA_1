from pydantic import BaseModel, Field, field_validator, model_validator

from application.services.password_policy import email_error, password_error, username_error


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


class RegisterRequest(BaseModel):
    email: str
    email_confirm: str
    username: str
    first_name: str = Field(min_length=1, max_length=80)
    last_name: str = Field(min_length=1, max_length=80)
    password: str
    password_confirm: str

    @field_validator("email", "email_confirm", "username", "first_name", "last_name")
    @classmethod
    def strip_text(cls, value: str) -> str:
        return value.strip()

    @field_validator("email")
    @classmethod
    def check_email(cls, value: str) -> str:
        error = email_error(value)
        if error:
            raise ValueError(error)
        return value.lower()

    @field_validator("email_confirm")
    @classmethod
    def check_email_confirm(cls, value: str) -> str:
        return value.lower()

    @field_validator("username")
    @classmethod
    def check_username(cls, value: str) -> str:
        error = username_error(value)
        if error:
            raise ValueError(error)
        return value

    @field_validator("password")
    @classmethod
    def check_password(cls, value: str) -> str:
        error = password_error(value)
        if error:
            raise ValueError(error)
        return value

    @model_validator(mode="after")
    def check_confirmations(self) -> "RegisterRequest":
        if self.email != self.email_confirm:
            raise ValueError("Les adresses e-mail ne correspondent pas")
        if self.password != self.password_confirm:
            raise ValueError("Les mots de passe ne correspondent pas")
        return self


class UserInfoResponse(BaseModel):
    sub: str
    email: str
    name: str | None = None
    given_name: str | None = None
    family_name: str | None = None
    roles: list[str] = Field(default_factory=list)
