"""Profil HTTP : PUT /users/me, noms stables, mot de passe, avatar."""

from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from jose import jwt

from api.deps import get_identity_service
from api.main import app
from application.services.identity_service import IdentityService
from core.config import get_settings
from tests.fakes.identity_repository import InMemoryIdentityRepository
from tests.fakes.keycloak import FakeKeycloakAsyncClient

CLAIMS = {
    "sub": "kc-profile-http-1",
    "email": "profile-http@confidia.local",
    "given_name": "Jean",
    "family_name": "Dupont",
    "preferred_username": "user",
    "realm_access": {"roles": ["USER"]},
}

ACCESS_TOKEN = jwt.encode(CLAIMS, key="test-secret", algorithm="HS256")

REGISTER = {
    "email": "camille@confidia.local",
    "email_confirm": "camille@confidia.local",
    "username": "camille",
    "first_name": "Camille",
    "last_name": "Martin",
    "password": "SolidPassw0rd!",
    "password_confirm": "SolidPassw0rd!",
}


@pytest.fixture
def identity_harness():
    repo = InMemoryIdentityRepository()
    app.dependency_overrides[get_identity_service] = lambda: IdentityService(repo)
    with TestClient(app) as client:
        yield client, repo
    app.dependency_overrides.clear()


@pytest.fixture
def register_harness(monkeypatch: pytest.MonkeyPatch):
    FakeKeycloakAsyncClient.reset()
    repo = InMemoryIdentityRepository()
    app.dependency_overrides[get_identity_service] = lambda: IdentityService(repo)
    monkeypatch.setattr(
        "infrastructure.keycloak.admin_client.httpx.AsyncClient",
        FakeKeycloakAsyncClient,
    )
    monkeypatch.setattr(
        "application.services.auth_service.httpx.AsyncClient",
        FakeKeycloakAsyncClient,
    )
    with TestClient(app) as client:
        yield client, repo
    app.dependency_overrides.clear()
    FakeKeycloakAsyncClient.reset()


def test_put_users_me_persists_and_survives_reload(identity_harness):
    client, repo = identity_harness
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    client.get("/api/v1/users/me", headers=headers)

    updated = client.put(
        "/api/v1/users/me",
        headers=headers,
        json={
            "first_name": "Camille",
            "phone": "+33 6 11 22 33 44",
            "locale": "en_US",
            "organization": "Maison",
        },
    )
    assert updated.status_code == 200, updated.text
    body = updated.json()
    assert body["first_name"] == "Camille"
    assert body["phone"] == "+33 6 11 22 33 44"
    assert body["locale"] == "en-US"
    assert body["organization"] == "Maison"

    again = client.get("/api/v1/users/me", headers=headers)
    assert again.status_code == 200
    assert again.json()["first_name"] == "Camille"
    assert again.json()["phone"] == "+33 6 11 22 33 44"
    assert again.json()["organization"] == "Maison"
    assert repo.rows[CLAIMS["sub"]].stored.first_name == "Camille"


def test_put_users_me_clears_phone(identity_harness):
    client, _repo = identity_harness
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    client.get("/api/v1/users/me", headers=headers)
    client.put("/api/v1/users/me", headers=headers, json={"phone": "+33 6 00 00 00 00"})
    cleared = client.put("/api/v1/users/me", headers=headers, json={"phone": None})
    assert cleared.status_code == 200
    assert cleared.json()["phone"] is None


def test_put_users_me_rejects_blank_name(identity_harness):
    client, _repo = identity_harness
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    response = client.put("/api/v1/users/me", headers=headers, json={"first_name": "  "})
    assert response.status_code == 422


def test_put_users_me_rejects_blank_organization(identity_harness):
    client, _repo = identity_harness
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    client.get("/api/v1/users/me", headers=headers)
    response = client.put("/api/v1/users/me", headers=headers, json={"organization": "  "})
    assert response.status_code == 422


def test_change_password_then_login(register_harness):
    client, _repo = register_harness
    created = client.post("/api/v1/auth/register", json=REGISTER)
    assert created.status_code == 201
    token = created.json()["access_token"]
    changed = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {token}"},
        json={"current_password": REGISTER["password"], "new_password": "OtherPassw0rd!"},
    )
    assert changed.status_code == 200, changed.text

    old = client.post(
        "/api/v1/auth/login",
        json={"username": "camille", "password": REGISTER["password"]},
    )
    assert old.status_code == 401

    fresh = client.post(
        "/api/v1/auth/login",
        json={"username": "camille", "password": "OtherPassw0rd!"},
    )
    assert fresh.status_code == 200


def test_change_password_rejects_wrong_current(register_harness):
    client, _repo = register_harness
    created = client.post("/api/v1/auth/register", json=REGISTER)
    token = created.json()["access_token"]
    response = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {token}"},
        json={"current_password": "WrongPassw0rd!", "new_password": "OtherPassw0rd!"},
    )
    assert response.status_code == 401


def test_avatar_upload_get_delete(
    identity_harness, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
):
    monkeypatch.setenv("DOCUMENTS_STORAGE_DIR", str(tmp_path))
    get_settings.cache_clear()
    client, _repo = identity_harness
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
    client.get("/api/v1/users/me", headers=headers)

    png = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32
    uploaded = client.post(
        "/api/v1/users/me/avatar",
        headers=headers,
        files={"file": ("me.png", png, "image/png")},
    )
    assert uploaded.status_code == 200, uploaded.text
    assert uploaded.json()["avatar_url"] == "/api/v1/users/me/avatar"

    fetched = client.get("/api/v1/users/me/avatar", headers=headers)
    assert fetched.status_code == 200
    assert fetched.content == png

    anonymous = client.get("/api/v1/users/me/avatar")
    assert anonymous.status_code == 401

    deleted = client.delete("/api/v1/users/me/avatar", headers=headers)
    assert deleted.status_code == 200
    assert deleted.json()["avatar_url"] is None
    missing = client.get("/api/v1/users/me/avatar", headers=headers)
    assert missing.status_code == 404
    get_settings.cache_clear()
