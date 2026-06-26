"""Cliente de bajo nivel para la API de Groq.

Aísla la construcción del cliente `AsyncGroq` (API key, timeout, reintentos) y su
ciclo de vida como singleton. No contiene lógica de negocio —eso vive en
providers/groq.py—; así la dependencia del SDK queda confinada a un único punto y
el resto del código es testeable sin instalar `groq`.
"""
from __future__ import annotations

from functools import lru_cache

from app.core.config import get_settings

try:
    from groq import AsyncGroq

    GROQ_AVAILABLE = True
except ImportError:  # el SDK es opcional: en CI/tests usamos fakes
    AsyncGroq = None  # type: ignore[assignment, misc]
    GROQ_AVAILABLE = False


class GroqNotConfiguredError(RuntimeError):
    """El SDK de Groq no está instalado o falta GROQ_API_KEY."""


@lru_cache
def get_groq_client():
    """Devuelve un cliente AsyncGroq compartido. Lanza un error claro y accionable
    si Groq no está disponible, para que la API responda 503 en vez de 500."""
    settings = get_settings()
    if not GROQ_AVAILABLE:
        raise GroqNotConfiguredError(
            'El SDK de Groq no está instalado. Ejecutá: pip install groq'
        )
    if not settings.groq_api_key:
        raise GroqNotConfiguredError(
            'GROQ_API_KEY no está configurada en el entorno (.env).'
        )
    return AsyncGroq(
        api_key=settings.groq_api_key,
        timeout=settings.groq_timeout_seconds,
        max_retries=settings.groq_max_retries,
    )
