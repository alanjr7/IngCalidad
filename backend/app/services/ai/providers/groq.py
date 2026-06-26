"""Implementación de `AIProvider` sobre Groq.

Una sola clase cubre las cuatro capacidades:
  - analyze_message  → chat LLM        (llama-3.3-70b-versatile)
  - transcribe       → audio/STT       (whisper-large-v3-turbo)
  - synthesize       → voz/TTS         (playai-tts)
  - analyze_image    → visión          (llama-4-scout)

Cada método mide latencia y normaliza la salida a las dataclasses de `base.py`.
La salida JSON del modelo se valida con Pydantic (schemas.py); ante cualquier
desvío se degrada de forma segura (riesgo desconocido en vez de exponer basura).
"""
from __future__ import annotations

import base64
import inspect
import json
import time

import structlog

from app.core.config import get_settings
from app.services.ai import prompts
from app.services.ai.base import (
    AssistantResult,
    ChatMessage,
    SpeechResult,
    TranscriptionResult,
    VisionResult,
)
from app.services.ai.groq_client import get_groq_client
from app.services.ai.scam_index import get_scam_index
from app.services.ai.schemas import AssistantReply, VisionVerdict

logger = structlog.get_logger()
settings = get_settings()


def _extract_json(raw: str) -> dict:
    """Extrae el primer objeto JSON de la respuesta del modelo.

    Tolera respuestas envueltas en ```json ... ``` o con texto alrededor. Devuelve
    {} si no hay JSON parseable (el caller decide el fallback seguro)."""
    if not raw:
        return {}
    text = raw.strip()
    start, end = text.find('{'), text.rfind('}')
    if start == -1 or end == -1 or end < start:
        return {}
    try:
        return json.loads(text[start : end + 1])
    except json.JSONDecodeError:
        return {}


async def _read_binary(response) -> bytes:
    """Extrae bytes de la respuesta binaria del TTS de forma robusta entre
    versiones del SDK (algunas exponen .read(), otras .content)."""
    reader = getattr(response, 'read', None)
    if callable(reader):
        data = reader()
        if inspect.isawaitable(data):
            data = await data
        return data
    if hasattr(response, 'content'):
        return response.content
    return bytes(response)


def _to_data_url(image_bytes: bytes, mime_type: str) -> str:
    """Codifica la imagen como data URL base64 para la API de visión."""
    return f'data:{mime_type};base64,{base64.b64encode(image_bytes).decode()}'


def _build_multimodal_messages(
    text: str,
    image: bytes,
    mime_type: str | None,
    history: list[ChatMessage] | None,
    context: str,
) -> list[dict]:
    """Arma los mensajes del turno multimodal (chat con imagen) para la API.

    Estructura: system blindado + (contexto RAG) + historial + mensaje 'user' con
    DOS partes: el contexto del usuario envuelto como dato no confiable y la imagen.
    El caption viaja envuelto para no mezclarse con instrucciones (anti-injection)."""
    messages: list[dict] = [
        {'role': 'system', 'content': prompts.CHAT_VISION_SYSTEM_PROMPT}
    ]
    if context:
        messages.append({'role': 'system', 'content': prompts.reference_system_text(context)})
    if history:
        messages.extend({'role': m.role, 'content': m.content} for m in history)

    caption = (text or '').strip()
    if caption:
        instruction = (
            'Analizá esta captura teniendo en cuenta el contexto que aporta el '
            f'usuario:\n{prompts.wrap_untrusted(caption)}\nDevolvé el JSON solicitado.'
        )
    else:
        instruction = 'Analizá esta captura y devolvé el JSON solicitado.'

    messages.append({
        'role': 'user',
        'content': [
            {'type': 'text', 'text': instruction},
            {'type': 'image_url', 'image_url': {'url': _to_data_url(image, mime_type or 'image/jpeg')}},
        ],
    })
    return messages


