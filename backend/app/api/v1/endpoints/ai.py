"""Endpoints de IA respaldados por Groq.

  POST /ai/chat        — asistente conversacional + veredicto de estafa
  POST /ai/transcribe  — audio → texto (Whisper) + riesgo heurístico inmediato
  POST /ai/speak       — texto → audio WAV (TTS, accesibilidad)
  POST /ai/vision      — captura → veredicto de estafa (modelo de visión)

Todos requieren autenticación. Si Groq no está configurado, responden 503 (no
500), de modo que el cliente pueda degradar con su heurística local.
"""
import hashlib
import json

import structlog
from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Response,
    UploadFile,
    status,
)
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.analysis import Analysis
from app.models.user import User
from app.schemas.ai import (
    ChatRequest,
    ChatResponse,
    ChatTurn,
    SpeechRequest,
    TranscriptionResponse,
    VisionResponse,
)
from app.services.ai import get_ai_provider
from app.services.ai.base import AIProvider, ChatMessage
from app.services.ai.groq_client import GroqNotConfiguredError
from app.services.auth_service import get_current_user
from app.services.ml.text_analyzer import get_text_analyzer

logger = structlog.get_logger()
router = APIRouter()

# Límites de carga alineados con los de Groq y para acotar superficie de abuso.
_MAX_AUDIO_BYTES = 25 * 1024 * 1024  # 25 MB
_MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB
_ALLOWED_IMAGE_TYPES = {'image/png', 'image/jpeg', 'image/webp', 'image/gif'}


async def _guard(coro, *, op: str):
    """Ejecuta una llamada al proveedor traduciendo fallos a códigos HTTP claros."""
    try:
        return await coro
    except GroqNotConfiguredError as exc:
        logger.warning('ai_not_configured', op=op, error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail='El servicio de IA no está disponible en este momento.',
        )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001 — frontera con un servicio externo
        logger.error('ai_call_failed', op=op, error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail='El proveedor de IA falló al procesar la solicitud.',
        )


async def _persist(
    db: AsyncSession, user: User, *, kind: str, level: str, score: float,
    reasons: list[str], content_hash: str, processing_ms: int,
) -> None:
    """Guarda el veredicto en el historial (coherente con /analysis/history)."""
    db.add(Analysis(
        user_id=user.id,
        analysis_type=kind,
        risk_level=level,
        risk_score=score,
        content_hash=content_hash,
        patterns_found=reasons,
        processing_ms=processing_ms,
    ))
    await db.flush()


async def _read_valid_image(file: UploadFile) -> bytes:
    """Valida tipo/tamaño y devuelve los bytes de una imagen subida.

    Compartido por /vision y /chat-image para no duplicar los límites de abuso."""
    if file.content_type not in _ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f'Formato no soportado. Permitidos: {", ".join(sorted(_ALLOWED_IMAGE_TYPES))}',
        )
    image = await file.read()
    if not image:
        raise HTTPException(status_code=422, detail='La imagen está vacía.')
    if len(image) > _MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail='La imagen supera el límite de 10 MB.')
    return image


def _parse_history(raw: str) -> list[ChatMessage]:
    """Decodifica el historial (JSON en un campo de formulario) a ChatMessage.

    Multipart no admite cuerpos JSON anidados, así que el cliente envía el historial
    serializado. Se valida con el mismo schema que el chat de texto (solo roles
    'user'/'assistant') y se acota a 20 turnos."""
    try:
        items = json.loads(raw or '[]')
        if not isinstance(items, list):
            raise ValueError('El historial debe ser una lista de turnos.')
        turns = [ChatTurn.model_validate(item) for item in items[:20]]
    except (json.JSONDecodeError, ValidationError, ValueError, TypeError):
        raise HTTPException(status_code=422, detail='Historial inválido.')
    return [ChatMessage(role=t.role, content=t.content) for t in turns]


@router.get('/ping', summary='Liveness del módulo de IA')
async def ping():
    return {'status': 'ok'}


