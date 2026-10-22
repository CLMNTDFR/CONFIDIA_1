"""JWT verification, upload sniffing, and HTTP security headers."""

from __future__ import annotations

import base64
import json
from io import BytesIO

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import HTTPException
from fastapi.testclient import TestClient
from jose import jwt
from jose.utils import base64url_encode

from api.deps import get_identity_service, get_workspace_document_service
from api.main import app
from application.services.identity_service import IdentityService
from application.services.workspace_document_service import WorkspaceDocumentService
from core.config import get_settings
from core.security import verified_claims
from core.uploads import inspect_avatar, inspect_document, read_limited, sniff_mime
from tests.fakes.document_repository import InMemoryDocumentRepository
from tests.fakes.identity_repository import InMemoryIdentityRepository
from tests.fakes.keycloak import FakeKeycloakAsyncClient

CLAIMS = {
    "sub": "kc-sec-1",
    "email": "sec@confidia.local",
    "preferred_username": "secuser",
    "realm_access": {"roles": ["USER"]},
    "iss": "http://localhost:8080/realms/confidia",
    "azp": "confidia-backend",
}


def _hs(claims: dict, key: str = "test") -> str:
    return jwt.encode(claims, key=key, algorithm="HS256")


def _rsa_material() -> tuple[str, dict]:
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    private_pem = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()
    numbers = key.public_key().public_numbers()

    def _b64(value: int) -> str:
        raw = value.to_bytes((value.bit_length() + 7) // 8, "big")
        return base64url_encode(raw).decode()

    jwks = {
        "keys": [
            {
                "kty": "RSA",
                "kid": "test-rsa",
                "use": "sig",
                "alg": "RS256",
                "n": _b64(numbers.n),
                "e": _b64(numbers.e),
            }
        ]
    }
    return private_pem, jwks


def _unsigned(claims: dict) -> str:
    header = base64.urlsafe_b64encode(
        json.dumps({"alg": "none", "typ": "JWT"}).encode()
    ).rstrip(b"=")
    payload = base64.urlsafe_b64encode(json.dumps(claims).encode()).rstrip(b"=")
    return f"{header.decode()}.{payload.decode()}."


def test_forged_hs256_token_is_rejected():
    token = _hs(CLAIMS, key="forged")
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/notifications/",
            headers={"Authorization": f"Bearer {token}"},
        )
    assert response.status_code == 401


def test_empty_sub_is_rejected():
    token = _hs({**CLAIMS, "sub": "  "})
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/notifications/",
            headers={"Authorization": f"Bearer {token}"},
        )
    assert response.status_code == 401


def test_unsigned_token_is_rejected():
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/notifications/",
            headers={"Authorization": f"Bearer {_unsigned(CLAIMS)}"},
        )
    assert response.status_code == 401


def test_hs256_is_rejected_outside_test_env(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("APP_ENV", "development")
    get_settings.cache_clear()
    token = _hs(CLAIMS)
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/notifications/",
            headers={"Authorization": f"Bearer {token}"},
        )
    assert response.status_code == 401


def test_expired_hs256_is_rejected():
    token = jwt.encode({**CLAIMS, "exp": 1}, key="test", algorithm="HS256")
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/notifications/",
            headers={"Authorization": f"Bearer {token}"},
        )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_rs256_is_verified_against_jwks(monkeypatch: pytest.MonkeyPatch):
    private_pem, jwks = _rsa_material()

    async def _jwks(settings, force: bool = False):
        del settings, force
        return jwks

    monkeypatch.setattr("core.security._load_jwks", _jwks)
    token = jwt.encode(CLAIMS, private_pem, algorithm="RS256", headers={"kid": "test-rsa"})
    payload = await verified_claims(token, get_settings())
    assert payload["sub"] == "kc-sec-1"


@pytest.mark.asyncio
async def test_rs256_for_another_client_is_rejected(monkeypatch: pytest.MonkeyPatch):
    private_pem, jwks = _rsa_material()

    async def _jwks(settings, force: bool = False):
        del settings, force
        return jwks

    monkeypatch.setattr("core.security._load_jwks", _jwks)
    token = jwt.encode(
        {**CLAIMS, "aud": "account", "azp": "confidia-frontend"},
        private_pem,
        algorithm="RS256",
        headers={"kid": "test-rsa"},
    )
    with pytest.raises(HTTPException) as exc:
        await verified_claims(token, get_settings())
    assert exc.value.status_code == 401


