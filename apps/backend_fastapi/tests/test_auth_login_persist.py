"""Login and /users/me persist identity without a live Keycloak or Postgres."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from jose import jwt

from api.deps import get_identity_service
from api.main import app
from application.services.identity_service import IdentityService
from tests.fakes.identity_repository import InMemoryIdentityRepository

CLAIMS = {
    "sub": "kc-login-persist-1",
    "email": "login-persist@confidia.local",
    "given_name": "Jean",
    "family_name": "Dupont",
    "preferred_username": "user",
    "realm_access": {"roles": ["USER"]},
}

ACCESS_TOKEN = jwt.encode(CLAIMS, key="test-secret", algorithm="HS256")


class _FakeResponse:
    def __init__(self, status_code: int, payload: dict):
        self.status_code = status_code
        self._payload = payload

    def json(self) -> dict:
        return self._payload


class _FakeKeycloakClient:
    def __init__(self, *args, **kwargs):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return None

    async def post(self, url, data=None):
        if (data or {}).get("password") == "wrong":
            return _FakeResponse(401, {"error": "invalid_grant"})
        return _FakeResponse(
            200,
            {
                "access_token": ACCESS_TOKEN,
                "refresh_token": "refresh-token",
                "token_type": "bearer",
                "expires_in": 300,
            },
        )


@pytest.fixture
def identity_harness(monkeypatch: pytest.MonkeyPatch):
    repo = InMemoryIdentityRepository()
    app.dependency_overrides[get_identity_service] = lambda: IdentityService(repo)
    monkeypatch.setattr(
        "application.services.auth_service.httpx.AsyncClient",
        _FakeKeycloakClient,
    )
    with TestClient(app) as client:
        yield client, repo
    app.dependency_overrides.clear()


def test_login_upserts_user_and_famille_workspace(identity_harness):
    client, repo = identity_harness
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "user", "password": "user"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["access_token"] == ACCESS_TOKEN

    stored = repo.rows[CLAIMS["sub"]].stored
    assert stored.email == "login-persist@confidia.local"
    assert stored.first_name == "Jean"
    assert stored.organization_name == "Famille"
    assert stored.membership_role == "owner"

    again = client.post(
        "/api/v1/auth/login",
        json={"username": "user", "password": "user"},
    )
    assert again.status_code == 200
    assert len(repo.rows) == 1


def test_login_rejects_invalid_credentials_without_writing(identity_harness):
    client, repo = identity_harness
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "user", "password": "wrong"},
    )
    assert response.status_code == 401
    assert repo.rows == {}


def test_users_me_returns_persisted_profile(identity_harness):
    client, repo = identity_harness
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    response = client.get("/api/v1/users/me", headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == CLAIMS["sub"]
    assert body["first_name"] == "Jean"
    assert body["organization"] == "Famille"
    assert CLAIMS["sub"] in repo.rows

    second = client.get("/api/v1/users/me", headers=headers)
    assert second.status_code == 200
    assert len(repo.rows) == 1
