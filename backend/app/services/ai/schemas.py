"""Esquemas Pydantic para validar la SALIDA estructurada del LLM.

Pedimos al modelo JSON con estos esquemas y los validamos antes de confiar en
ellos. Es una defensa clave contra prompt-injection: aunque el atacante logre
influir en el texto, la respuesta solo se acepta si cumple el contrato (nivel de
riesgo de un conjunto cerrado, score acotado, etc.). Cualquier desvío se degrada
de forma segura en el provider.
"""
from typing import Literal

from pydantic import BaseModel, Field

RiskLevel = Literal['low', 'medium', 'high']


class AssistantReply(BaseModel):
    """Salida esperada del asistente de chat (LLM)."""
    reply: str = Field(default='', description='Respuesta conversacional al usuario')
    risk_level: RiskLevel | None = None
    risk_score: float | None = Field(default=None, ge=0.0, le=1.0)
    reasons: list[str] = Field(default_factory=list, max_length=8)


class VisionVerdict(BaseModel):
    """Salida esperada del análisis de imagen (modelo de visión)."""
    risk_level: RiskLevel
    risk_score: float = Field(ge=0.0, le=1.0)
    reasons: list[str] = Field(default_factory=list, max_length=8)
    extracted_text: str = Field(default='', max_length=2000)
