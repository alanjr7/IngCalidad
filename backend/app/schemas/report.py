import uuid
from datetime import datetime
from pydantic import BaseModel, Field


class AnonymousReportCreate(BaseModel):
    analysis_type: str
    risk_level: str
    risk_score: float = Field(ge=0.0, le=1.0)
    patterns_found: list[str] = []
    region: str | None = None        # solo código de país, ej. "MX"
    app_version: str | None = None


class AnonymousReportResponse(BaseModel):
    id: uuid.UUID
    analysis_type: str
    risk_level: str
    risk_score: float
    created_at: datetime

    model_config = {'from_attributes': True}
