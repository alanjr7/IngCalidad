"""Contratos del subsistema de IA (anti-corruption layer).

Define un único `AIProvider` (Protocol) con las cuatro capacidades que pidió el
proyecto —chat, transcripción de audio, síntesis de voz y visión— más las
dataclasses de dominio que devuelven sus métodos.

Por qué un Protocol y no una clase base: permite inyectar un *fake* en los tests
sin tocar la red ni el SDK de Groq (mismo patrón de DI que `AnalysisService` en
el mobile). El resto de la app depende de estos tipos, nunca de los del SDK.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol, runtime_checkable


# ── Tipos de entrada ─────────────────────────────────────────
@dataclass
class ChatMessage:
    role: str  # 'system' | 'user' | 'assistant'
    content: str


# ── Tipos de salida (dominio, agnósticos del proveedor) ──────
@dataclass
class AssistantResult:
    """Respuesta del asistente: texto conversacional + veredicto de riesgo."""
    reply: str
    risk_level: str | None  # 'low' | 'medium' | 'high' | None
    risk_score: float | None
    reasons: list[str] = field(default_factory=list)
    sources: list[str] = field(default_factory=list)  # estafas del índice usadas (RAG)
    model: str = ''
    processing_ms: int = 0


@dataclass
class TranscriptionResult:
    text: str
    language: str | None
    model: str = ''
    processing_ms: int = 0


@dataclass
class SpeechResult:
    audio: bytes
    content_type: str  # p. ej. 'audio/wav'
    model: str = ''
    processing_ms: int = 0


@dataclass
class VisionResult:
    risk_level: str
    risk_score: float
    reasons: list[str] = field(default_factory=list)
    extracted_text: str = ''
    model: str = ''
    processing_ms: int = 0


# ── Contrato ─────────────────────────────────────────────────
@runtime_checkable
class AIProvider(Protocol):
    """Capacidades de IA que consume la API. Una implementación = Groq."""

    async def analyze_message(
        self,
        text: str,
        history: list[ChatMessage] | None = None,
        *,
        image: bytes | None = None,
        mime_type: str | None = None,
    ) -> AssistantResult: ...

    async def transcribe(
        self, audio: bytes, filename: str, language: str | None = None
    ) -> TranscriptionResult: ...

    async def synthesize(self, text: str, voice: str | None = None) -> SpeechResult: ...

    async def analyze_image(self, image_bytes: bytes, mime_type: str) -> VisionResult: ...
