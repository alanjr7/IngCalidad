"""Tests unitarios del provider de IA sin tocar la red.

Cubre el parseo robusto de la salida del LLM (`_extract_json`) y la degradación
segura cuando el modelo devuelve algo que no es el JSON esperado.
"""
from app.services.ai.providers.groq import _extract_json
from app.services.ai.schemas import AssistantReply, VisionVerdict


def test_extract_json_plain():
    assert _extract_json('{"a": 1}') == {'a': 1}


def test_extract_json_wrapped_in_fences():
    raw = '```json\n{"risk_level": "high", "risk_score": 0.9}\n```'
    assert _extract_json(raw) == {'risk_level': 'high', 'risk_score': 0.9}


def test_extract_json_with_surrounding_text():
    raw = 'Claro, aquí tenés el análisis: {"reply": "ojo"} ¡saludos!'
    assert _extract_json(raw) == {'reply': 'ojo'}


def test_extract_json_invalid_returns_empty():
    assert _extract_json('no hay json aquí') == {}
    assert _extract_json('') == {}


def test_assistant_reply_defaults_are_safe():
    # Si el modelo solo devuelve texto, el resto queda en None/listas vacías,
    # no rompe la respuesta de la API.
    reply = AssistantReply.model_validate({'reply': 'hola'})
    assert reply.reply == 'hola'
    assert reply.risk_level is None
    assert reply.reasons == []


def test_vision_verdict_rejects_out_of_range_score():
    import pytest
    with pytest.raises(Exception):
        VisionVerdict.model_validate(
            {'risk_level': 'high', 'risk_score': 5.0}  # fuera de [0,1]
        )