class GroqAIProvider:
    """Proveedor de IA respaldado por Groq. Cumple el Protocol `AIProvider`."""

    # ── Chat (RAG: recuperar del índice → aumentar prompt → generar) ──
    async def analyze_message(
        self,
        text: str,
        history: list[ChatMessage] | None = None,
        *,
        image: bytes | None = None,
        mime_type: str | None = None,
    ) -> AssistantResult:
        """Analiza un turno de conversación que opcionalmente trae una imagen.

        Sin imagen: chat de texto con el modelo conversacional. Con imagen: el
        contenido va como mensaje multimodal al modelo de visión, conservando el
        contexto RAG y el historial. En ambos casos devuelve un `AssistantResult`
        (mismo contrato), de modo que el cliente renderiza el veredicto igual."""
        client = get_groq_client()

        # 1) Recuperar estafas conocidas parecidas (título → subtítulo → desc).
        #    Sobre el contexto en texto; con solo imagen puede no haber coincidencias.
        matches = get_scam_index().search(text or '', k=3)
        context = get_scam_index().format_for_prompt(matches)
        sources = [m.entry.title for m in matches]

        # 2) Armar los mensajes según haya o no imagen y generar.
        if image is not None:
            messages = _build_multimodal_messages(text, image, mime_type, history, context)
            model = settings.groq_vision_model
            fallback = 'No pude analizar la imagen, intentá de nuevo.'
        else:
            chat_messages = prompts.build_assistant_messages(text, history, context=context)
            messages = [{'role': m.role, 'content': m.content} for m in chat_messages]
            model = settings.groq_chat_model
            fallback = 'No pude analizar el mensaje, intentá de nuevo.'

        parsed, elapsed = await self._generate_reply(client, model, messages)
        return AssistantResult(
            reply=parsed.reply or fallback,
            risk_level=parsed.risk_level,
            risk_score=parsed.risk_score,
            reasons=parsed.reasons,
            sources=sources,
            model=model,
            processing_ms=elapsed,
        )

    @staticmethod
    async def _generate_reply(client, model: str, messages: list[dict]):
        """Pide al modelo un JSON con forma `AssistantReply` y lo valida.

        Centraliza los parámetros deterministas (temperature=0 → reproducible y
        auditable) y el parseo robusto compartido por los caminos texto/imagen."""
        start = time.monotonic()
        completion = await client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.0,
            max_tokens=settings.groq_max_output_tokens,
            response_format={'type': 'json_object'},
        )
        elapsed = int((time.monotonic() - start) * 1000)
        raw = completion.choices[0].message.content or ''
        parsed = AssistantReply.model_validate(_extract_json(raw) or {'reply': raw})
        return parsed, elapsed

    # ── Audio → texto (STT) ───────────────────────────────────
    async def transcribe(
        self, audio: bytes, filename: str, language: str | None = None
    ) -> TranscriptionResult:
        client = get_groq_client()
        start = time.monotonic()
        result = await client.audio.transcriptions.create(
            file=(filename, audio),
            model=settings.groq_transcription_model,
            language=language,
            response_format='json',
        )
        elapsed = int((time.monotonic() - start) * 1000)
        return TranscriptionResult(
            text=getattr(result, 'text', '').strip(),
            language=language,
            model=settings.groq_transcription_model,
            processing_ms=elapsed,
        )

    # ── Texto → voz (TTS) ─────────────────────────────────────
    async def synthesize(self, text: str, voice: str | None = None) -> SpeechResult:
        client = get_groq_client()
        start = time.monotonic()
        response = await client.audio.speech.create(
            model=settings.groq_tts_model,
            voice=voice or settings.groq_tts_voice,
            input=text,
            response_format='wav',
        )
        audio = await _read_binary(response)
        elapsed = int((time.monotonic() - start) * 1000)
        return SpeechResult(
            audio=audio,
            content_type='audio/wav',
            model=settings.groq_tts_model,
            processing_ms=elapsed,
        )

    # ── Imagen → veredicto (visión) ───────────────────────────
    async def analyze_image(self, image_bytes: bytes, mime_type: str) -> VisionResult:
        client = get_groq_client()
        data_url = _to_data_url(image_bytes, mime_type)
        start = time.monotonic()
        completion = await client.chat.completions.create(
            model=settings.groq_vision_model,
            messages=[
                {'role': 'system', 'content': prompts.VISION_SYSTEM_PROMPT},
                {
                    'role': 'user',
                    'content': [
                        {
                            'type': 'text',
                            'text': 'Analizá esta captura y devolvé el JSON solicitado.',
                        },
                        {'type': 'image_url', 'image_url': {'url': data_url}},
                    ],
                },
            ],
            temperature=0.0,
            max_tokens=settings.groq_max_output_tokens,
            response_format={'type': 'json_object'},
        )
        elapsed = int((time.monotonic() - start) * 1000)

        raw = completion.choices[0].message.content or ''
        data = _extract_json(raw)
        try:
            verdict = VisionVerdict.model_validate(data)
        except Exception:  # salida no conforme → degradación segura
            logger.warning('vision_verdict_invalid', model=settings.groq_vision_model)
            verdict = VisionVerdict(
                risk_level='medium',
                risk_score=0.5,
                reasons=['No se pudo evaluar la imagen con certeza; revisá con cautela.'],
                extracted_text='',
            )
        return VisionResult(
            risk_level=verdict.risk_level,
            risk_score=verdict.risk_score,
            reasons=verdict.reasons,
            extracted_text=verdict.extracted_text,
            model=settings.groq_vision_model,
            processing_ms=elapsed,
        )
