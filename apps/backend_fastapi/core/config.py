from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "CONFIDIA API"
    app_version: str = "0.1.0"
    app_env: str = "development"
    debug: bool = True

    database_url: str = "postgresql+asyncpg://confidia:confidia_secret@localhost:5432/confidia"
    redis_url: str = "redis://localhost:6379/0"

    keycloak_url: str = "http://localhost:8080"
    keycloak_realm: str = "confidia"
    keycloak_client_id: str = "confidia-backend"
    keycloak_client_secret: str = "confidia-backend-secret"
    keycloak_admin_user: str = "admin"
    keycloak_admin_password: str = "admin"
    documents_storage_dir: str = "var/documents"

    paperless_url: str = "http://localhost:8001"
    paperless_token: str = ""

    nextcloud_url: str = "http://localhost:8081"
    nextcloud_user: str = "admin"
    nextcloud_password: str = "admin"

    cors_origins: str = "http://localhost:3000,http://localhost:8082"

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",")]

    @property
    def keycloak_token_url(self) -> str:
        return (
            f"{self.keycloak_url}/realms/{self.keycloak_realm}"
            "/protocol/openid-connect/token"
        )

    @property
    def keycloak_admin_token_url(self) -> str:
        return f"{self.keycloak_url}/realms/master/protocol/openid-connect/token"

    @property
    def keycloak_certs_url(self) -> str:
        return (
            f"{self.keycloak_url}/realms/{self.keycloak_realm}"
            "/protocol/openid-connect/certs"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
