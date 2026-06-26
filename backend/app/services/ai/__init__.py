"""Subsistema de IA (Groq).

Expone `get_ai_provider`, la dependencia que usan los endpoints. Es un singleton
perezoso: no construye nada del SDK hasta la primera llamada real, y en los tests
se sustituye vía `app.dependency_overrides[get_ai_provider]` por un fake.
"""
from app.services.ai.base import AIProvider
from app.services.ai.providers.groq import GroqAIProvider

_provider: AIProvider | None = None


def get_ai_provider() -> AIProvider:
    global _provider
    if _provider is None:
        _provider = GroqAIProvider()
    return _provider


__all__ = ['AIProvider', 'GroqAIProvider', 'get_ai_provider']
