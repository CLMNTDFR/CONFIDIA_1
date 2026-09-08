"""In-memory Keycloak stand-in for register + login HTTP tests."""

from __future__ import annotations

from uuid import uuid4

from jose import jwt


class FakeResponse:
    def __init__(self, status_code: int, payload: dict | None = None, headers: dict | None = None):
        self.status_code = status_code
        self._payload = payload or {}
        self.headers = headers or {}

    def json(self) -> dict:
        return self._payload


class FakeKeycloakAsyncClient:
    """Shared store across httpx.AsyncClient() instances created during one test."""

    users: dict[str, dict] = {}

    def __init__(self, *args, **kwargs):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return None

    @classmethod
    def reset(cls) -> None:
        cls.users = {}

    def _token_for(self, user: dict) -> str:
        return jwt.encode(
            {
                "sub": user["id"],
                "email": user["email"],
                "given_name": user["first_name"],
                "family_name": user["last_name"],
                "preferred_username": user["username"],
                "realm_access": {"roles": ["USER"]},
            },
            key="test-secret",
            algorithm="HS256",
        )

    async def get(self, url, headers=None, **kwargs):
        if url.rstrip("/").endswith("/roles/USER"):
            return FakeResponse(200, {"id": "role-user-id", "name": "USER"})
        return FakeResponse(404, {})

    async def post(self, url, data=None, json=None, headers=None, **kwargs):
        if "/protocol/openid-connect/token" in url:
            payload = data or {}
            if payload.get("client_id") == "admin-cli":
                if payload.get("password") != "admin":
                    return FakeResponse(401, {"error": "invalid_grant"})
                return FakeResponse(200, {"access_token": "admin-token"})
            username = payload.get("username")
            password = payload.get("password")
            user = self.users.get(username or "")
            if user is None or user["password"] != password:
                return FakeResponse(401, {"error": "invalid_grant"})
            return FakeResponse(
                200,
                {
                    "access_token": self._token_for(user),
                    "refresh_token": "refresh-token",
                    "token_type": "bearer",
                    "expires_in": 300,
                },
            )

        if url.rstrip("/").endswith("/users") and json is not None:
            username = json["username"]
            email = json["email"]
            if any(u["username"] == username for u in self.users.values()):
                return FakeResponse(409, {"errorMessage": "User exists with same username"})
            if any(u["email"] == email for u in self.users.values()):
                return FakeResponse(409, {"errorMessage": "User exists with same email"})
            user_id = str(uuid4())
            self.users[username] = {
                "id": user_id,
                "username": username,
                "email": email,
                "first_name": json.get("firstName", ""),
                "last_name": json.get("lastName", ""),
                "password": json["credentials"][0]["value"],
            }
            return FakeResponse(
                201,
                {},
                {"Location": f"http://keycloak/admin/realms/confidia/users/{user_id}"},
            )

        if "role-mappings/realm" in url:
            return FakeResponse(204, {})

        return FakeResponse(404, {})

    async def put(self, url, json=None, headers=None, **kwargs):
        if "/reset-password" in url:
            user_id = url.rstrip("/").rsplit("/", 2)[-2]
            for user in self.users.values():
                if user["id"] == user_id:
                    user["password"] = (json or {}).get("value", user["password"])
                    return FakeResponse(204, {})
            return FakeResponse(404, {})
        return FakeResponse(404, {})
