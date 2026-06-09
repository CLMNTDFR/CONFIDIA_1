from application.dto.ai_dto import (
    AmountExtractionDTO,
    ClassificationDTO,
    DateExtractionDTO,
    ExtractedAmount,
    ExtractedDate,
    SummaryDTO,
)
from domain.interfaces.ai_provider import DocumentAIProvider


class MockAIProvider(DocumentAIProvider):
    """Mock AI provider returning simulated data. No token consumption."""

    async def summarize(self, document_id: int, content: str) -> SummaryDTO:
        return SummaryDTO(
            document_id=document_id,
            summary=(
                f"Résumé simulé du document #{document_id}. "
                "Ce document contient des informations administratives importantes "
                "nécessitant une attention particulière."
            ),
            confidence=0.85,
            provider="mock",
        )

    async def classify(self, document_id: int, content: str) -> ClassificationDTO:
        categories = ["Facture", "Contrat", "Identité", "Fiscal", "Assurance"]
        category = categories[document_id % len(categories)]
        return ClassificationDTO(
            document_id=document_id,
            category=category,
            subcategory=f"Sous-catégorie {category}",
            confidence=0.78,
            tags=["auto-classifié", category.lower()],
            provider="mock",
        )

    async def extract_dates(self, document_id: int, content: str) -> DateExtractionDTO:
        return DateExtractionDTO(
            document_id=document_id,
            dates=[
                ExtractedDate(date="2026-01-15", label="Date d'émission", confidence=0.92),
                ExtractedDate(date="2026-02-15", label="Date d'échéance", confidence=0.88),
                ExtractedDate(date="2026-12-31", label="Date de validité", confidence=0.75),
            ],
            provider="mock",
        )

    async def extract_amounts(self, document_id: int, content: str) -> AmountExtractionDTO:
        return AmountExtractionDTO(
            document_id=document_id,
            amounts=[
                ExtractedAmount(amount=156.78, currency="EUR", label="Montant TTC", confidence=0.95),
                ExtractedAmount(amount=130.65, currency="EUR", label="Montant HT", confidence=0.90),
                ExtractedAmount(amount=26.13, currency="EUR", label="TVA", confidence=0.88),
            ],
            provider="mock",
        )
