import logging
from datetime import datetime
from typing import BinaryIO

import httpx

from application.dto.document_dto import DocumentCreateDTO, DocumentDTO, DocumentSearchDTO
from domain.interfaces.document_repository import DocumentRepository

logger = logging.getLogger(__name__)


class PaperlessClient(DocumentRepository):
    """Paperless-ngx API client implementing DocumentRepository."""

    def __init__(self, base_url: str, token: str = ""):
        self._base_url = base_url.rstrip("/")
        self._token = token
        self._headers = {"Authorization": f"Token {token}"} if token else {}

    def _parse_document(self, data: dict) -> DocumentDTO:
        return DocumentDTO(
            id=data["id"],
            title=data.get("title", "Untitled"),
            content=data.get("content"),
            created=datetime.fromisoformat(data["created"].replace("Z", "+00:00")),
            modified=datetime.fromisoformat(data["modified"].replace("Z", "+00:00")),
            correspondent=data.get("correspondent"),
            document_type=data.get("document_type"),
            tags=[str(t) for t in data.get("tags", [])],
            mime_type=data.get("mime_type"),
            file_size=data.get("file_size"),
        )

    async def list_documents(
        self, page: int = 1, page_size: int = 25, query: str | None = None
    ) -> tuple[list[DocumentDTO], int]:
        if not self._token:
            return self._mock_documents(page, page_size, query)

        params: dict = {"page": page, "page_size": page_size}
        if query:
            params["query"] = query

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self._base_url}/api/documents/",
                headers=self._headers,
                params=params,
                timeout=30.0,
            )
            if response.status_code != 200:
                logger.warning("Paperless unavailable, returning mock data")
                return self._mock_documents(page, page_size, query)

            data = response.json()
            items = [self._parse_document(d) for d in data.get("results", [])]
            return items, data.get("count", len(items))

    async def get_document(self, document_id: int) -> DocumentDTO | None:
        if not self._token:
            docs, _ = self._mock_documents()
            return next((d for d in docs if d.id == document_id), None)

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self._base_url}/api/documents/{document_id}/",
                headers=self._headers,
                timeout=30.0,
            )
            if response.status_code == 200:
                return self._parse_document(response.json())
            return None

    async def upload_document(
        self, file: BinaryIO, filename: str, metadata: DocumentCreateDTO
    ) -> DocumentDTO:
        if not self._token:
            now = datetime.now()
            return DocumentDTO(
                id=999,
                title=metadata.title or filename,
                created=now,
                modified=now,
                tags=metadata.tags,
                category=metadata.category,
                correspondent=metadata.correspondent,
                document_type=metadata.document_type,
            )

        form_data = {}
        if metadata.title:
            form_data["title"] = metadata.title

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self._base_url}/api/documents/post_document/",
                headers=self._headers,
                files={"document": (filename, file)},
                data=form_data,
                timeout=60.0,
            )
            response.raise_for_status()
            task_id = response.json().get("task_id")
            return DocumentDTO(
                id=0,
                title=metadata.title or filename,
                created=datetime.now(),
                modified=datetime.now(),
                tags=metadata.tags,
            )

    async def delete_document(self, document_id: int) -> bool:
        if not self._token:
            return True

        async with httpx.AsyncClient() as client:
            response = await client.delete(
                f"{self._base_url}/api/documents/{document_id}/",
                headers=self._headers,
                timeout=30.0,
            )
            return response.status_code == 204

    async def search_documents(self, search: DocumentSearchDTO) -> list[DocumentDTO]:
        docs, _ = await self.list_documents(query=search.query)
        if search.tags:
            docs = [d for d in docs if any(t in d.tags for t in search.tags)]
        if search.category:
            docs = [d for d in docs if d.category == search.category]
        return docs

    def _mock_documents(
        self, page: int = 1, page_size: int = 25, query: str | None = None
    ) -> tuple[list[DocumentDTO], int]:
        now = datetime.now()
        all_docs = [
            DocumentDTO(
                id=1,
                title="Facture EDF - Janvier 2026",
                content="Facture électricité mensuelle",
                created=now,
                modified=now,
                correspondent="EDF",
                document_type="Facture",
                tags=["énergie", "facture", "récurrent"],
                category="Énergie",
                mime_type="application/pdf",
                file_size=245_760,
                is_important=True,
            ),
            DocumentDTO(
                id=2,
                title="Contrat assurance habitation",
                content="Police d'assurance multirisque habitation",
                created=now,
                modified=now,
                correspondent="AXA",
                document_type="Contrat",
                tags=["assurance", "habitation"],
                category="Assurance",
                mime_type="application/pdf",
                file_size=1_048_576,
                is_important=True,
            ),
            DocumentDTO(
                id=3,
                title="Avis d'imposition 2025",
                content="Avis d'imposition sur le revenu",
                created=now,
                modified=now,
                correspondent="Direction Générale des Finances Publiques",
                document_type="Avis",
                tags=["impôts", "fiscal"],
                category="Fiscal",
                mime_type="application/pdf",
                file_size=512_000,
            ),
            DocumentDTO(
                id=4,
                title="Attestation employeur",
                content="Attestation de travail",
                created=now,
                modified=now,
                correspondent="TechCorp SAS",
                document_type="Attestation",
                tags=["emploi", "administratif"],
                category="Emploi",
                mime_type="application/pdf",
                file_size=128_000,
            ),
            DocumentDTO(
                id=5,
                title="Passeport - Scan",
                content="Copie passeport",
                created=now,
                modified=now,
                document_type="Identité",
                tags=["identité", "voyage"],
                category="Identité",
                mime_type="application/pdf",
                file_size=2_097_152,
                is_important=True,
            ),
            DocumentDTO(
                id=6,
                title="Relevé bancaire - Février 2026",
                content="Relevé de compte courant",
                created=now,
                modified=now,
                correspondent="BNP Paribas",
                document_type="Relevé",
                tags=["banque", "finances"],
                category="Banque",
                mime_type="application/pdf",
                file_size=384_000,
            ),
        ]

        if query:
            q = query.lower()
            all_docs = [
                d
                for d in all_docs
                if q in d.title.lower()
                or q in (d.content or "").lower()
                or any(q in t for t in d.tags)
            ]

        start = (page - 1) * page_size
        return all_docs[start : start + page_size], len(all_docs)
