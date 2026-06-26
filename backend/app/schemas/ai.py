"""Schemas de request/response de los endpoints /ai.

Separados de los schemas internos del LLM (services/ai/schemas.py): estos son el
contrato público de la API; aquéllos validan la salida cruda del modelo.
"""
from typing import Literal

from pydantic import BaseModel, Field, field_validator

_MAX_CHARS = 5000


class ChatTurn(BaseModel):
    """Turno previo de la conversación (para dar contexto al asistente)."""
    role: Literal['user', 'assistant']
    content: str = Field(max_length=_MAX_CHARS)


class ChatRequest(BaseModel):
    message: str
    history: list[ChatTurn] = Field(default_factory=list, max_length=20)

    @field_validator('message')
    @classmethod
    def not_empty(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError('El mensaje no puede estar vacío')
        if len(v) > _MAX_CHARS:
            raise ValueError(f'El mensaje no puede superar {_MAX_CHARS} caracteres')
        return v


class ChatResponse(BaseModel):
    reply: str
    risk_level: str | None = None
    risk_score: float | None = None
    reasons: list[str] = Field(default_factory=list)
    sources: list[str] = Field(default_factory=list)  # estafas del índice usadas (RAG)
    model: str
    processing_ms: int


class TranscriptionResponse(BaseModel):
    text: str
    language: str | None = None
    model: str
    processing_ms: int
    # Veredicto heurístico inmediato sobre el texto transcrito (sin coste extra).
    risk_level: str
    risk_score: float
    patterns_found: list[str] = Field(default_factory=list)


class SpeechRequest(BaseModel):
    text: str
    voice: str | None = None

    @field_validator('text')
    @classmethod
    def not_empty(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError('El texto no puede estar vacío')
        if len(v) > _MAX_CHARS:
            raise ValueError(f'El texto no puede superar {_MAX_CHARS} caracteres')
        return v


class VisionResponse(BaseModel):
    risk_level: str
    risk_score: float
    reasons: list[str] = Field(default_factory=list)
    extracted_text: str = ''
    model: str
    processing_ms: int
