import pytest

from infrastructure.ai.mock_ai_provider import MockAIProvider


@pytest.fixture
def ai_provider():
    return MockAIProvider()


@pytest.mark.asyncio
async def test_summarize(ai_provider):
    result = await ai_provider.summarize(1, "test content")
    assert result.document_id == 1
    assert len(result.summary) > 0
    assert result.provider == "mock"
    assert 0 <= result.confidence <= 1


@pytest.mark.asyncio
async def test_classify(ai_provider):
    result = await ai_provider.classify(2, "test content")
    assert result.document_id == 2
    assert result.category
    assert result.provider == "mock"


@pytest.mark.asyncio
async def test_extract_dates(ai_provider):
    result = await ai_provider.extract_dates(1, "test")
    assert result.document_id == 1
    assert len(result.dates) > 0


@pytest.mark.asyncio
async def test_extract_amounts(ai_provider):
    result = await ai_provider.extract_amounts(1, "test")
    assert result.document_id == 1
    assert len(result.amounts) > 0
    assert result.amounts[0].currency == "EUR"
