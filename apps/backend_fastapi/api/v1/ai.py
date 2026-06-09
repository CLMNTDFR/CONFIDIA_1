from fastapi import APIRouter, Depends

from application.dto.ai_dto import (
    AmountExtractionDTO,
    ClassificationDTO,
    DateExtractionDTO,
    SummaryDTO,
)
from core.security import TokenPayload, decode_token
from infrastructure.ai.mock_ai_provider import MockAIProvider

router = APIRouter()
_ai_provider = MockAIProvider()


@router.post("/documents/{document_id}/summarize", response_model=SummaryDTO)
async def summarize_document(
    document_id: int,
    content: str = "",
    token: TokenPayload = Depends(decode_token),
):
    return await _ai_provider.summarize(document_id, content)


@router.post("/documents/{document_id}/classify", response_model=ClassificationDTO)
async def classify_document(
    document_id: int,
    content: str = "",
    token: TokenPayload = Depends(decode_token),
):
    return await _ai_provider.classify(document_id, content)


@router.post("/documents/{document_id}/extract-dates", response_model=DateExtractionDTO)
async def extract_dates(
    document_id: int,
    content: str = "",
    token: TokenPayload = Depends(decode_token),
):
    return await _ai_provider.extract_dates(document_id, content)


@router.post("/documents/{document_id}/extract-amounts", response_model=AmountExtractionDTO)
async def extract_amounts(
    document_id: int,
    content: str = "",
    token: TokenPayload = Depends(decode_token),
):
    return await _ai_provider.extract_amounts(document_id, content)
