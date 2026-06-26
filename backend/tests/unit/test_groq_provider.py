"""Tests del proveedor de IA (Groq) con un cliente FALSO — sin red ni SDK real.

Patrón: inyectamos un fake en `get_groq_client` (DI) y verificamos que cada
capacidad (chat, visión, STT, TTS) normaliza la salida a las dataclasses de
dominio y que el camino de visión degrada de forma segura ante JSON inválido.
"""
import json
from types import SimpleNamespace

import pytest

from app.services.ai import prompts
from app.services.ai.providers import groq as provider
from app.services.ai.providers.groq import (
    GroqAIProvider,
    _build_multimodal_messages,
    _read_binary,
    _to_data_url,
)


# ── Cliente falso ────────────────────────────────────────────
class _FakeChatCompletions:
    def __init__(self, content: str):
        self._content = content

    async def create(self, **kwargs):
        message = SimpleNamespace(content=self._content)
        return SimpleNamespace(choices=[SimpleNamespace(message=message)])


class _FakeTranscriptions:
    async def create(self, **kwargs):
        return SimpleNamespace(text="  hola desde el audio  ")


class _FakeSpeech:
    async def create(self, **kwargs):
        # El SDK expone .read() síncrono que devuelve los bytes del wav.
        return SimpleNamespace(read=lambda: b"WAVE-BYTES")


class FakeGroqClient:
    def __init__(self, content: str):
        self.chat = SimpleNamespace(completions=_FakeChatCompletions(content))
        self.audio = SimpleNamespace(
            transcriptions=_FakeTranscriptions(), speech=_FakeSpeech()
        )


def _patch_client(monkeypatch, content: str):
    monkeypatch.setattr(provider, "get_groq_client", lambda: FakeGroqClient(content))


# ── Funciones puras ──────────────────────────────────────────
def test_to_data_url_encodes_base64():
    url = _to_data_url(b"hola", "image/png")
    assert url.startswith("data:image/png;base64,")
    assert "aG9sYQ==" in url  # base64('hola')


def test_extract_json_roundtrip():
    assert provider._extract_json('{"a": 1}') == {"a": 1}
    assert provider._extract_json("sin json") == {}


def test_build_multimodal_messages_wraps_untrusted_caption():
    msgs = _build_multimodal_messages(
        text="mirá esto",
        image=b"img",
        mime_type="image/png",
        history=[provider.ChatMessage(role="user", content="hola")],
        context="contexto-rag",
    )
    assert msgs[0]["role"] == "system"
    # El último mensaje es el 'user' multimodal: texto + imagen.
    user_msg = msgs[-1]
    assert user_msg["role"] == "user"
    kinds = {part["type"] for part in user_msg["content"]}
    assert kinds == {"text", "image_url"}
    text_part = next(p for p in user_msg["content"] if p["type"] == "text")
    assert prompts.wrap_untrusted("mirá esto") in text_part["text"]


def test_build_multimodal_messages_without_caption():
    msgs = _build_multimodal_messages(
        text="", image=b"img", mime_type=None, history=None, context=""
    )
    text_part = next(p for p in msgs[-1]["content"] if p["type"] == "text")
    assert "Analizá esta captura" in text_part["text"]


# ── _read_binary (robusto entre versiones del SDK) ───────────
async def test_read_binary_from_read_method():
    resp = SimpleNamespace(read=lambda: b"abc")
    assert await _read_binary(resp) == b"abc"


async def test_read_binary_from_content_attr():
    resp = SimpleNamespace(content=b"xyz")
    assert await _read_binary(resp) == b"xyz"


# ── Capacidades del provider ─────────────────────────────────
async def test_analyze_message_text(monkeypatch):
    _patch_client(monkeypatch, json.dumps(
        {"reply": "Es una estafa", "risk_level": "high", "risk_score": 0.95, "reasons": ["urgencia"]}
    ))
    result = await GroqAIProvider().analyze_message("¿esto es seguro?")
    assert result.reply == "Es una estafa"
    assert result.risk_level == "high"
    assert result.risk_score == 0.95
    assert result.processing_ms >= 0


async def test_analyze_message_with_image_uses_vision_model(monkeypatch):
    _patch_client(monkeypatch, json.dumps(
        {"reply": "Captura sospechosa", "risk_level": "medium", "risk_score": 0.5, "reasons": []}
    ))
    result = await GroqAIProvider().analyze_message("mirá", image=b"PNG", mime_type="image/png")
    assert result.reply == "Captura sospechosa"
    assert result.risk_level == "medium"


async def test_analyze_message_falls_back_when_reply_empty(monkeypatch):
    # Modelo devuelve JSON sin 'reply' → se usa el texto de fallback.
    _patch_client(monkeypatch, json.dumps({"risk_level": "low", "risk_score": 0.1}))
    result = await GroqAIProvider().analyze_message("hola")
    assert "No pude analizar" in result.reply


async def test_transcribe_strips_text(monkeypatch):
    _patch_client(monkeypatch, "{}")
    result = await GroqAIProvider().transcribe(b"audio", "nota.wav", language="es")
    assert result.text == "hola desde el audio"
    assert result.language == "es"


async def test_synthesize_returns_wav_bytes(monkeypatch):
    _patch_client(monkeypatch, "{}")
    result = await GroqAIProvider().synthesize("hola mundo")
    assert result.audio == b"WAVE-BYTES"
    assert result.content_type == "audio/wav"


async def test_analyze_image_valid_verdict(monkeypatch):
    _patch_client(monkeypatch, json.dumps(
        {"risk_level": "high", "risk_score": 0.9, "reasons": ["pide tarjeta"], "extracted_text": "Banco XYZ"}
    ))
    result = await GroqAIProvider().analyze_image(b"PNG", "image/png")
    assert result.risk_level == "high"
    assert result.extracted_text == "Banco XYZ"


async def test_analyze_image_degrades_on_invalid_json(monkeypatch):
    # Salida no conforme al schema → degradación segura a riesgo medio.
    _patch_client(monkeypatch, "esto no es json")
    result = await GroqAIProvider().analyze_image(b"PNG", "image/png")
    assert result.risk_level == "medium"
    assert result.risk_score == 0.5
    assert result.reasons  # mensaje de cautela