@router.post('/chat', response_model=ChatResponse, summary='Asistente ShieldAI (chat + veredicto)')
async def chat(
    data: ChatRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    ai: AIProvider = Depends(get_ai_provider),
):
    history = [ChatMessage(role=t.role, content=t.content) for t in data.history]
    result = await _guard(ai.analyze_message(data.message, history), op='chat')

    if result.risk_level is not None:
        await _persist(
            db, current_user, kind='text', level=result.risk_level,
            score=result.risk_score or 0.0, reasons=result.reasons,
            content_hash=hashlib.sha256(data.message.encode()).hexdigest(),
            processing_ms=result.processing_ms,
        )

    return ChatResponse(
        reply=result.reply,
        risk_level=result.risk_level,
        risk_score=result.risk_score,
        reasons=result.reasons,
        sources=result.sources,
        model=result.model,
        processing_ms=result.processing_ms,
    )


@router.post(
    '/chat-image',
    response_model=ChatResponse,
    summary='Asistente ShieldAI (chat con imagen + contexto)',
)
async def chat_image(
    file: UploadFile = File(..., description='Captura a analizar'),
    message: str = Form('', description='Contexto opcional escrito por el usuario'),
    history: str = Form('[]', description='Historial previo (JSON: [{role, content}])'),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    ai: AIProvider = Depends(get_ai_provider),
):
    """Turno de chat multimodal: una imagen + un contexto de texto opcional.

    Devuelve el MISMO contrato que /chat (reply + veredicto), de modo que la UI de
    chat renderiza la respuesta igual que la de un mensaje de texto."""
    image = await _read_valid_image(file)
    turns = _parse_history(history)

    result = await _guard(
        ai.analyze_message(message, turns, image=image, mime_type=file.content_type),
        op='chat-image',
    )

    if result.risk_level is not None:
        await _persist(
            db, current_user, kind='image', level=result.risk_level,
            score=result.risk_score or 0.0, reasons=result.reasons,
            content_hash=hashlib.sha256(image).hexdigest(),
            processing_ms=result.processing_ms,
        )

    return ChatResponse(
        reply=result.reply,
        risk_level=result.risk_level,
        risk_score=result.risk_score,
        reasons=result.reasons,
        sources=result.sources,
        model=result.model,
        processing_ms=result.processing_ms,
    )


@router.post('/transcribe', response_model=TranscriptionResponse, summary='Audio → texto + riesgo')
async def transcribe(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    ai: AIProvider = Depends(get_ai_provider),
):
    audio = await file.read()
    if not audio:
        raise HTTPException(status_code=422, detail='El archivo de audio está vacío.')
    if len(audio) > _MAX_AUDIO_BYTES:
        raise HTTPException(status_code=413, detail='El audio supera el límite de 25 MB.')

    result = await _guard(
        ai.transcribe(audio, file.filename or 'audio.wav'), op='transcribe'
    )
    # Riesgo inmediato sobre el texto transcrito con la heurística local (sin coste).
    heur = get_text_analyzer().analyze(result.text or '')
    return TranscriptionResponse(
        text=result.text,
        language=result.language,
        model=result.model,
        processing_ms=result.processing_ms,
        risk_level=heur.risk_level,
        risk_score=heur.risk_score,
        patterns_found=heur.patterns_found,
    )


@router.post('/speak', summary='Texto → audio WAV (TTS)')
async def speak(
    data: SpeechRequest,
    current_user: User = Depends(get_current_user),
    ai: AIProvider = Depends(get_ai_provider),
):
    result = await _guard(ai.synthesize(data.text, data.voice), op='speak')
    return Response(
        content=result.audio,
        media_type=result.content_type,
        headers={'X-AI-Model': result.model},
    )


@router.post('/vision', response_model=VisionResponse, summary='Captura → veredicto de estafa')
async def vision(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    ai: AIProvider = Depends(get_ai_provider),
):
    image = await _read_valid_image(file)

    result = await _guard(
        ai.analyze_image(image, file.content_type), op='vision'
    )
    await _persist(
        db, current_user, kind='image', level=result.risk_level,
        score=result.risk_score, reasons=result.reasons,
        content_hash=hashlib.sha256(image).hexdigest(),
        processing_ms=result.processing_ms,
    )
    return VisionResponse(
        risk_level=result.risk_level,
        risk_score=result.risk_score,
        reasons=result.reasons,
        extracted_text=result.extracted_text,
        model=result.model,
        processing_ms=result.processing_ms,
    )
