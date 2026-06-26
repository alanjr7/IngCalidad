"""Índice de estafas conocidas + recuperación (la 'R' del RAG).

Antes de pedirle un veredicto al LLM, buscamos en este índice las estafas más
parecidas al mensaje del usuario y se las pasamos como CONOCIMIENTO DE REFERENCIA.
Así el modelo razona fundamentado en un catálogo curado, no solo en su memoria.

Estrategia de búsqueda (la que pidió el negocio): en cascada y ponderada por
campo —primero TÍTULO, luego SUBTÍTULO, luego DESCRIPCIÓN— más coincidencia de
frases-gatillo (indicators). Es recuperación léxica, no vectorial: Groq no expone
un modelo de embeddings, y para un catálogo curado en español la coincidencia por
palabras/frases es precisa, explicable y sin coste de inferencia extra.
"""
from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

_DATA_PATH = Path(__file__).resolve().parents[2] / 'data' / 'scam_index.json'

# Pesos por campo: el TÍTULO manda, luego subtítulo, luego descripción. Las
# frases-gatillo (indicators) son señales curadas muy fuertes.
_W_TITLE = 5.0
_W_SUBTITLE = 3.0
_W_DESCRIPTION = 1.0
_W_INDICATOR_PHRASE = 6.0

# Palabras vacías que no aportan a la coincidencia.
_STOPWORDS = {
    'que', 'los', 'las', 'una', 'uno', 'con', 'por', 'para', 'del', 'tus', 'tu',
    'mi', 'me', 'te', 'se', 'lo', 'la', 'el', 'un', 'es', 'si', 'no', 'de', 'en',
    'y', 'a', 'o', 'su', 'sus', 'al', 'le', 'ya', 'soy', 'eres', 'esto', 'esta',
}


def _normalize(text: str) -> str:
    """Minúsculas + sin tildes, para que 'envío' y 'envio' coincidan."""
    text = unicodedata.normalize('NFKD', text.lower())
    return ''.join(c for c in text if not unicodedata.combining(c))


def _tokenize(text: str) -> set[str]:
    return {
        t for t in re.split(r'[^a-z0-9]+', _normalize(text))
        if len(t) >= 3 and t not in _STOPWORDS
    }


@dataclass
class ScamEntry:
    id: str
    title: str
    subtitle: str
    description: str
    indicators: list[str] = field(default_factory=list)
    recommended_action: str = ''
    risk_level: str = 'medium'

    # Índices precomputados (no se serializan).
    _title_tokens: set[str] = field(default_factory=set, repr=False)
    _subtitle_tokens: set[str] = field(default_factory=set, repr=False)
    _desc_tokens: set[str] = field(default_factory=set, repr=False)
    _indicator_phrases: list[str] = field(default_factory=list, repr=False)

    def index(self) -> 'ScamEntry':
        self._title_tokens = _tokenize(self.title)
        self._subtitle_tokens = _tokenize(self.subtitle)
        self._desc_tokens = _tokenize(self.description)
        self._indicator_phrases = [_normalize(i) for i in self.indicators]
        return self


@dataclass
class ScamMatch:
    entry: ScamEntry
    score: float


class ScamIndex:
    def __init__(self, entries: list[ScamEntry]):
        self._entries = [e.index() for e in entries]

    def __len__(self) -> int:
        return len(self._entries)

    def search(self, query: str, k: int = 3) -> list[ScamMatch]:
        """Devuelve hasta k estafas relevantes, de mayor a menor score (>0)."""
        q_tokens = _tokenize(query)
        q_norm = _normalize(query)
        scored: list[ScamMatch] = []

        for e in self._entries:
            score = (
                _W_TITLE * len(q_tokens & e._title_tokens)
                + _W_SUBTITLE * len(q_tokens & e._subtitle_tokens)
                + _W_DESCRIPTION * len(q_tokens & e._desc_tokens)
            )
            # Frase-gatillo presente como subcadena del mensaje → señal fuerte.
            score += _W_INDICATOR_PHRASE * sum(
                1 for phrase in e._indicator_phrases if phrase and phrase in q_norm
            )
            if score > 0:
                scored.append(ScamMatch(entry=e, score=score))

        scored.sort(key=lambda m: m.score, reverse=True)
        return scored[:k]

    @staticmethod
    def format_for_prompt(matches: list[ScamMatch]) -> str:
        """Serializa las coincidencias como contexto para el LLM."""
        if not matches:
            return ''
        lines = []
        for m in matches:
            e = m.entry
            lines.append(
                f'- {e.title} ({e.risk_level}): {e.subtitle}. {e.description} '
                f'Recomendación: {e.recommended_action}'
            )
        return '\n'.join(lines)


def _load_entries(path: Path = _DATA_PATH) -> list[ScamEntry]:
    raw = json.loads(path.read_text(encoding='utf-8'))
    return [ScamEntry(**item) for item in raw]


@lru_cache
def get_scam_index() -> ScamIndex:
    return ScamIndex(_load_entries())
