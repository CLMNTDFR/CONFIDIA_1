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
    trash = client.get("/api/v1/documents/trash", headers=HEADERS)
    assert trash.status_code == 200
    assert trash.json()["total"] == 1
    assert trash.json()["items"][0]["id"] == doc_id


def test_trash_restore_keeps_the_file_until_purge(docs_harness):
    client, _, repo = docs_harness
    payload = b"%PDF-trash"
    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("scan.pdf", BytesIO(payload), "application/pdf")},
        data={"title": "Scan corbeille"},
    )
    doc_id = upload.json()["id"]
    assert client.delete(f"/api/v1/documents/{doc_id}", headers=HEADERS).status_code == 204
    assert doc_id in repo.payloads
    assert client.get(f"/api/v1/documents/{doc_id}/file", headers=HEADERS).status_code == 404

    restored = client.post(f"/api/v1/documents/{doc_id}/restore", headers=HEADERS)
    assert restored.status_code == 200
    assert restored.json()["title"] == "Scan corbeille"
    assert client.get("/api/v1/documents/trash", headers=HEADERS).json()["total"] == 0
    assert client.get(f"/api/v1/documents/{doc_id}/file", headers=HEADERS).content == payload

    assert client.delete(f"/api/v1/documents/{doc_id}", headers=HEADERS).status_code == 204
    purged = client.post(
        f"/api/v1/documents/{doc_id}/purge",
        headers=HEADERS,
        json={"decisions": []},
    )
    assert purged.status_code == 204
    assert doc_id not in repo.payloads
    assert client.get("/api/v1/documents/trash", headers=HEADERS).json()["total"] == 0
    assert client.post(f"/api/v1/documents/{doc_id}/restore", headers=HEADERS).status_code == 404


def test_purge_asks_for_every_live_event_link(docs_harness):
    from datetime import UTC, datetime
    from uuid import UUID, uuid4

    from application.dto.document_dto import DocumentPurgeDecision
    from tests.fakes.document_repository import MemoryEventLink

    client, identity_repo, repo = docs_harness
    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("scan.pdf", BytesIO(b"%PDF-link"), "application/pdf")},
        data={"title": "Contrat"},
    )
    doc_id = upload.json()["id"]
    org_id = identity_repo.rows["kc-docs-1"].stored.organization_id
    assert org_id is not None
    live = MemoryEventLink(
        event_id=uuid4(),
        organization_id=org_id,
        document_id=UUID(doc_id),
        title="Signature",
        start=datetime(2026, 10, 18, 8, 0, tzinfo=UTC),
    )
    archived = MemoryEventLink(
        event_id=uuid4(),
        organization_id=org_id,
        document_id=UUID(doc_id),
        title="Ancien rappel",
        start=datetime(2026, 10, 1, 8, 0, tzinfo=UTC),
        deleted_at=datetime(2026, 10, 2, tzinfo=UTC),
    )
    repo.events.extend([live, archived])
    assert client.delete(f"/api/v1/documents/{doc_id}", headers=HEADERS).status_code == 204

    links = client.get(f"/api/v1/documents/{doc_id}/links", headers=HEADERS)
    assert links.status_code == 200
    body = links.json()
    assert {item["title"] for item in body} == {"Signature", "Ancien rappel"}
    assert next(item for item in body if item["title"] == "Ancien rappel")["deleted"] is True

    missing = client.post(
        f"/api/v1/documents/{doc_id}/purge",
        headers=HEADERS,
        json={"decisions": []},
    )
    assert missing.status_code == 409
    assert live.document_id == UUID(doc_id)

    kept = client.post(
        f"/api/v1/documents/{doc_id}/purge",
        headers=HEADERS,
        json={
            "decisions": [
                DocumentPurgeDecision(event_id=live.event_id, action="keep").model_dump(mode="json")
            ]
        },
    )
    assert kept.status_code == 204
    assert live.document_id is None
    assert live.deleted_at is None
    assert archived.document_id is None
    assert doc_id not in repo.payloads


def test_purge_can_delete_a_linked_event(docs_harness):
    from datetime import UTC, datetime
    from uuid import UUID, uuid4

    from application.dto.document_dto import DocumentPurgeDecision
    from tests.fakes.document_repository import MemoryEventLink

    client, identity_repo, repo = docs_harness
    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("scan.pdf", BytesIO(b"%PDF-gone"), "application/pdf")},
        data={"title": "A jeter"},
    )
    doc_id = upload.json()["id"]
    org_id = identity_repo.rows["kc-docs-1"].stored.organization_id
    event = MemoryEventLink(
        event_id=uuid4(),
        organization_id=org_id,
        document_id=UUID(doc_id),
        title="Rendez-vous",
        start=datetime(2026, 10, 18, 9, 0, tzinfo=UTC),
    )
    repo.events.append(event)
    assert client.delete(f"/api/v1/documents/{doc_id}", headers=HEADERS).status_code == 204
    purged = client.post(
        f"/api/v1/documents/{doc_id}/purge",
        headers=HEADERS,
        json={
            "decisions": [
                DocumentPurgeDecision(
                    event_id=event.event_id, action="delete"
                ).model_dump(mode="json")
            ]
        },
    )
    assert purged.status_code == 204
    assert event.document_id is None
    assert event.deleted_at is not None


def test_trash_is_isolated_between_workspaces(docs_harness):
    client, _, _ = docs_harness
    upload = client.post(
        "/api/v1/documents/upload",
        headers=HEADERS,
        files={"file": ("secret.pdf", BytesIO(b"%PDF-secret"), "application/pdf")},
        data={"title": "Secret"},
    )
    doc_id = upload.json()["id"]
    assert client.delete(f"/api/v1/documents/{doc_id}", headers=HEADERS).status_code == 204
    other_claims = {
        "sub": "kc-docs-3",
        "email": "third-docs@confidia.local",
        "given_name": "Third",
        "family_name": "User",
        "realm_access": {"roles": ["USER"]},
        "iss": "http://localhost:8080/realms/confidia",
        "azp": "confidia-backend",
    }
    other = {"Authorization": f"Bearer {jwt.encode(other_claims, key='test', algorithm='HS256')}"}
    assert client.get("/api/v1/documents/trash", headers=other).json()["total"] == 0
    forbidden = client.post(
        f"/api/v1/documents/{doc_id}/purge",
        headers=other,
        json={},
    )
    assert forbidden.status_code == 404
    assert client.get("/api/v1/documents/trash", headers=HEADERS).json()["total"] == 1


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
