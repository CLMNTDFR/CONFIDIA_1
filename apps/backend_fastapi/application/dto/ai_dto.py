from pydantic import BaseModel, Field


class SummaryDTO(BaseModel):
    document_id: int
    summary: str
    confidence: float = Field(ge=0.0, le=1.0)
    provider: str = "mock"


class ClassificationDTO(BaseModel):
    document_id: int
    category: str
    subcategory: str | None = None
    confidence: float = Field(ge=0.0, le=1.0)
    tags: list[str] = Field(default_factory=list)
    provider: str = "mock"


class ExtractedDate(BaseModel):
    date: str
    label: str
    confidence: float = Field(ge=0.0, le=1.0)


class DateExtractionDTO(BaseModel):
    document_id: int
    dates: list[ExtractedDate] = Field(default_factory=list)
    provider: str = "mock"


class ExtractedAmount(BaseModel):
    amount: float
    currency: str
    label: str
    confidence: float = Field(ge=0.0, le=1.0)


class AmountExtractionDTO(BaseModel):
    document_id: int
    amounts: list[ExtractedAmount] = Field(default_factory=list)
    provider: str = "mock"
