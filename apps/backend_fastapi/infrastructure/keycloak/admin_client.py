from __future__ import annotations

import httpx

from core.config import Settings

_TIMEOUT = httpx.Timeout(30.0)


class KeycloakUserExistsError(Exception):
    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class KeycloakAdminError(Exception):
    def __init__(self, message: str, status_code: int = 502):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class KeycloakAdminClient:
    """Creates realm users via the Keycloak Admin REST API (master admin-cli)."""

    def __init__(self, settings: Settings):
        self._settings = settings

    async def create_user(
        self,
        *,
        username: str,
        email: str,
        first_name: str,
        last_name: str,
        password: str,
    ) -> str:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            admin_token = await self._admin_token(client)
            headers = {"Authorization": f"Bearer {admin_token}"}
            response = await client.post(
                f"{self._settings.keycloak_url}/admin/realms/{self._settings.keycloak_realm}/users",
                headers=headers,
                json={
                    "username": username,
                    "email": email,
                    "firstName": first_name,
                    "lastName": last_name,
                    "enabled": True,
                    "emailVerified": True,
                    "credentials": [
                        {"type": "password", "value": password, "temporary": False},
                    ],
                },
            )
            if response.status_code == 409:
                raw = ""
                try:
                    raw = str(response.json().get("errorMessage") or "")
                except Exception:
                    raw = response.text
                lowered = raw.lower()
                if "email" in lowered:
                    raise KeycloakUserExistsError("Cette adresse e-mail est déjà utilisée")
                raise KeycloakUserExistsError("Ce nom d'utilisateur est déjà pris")
            if response.status_code not in (201, 204):
                raise KeycloakAdminError(
                    "Impossible de créer le compte pour le moment",
                    status_code=502,
                )
            location = response.headers.get("Location") or response.headers.get("location") or ""
            user_id = location.rstrip("/").rsplit("/", 1)[-1]
            if not user_id:
                raise KeycloakAdminError("Keycloak n'a pas renvoyé l'identifiant du compte")
            await self._assign_realm_role(client, headers, user_id, "USER")
            return user_id

    async def reset_password(self, user_id: str, password: str) -> None:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            admin_token = await self._admin_token(client)
            response = await client.put(
                f"{self._settings.keycloak_url}/admin/realms/{self._settings.keycloak_realm}"
                f"/users/{user_id}/reset-password",
                headers={"Authorization": f"Bearer {admin_token}"},
                json={"type": "password", "value": password, "temporary": False},
            )
            if response.status_code not in (200, 204):
                raise KeycloakAdminError("Impossible de changer le mot de passe pour le moment")

    async def _admin_token(self, client: httpx.AsyncClient) -> str:
        response = await client.post(
            self._settings.keycloak_admin_token_url,
            data={
                "grant_type": "password",
                "client_id": "admin-cli",
                "username": self._settings.keycloak_admin_user,
                "password": self._settings.keycloak_admin_password,
            },
        )
        if response.status_code != 200:
            raise KeycloakAdminError(
                "Service d'inscription indisponible (Keycloak)",
                status_code=503,
            )
        return str(response.json()["access_token"])

    async def _assign_realm_role(
        self,
        client: httpx.AsyncClient,
        headers: dict[str, str],
        user_id: str,
        role_name: str,
    ) -> None:
        role_response = await client.get(
            f"{self._settings.keycloak_url}/admin/realms/{self._settings.keycloak_realm}/roles/{role_name}",
            headers=headers,
        )
        if role_response.status_code != 200:
            return
        role = role_response.json()
        await client.post(
            f"{self._settings.keycloak_url}/admin/realms/{self._settings.keycloak_realm}"
            f"/users/{user_id}/role-mappings/realm",
            headers=headers,
            json=[{"id": role["id"], "name": role["name"]}],
        )
