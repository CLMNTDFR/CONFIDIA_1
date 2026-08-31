import pytest

from infrastructure.paperless.paperless_client import PaperlessClient


@pytest.fixture
def paperless_client():
    return PaperlessClient(base_url="http://localhost:8001", token="")


@pytest.mark.asyncio
async def test_list_mock_documents(paperless_client):
    items, total = await paperless_client.list_documents()
    assert total > 0
    assert len(items) > 0
    assert items[0].title


@pytest.mark.asyncio
async def test_get_mock_document(paperless_client):
    doc = await paperless_client.get_document(1)
    assert doc is not None
    assert doc.id == "1"


@pytest.mark.asyncio
async def test_search_mock_documents(paperless_client):
    from application.dto.document_dto import DocumentSearchDTO

    results = await paperless_client.search_documents(DocumentSearchDTO(query="EDF"))
    assert len(results) > 0
