"""Document upload / list / detail without a live Postgres."""

from __future__ import annotations

from io import BytesIO

import pytest
from fastapi.testclient import TestClient
from jose import jwt

from api.deps import get_identity_service, get_workspace_document_service
from api.main import app
from application.services.identity_service import IdentityService
from application.services.workspace_document_service import WorkspaceDocumentService
from tests.fakes.document_repository import InMemoryDocumentRepository
from tests.fakes.identity_repository import InMemoryIdentityRepository

CLAIMS = {
    "sub": "kc-docs-1",
    "email": "docs@confidia.local",
    "given_name": "Docs",
    "family_name": "User",
    "realm_access": {"roles": ["USER"]},
    "iss": "http://localhost:8080/realms/confidia",
    "azp": "confidia-backend",
}
TOKEN = jwt.encode(CLAIMS, key="test", algorithm="HS256")
HEADERS = {"Authorization": f"Bearer {TOKEN}"}


@pytest.fixture
def docs_harness():
    identity_repo = InMemoryIdentityRepository()
    docs_repo = InMemoryDocumentRepository()
    app.dependency_overrides[get_identity_service] = lambda: IdentityService(identity_repo)
    app.dependency_overrides[get_workspace_document_service] = lambda: WorkspaceDocumentService(
        docs_repo
    )
    with TestClient(app) as client:
        yield client, identity_repo, docs_repo
    app.dependency_overrides.clear()


def test_upload_list_and_detail_persist_in_workspace(docs_harness):
    client, identity_repo, docs_repo = docs_harness
    empty = client.get("/api/v1/documents/", headers=HEADERS)
    assert empty.status_code == 200
    assert empty.json()["total"] == 0
    assert identity_repo.rows["kc-docs-1"].stored.organization_name == "Famille"

    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("facture.pdf", BytesIO(b"%PDF-fake"), "application/pdf")},
        data={"title": "Facture EDF", "category": "Énergie", "document_type": "Facture"},
    )
    assert upload.status_code == 201
    body = upload.json()
    assert body["title"] == "Facture EDF"
    assert body["category"] == "Énergie"
    assert body["document_type"] == "Facture"
    assert body["file_size"] == len(b"%PDF-fake")
    doc_id = body["id"]

    listing = client.get("/api/v1/documents/", headers=HEADERS)
    assert listing.json()["total"] == 1
    assert listing.json()["items"][0]["id"] == doc_id

    detail = client.get(f"/api/v1/documents/{doc_id}", headers=HEADERS)
    assert detail.status_code == 200
    assert detail.json()["title"] == "Facture EDF"

    again = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("autre.pdf", BytesIO(b"%PDF-abc"), "application/pdf")},
    )
    assert again.status_code == 201
    assert client.get("/api/v1/documents/", headers=HEADERS).json()["total"] == 2


def test_uploaded_file_can_be_downloaded(docs_harness):
    client, _, _ = docs_harness
    payload = b"%PDF-preview"
    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("scan.pdf", BytesIO(payload), "application/pdf")},
        data={"title": "Scan loyers"},
    )
    assert upload.status_code == 201
    doc_id = upload.json()["id"]

    file_res = client.get(f"/api/v1/documents/{doc_id}/file", headers=HEADERS)
    assert file_res.status_code == 200
    assert file_res.content == payload
    assert "pdf" in file_res.headers["content-type"]
    assert file_res.headers["content-disposition"].startswith("inline;")


def test_document_file_unknown_is_404(docs_harness):
    client, _, _ = docs_harness
    response = client.get(
        "/api/v1/documents/11111111-1111-1111-1111-111111111111/file",
        headers=HEADERS,
    )
    assert response.status_code == 404


def test_document_detail_unknown_is_404(docs_harness):
    client, _, _ = docs_harness
    response = client.get(
        "/api/v1/documents/11111111-1111-1111-1111-111111111111",
        headers=HEADERS,
    )
    assert response.status_code == 404


def test_update_and_delete_document(docs_harness):
    client, _, _ = docs_harness
    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("scan.pdf", BytesIO(b"%PDF-x"), "application/pdf")},
        data={"title": "Scan initial", "category": "Identité"},
    )
    assert upload.status_code == 201
    doc_id = upload.json()["id"]

    patched = client.patch(
        f"/api/v1/documents/{doc_id}",
        headers=HEADERS,
        json={"title": "Passeport", "category": "Administratif"},
    )
    assert patched.status_code == 200
    assert patched.json()["title"] == "Passeport"
    assert patched.json()["category"] == "Administratif"

    empty_title = client.patch(
        f"/api/v1/documents/{doc_id}",
        headers=HEADERS,
        json={"title": "  "},
    )
    assert empty_title.status_code == 422

    deleted = client.delete(f"/api/v1/documents/{doc_id}", headers=HEADERS)
    assert deleted.status_code == 204
    assert client.get(f"/api/v1/documents/{doc_id}", headers=HEADERS).status_code == 404
    assert client.get("/api/v1/documents/", headers=HEADERS).json()["total"] == 0


def test_documents_require_auth():
    with TestClient(app) as client:
        assert client.get("/api/v1/documents/").status_code == 401


def test_documents_are_isolated_between_workspaces(docs_harness):
    client, _identity, _docs = docs_harness
    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("secret.pdf", BytesIO(b"%PDF-secret"), "application/pdf")},
        data={"title": "Secret"},
    )
    assert upload.status_code == 201
    doc_id = upload.json()["id"]

    other_claims = {
        "sub": "kc-docs-2",
        "email": "other-docs@confidia.local",
        "given_name": "Other",
        "family_name": "User",
        "realm_access": {"roles": ["USER"]},
        "iss": "http://localhost:8080/realms/confidia",
        "azp": "confidia-backend",
    }
    other_headers = {
        "Authorization": f"Bearer {jwt.encode(other_claims, key='test', algorithm='HS256')}"
    }
    listed = client.get("/api/v1/documents/", headers=other_headers)
    assert listed.status_code == 200
    assert listed.json()["total"] == 0
    stolen = client.get(f"/api/v1/documents/{doc_id}", headers=other_headers)
    assert stolen.status_code == 404
    stolen_file = client.get(f"/api/v1/documents/{doc_id}/file", headers=other_headers)
    assert stolen_file.status_code == 404
