"""Account creation then login, without a live Keycloak."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from jose import jwt

from api.deps import get_identity_service
from api.main import app
from application.services.identity_service import IdentityService
from tests.fakes.identity_repository import InMemoryIdentityRepository
from tests.fakes.keycloak import FakeKeycloakAsyncClient

VALID = {
    "email": "camille@confidia.local",
    "email_confirm": "camille@confidia.local",
    "username": "camille",
    "first_name": "Camille",
    "last_name": "Martin",
    "password": "SolidPassw0rd!",
    "password_confirm": "SolidPassw0rd!",
}


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


def test_register_rejects_email_mismatch(register_harness):
    client, repo = register_harness
    response = client.post(
        "/api/v1/auth/register",
        json={**VALID, "email_confirm": "other@confidia.local"},
    )
    assert response.status_code == 422
    assert repo.rows == {}


def test_register_rejects_password_mismatch(register_harness):
    client, _ = register_harness
    response = client.post(
        "/api/v1/auth/register",
        json={**VALID, "password_confirm": "SolidPassw0rd?"},
    )
    assert response.status_code == 422


def test_register_rejects_weak_password(register_harness):
    client, repo = register_harness
    response = client.post(
        "/api/v1/auth/register",
        json={**VALID, "password": "weak", "password_confirm": "weak"},
    )
    assert response.status_code == 422
    assert repo.rows == {}


def test_register_creates_account_persists_identity_and_returns_tokens(register_harness):
    client, repo = register_harness
    response = client.post("/api/v1/auth/register", json=VALID)
    assert response.status_code == 201
    body = response.json()
    claims = jwt.get_unverified_claims(body["access_token"])
    assert claims["preferred_username"] == "camille"
    assert claims["email"] == "camille@confidia.local"
    assert claims["given_name"] == "Camille"
    stored = repo.rows[claims["sub"]].stored
    assert stored.first_name == "Camille"
    assert stored.last_name == "Martin"
    assert stored.email == "camille@confidia.local"
    assert stored.organization_name == "Famille"


def test_register_then_login_with_same_credentials(register_harness):
    client, repo = register_harness
    created = client.post("/api/v1/auth/register", json=VALID)
    assert created.status_code == 201
    login = client.post(
        "/api/v1/auth/login",
        json={"username": "camille", "password": "SolidPassw0rd!"},
    )
    assert login.status_code == 200
    assert len(repo.rows) == 1
    login_claims = jwt.get_unverified_claims(login.json()["access_token"])
    register_claims = jwt.get_unverified_claims(created.json()["access_token"])
    assert login_claims["sub"] == register_claims["sub"]


def test_register_accepts_accented_username(register_harness):
    client, repo = register_harness
    response = client.post(
        "/api/v1/auth/register",
        json={**VALID, "username": "clément"},
    )
    assert response.status_code == 201
    claims = jwt.get_unverified_claims(response.json()["access_token"])
    assert claims["preferred_username"] == "clément"
    assert repo.rows


def test_register_duplicate_username_returns_409(register_harness):
    client, _ = register_harness
    assert client.post("/api/v1/auth/register", json=VALID).status_code == 201
    again = client.post(
        "/api/v1/auth/register",
        json={**VALID, "email": "other@confidia.local", "email_confirm": "other@confidia.local"},
    )
    assert again.status_code == 409
    assert "utilisateur" in again.json()["detail"].lower()


def test_register_duplicate_email_returns_409(register_harness):
    client, _ = register_harness
    assert client.post("/api/v1/auth/register", json=VALID).status_code == 201
    again = client.post(
        "/api/v1/auth/register",
        json={**VALID, "username": "camille2"},
    )
    assert again.status_code == 409
    assert "e-mail" in again.json()["detail"].lower()


def test_login_unknown_user_still_401(register_harness):
    client, repo = register_harness
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "ghost", "password": "SolidPassw0rd!"},
    )
    assert response.status_code == 401
    assert repo.rows == {}
