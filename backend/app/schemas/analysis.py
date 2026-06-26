import uuid
from datetime import datetime
from pydantic import BaseModel, field_validator


class TextAnalysisRequest(BaseModel):
    text: str

    @field_validator('text')
    @classmethod
    def not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('El texto no puede estar vacío')
        if len(v) > 5000:
            raise ValueError('El texto no puede superar 5000 caracteres')
        return v.strip()


class AnalysisResponse(BaseModel):
    id: uuid.UUID
    analysis_type: str
    risk_level: str
    risk_score: float
    patterns_found: list[str]
    processing_ms: int | None
    created_at: datetime

    model_config = {'from_attributes': True}


class PatternDetail(BaseModel):
    pattern: str
    description: str
    severity: str  # 'low' | 'medium' | 'high'