@pytest.mark.asyncio
async def test_rs256_with_unknown_key_is_rejected(monkeypatch: pytest.MonkeyPatch):
    signer_pem, _ = _rsa_material()
    _, jwks = _rsa_material()

    async def _jwks(settings, force: bool = False):
        del settings, force
        return jwks

    monkeypatch.setattr("core.security._load_jwks", _jwks)
    token = jwt.encode(CLAIMS, signer_pem, algorithm="RS256", headers={"kid": "test-rsa"})
    with pytest.raises(HTTPException) as exc:
        await verified_claims(token, get_settings())
    assert exc.value.status_code == 401


def test_valid_test_token_is_accepted():
    token = _hs(CLAIMS)
    with TestClient(app) as client:
        response = client.get(
            "/api/v1/notifications/",
            headers={"Authorization": f"Bearer {token}"},
        )
    assert response.status_code == 200


def test_security_headers_are_present():
    with TestClient(app) as client:
        response = client.get("/health")
    assert response.status_code == 200
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["referrer-policy"] == "no-referrer"
    assert "no-store" in response.headers.get("cache-control", "")


def test_logout_revokes_refresh_token(monkeypatch: pytest.MonkeyPatch):
    FakeKeycloakAsyncClient.reset()
    monkeypatch.setattr(
        "application.services.auth_service.httpx.AsyncClient",
        FakeKeycloakAsyncClient,
    )
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/auth/logout",
            json={"refresh_token": "refresh-token"},
        )
    assert response.status_code == 200
    FakeKeycloakAsyncClient.reset()


def test_storage_rejects_path_traversal():
    token = _hs(CLAIMS)
    headers = {"Authorization": f"Bearer {token}"}
    with TestClient(app) as client:
        listed = client.get(
            "/api/v1/storage/files",
            params={"directory": "/../../etc"},
            headers=headers,
        )
        shared = client.post(
            "/api/v1/storage/share",
            params={"path": "/Documents/../secret"},
            headers=headers,
        )
        encoded = client.get(
            "/api/v1/storage/files",
            params={"directory": "/%2e%2e/%2e%2e/etc"},
            headers=headers,
        )
    assert listed.status_code == 400
    assert shared.status_code == 400
    assert encoded.status_code == 400


def test_sniff_rejects_html_and_svg():
    with pytest.raises(ValueError, match="non autorisé"):
        inspect_document("facture.pdf", b"<html><body>x</body></html>")
    with pytest.raises(ValueError, match="non pris en charge"):
        inspect_avatar(b"<svg xmlns='http://www.w3.org/2000/svg'></svg>")
    assert sniff_mime(b"%PDF-1.4") == "application/pdf"
    assert inspect_document("scan.pdf", b"%PDF-1.4") == "application/pdf"


@pytest.mark.asyncio
async def test_read_limited_caps_payload():
    class _Fake:
        async def read(self, n: int) -> bytes:
            return b"a" * n

    with pytest.raises(ValueError, match="too big"):
        await read_limited(_Fake(), 8, too_large="too big")


def test_upload_rejects_html_even_with_pdf_content_type():
    identity_repo = InMemoryIdentityRepository()
    docs_repo = InMemoryDocumentRepository()
    app.dependency_overrides[get_identity_service] = lambda: IdentityService(identity_repo)
    app.dependency_overrides[get_workspace_document_service] = lambda: WorkspaceDocumentService(
        docs_repo
    )
    token = _hs(CLAIMS)
    try:
        with TestClient(app) as client:
            response = client.post(
                "/api/v1/documents/upload",
                headers={"Authorization": f"Bearer {token}"},
                files={"file": ("page.html", BytesIO(b"<html>x</html>"), "application/pdf")},
            )
        assert response.status_code == 415
    finally:
        app.dependency_overrides.clear()
