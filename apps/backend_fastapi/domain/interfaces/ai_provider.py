from abc import ABC, abstractmethod

from application.dto.ai_dto import (
    AmountExtractionDTO,
    ClassificationDTO,
    DateExtractionDTO,
    SummaryDTO,
)


class DocumentAIProvider(ABC):
    """Interface for AI document processing providers (OpenAI, Claude, Mistral, local LLM)."""

    @abstractmethod
    async def summarize(self, document_id: int, content: str) -> SummaryDTO:
        ...

    @abstractmethod
    async def classify(self, document_id: int, content: str) -> ClassificationDTO:
        ...

    @abstractmethod
    async def extract_dates(self, document_id: int, content: str) -> DateExtractionDTO:
        ...

    @abstractmethod
    async def extract_amounts(self, document_id: int, content: str) -> AmountExtractionDTO:
        ...
