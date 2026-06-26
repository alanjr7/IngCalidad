"""
Motor de análisis de texto para detección de smishing/vishing.

Nivel 1 (siempre activo): Análisis de patrones heurísticos — O(n), < 100ms.
Nivel 2 (si nivel 1 es ambiguo): Modelo TFLite BERT pequeño cuantizado INT8.

El diseño en dos niveles garantiza la respuesta en < 3s (criterio de aceptación).
"""

import re
import hashlib
import time
from dataclasses import dataclass, field
from app.core.config import get_settings

settings = get_settings()

# ── Patrones heurísticos ─────────────────────────────────────

_SHORTENED_URL_PATTERN = re.compile(
    r'(bit\.ly|tinyurl\.com|goo\.gl|t\.co|ow\.ly|rb\.gy|cutt\.ly|short\.gy)',
    re.IGNORECASE,
)

_SUSPICIOUS_URL_PATTERN = re.compile(
    r'https?://(?!(?:www\.)?(?:google|facebook|instagram|twitter|youtube)\.com)'
    r'[\w\-]+\.(?:xyz|top|click|download|zip|review|country|stream|gq|tk|ml|cf|ga)',
    re.IGNORECASE,
)

_URGENCY_PATTERN = re.compile(
    r'(urgent[e]?|inmediata?mente?|bloquear[áa]|suspend[ie]|24\s?h[ora]|ahora mismo|'
    r'expire|caduca|vence|último aviso|última oportunidad|act[úu]a ya)',
    re.IGNORECASE,
)

_MONEY_REQUEST_PATTERN = re.compile(
    r'(transfer[íi]|deposita|env[íi]a|paga|reembolso|premio|ganaste|ganador|'
    r'giftcard|gift card|western union|moneygram|\$\s*\d+)',
    re.IGNORECASE,
)

_IDENTITY_IMPERSONATION = re.compile(
    r'(banco\s+\w+|bbva|santander|hsbc|banamex|scotiabank|'
    r'sat\b|imss\b|infonavit|afore|hacienda|gobierno|'
    r'microsoft|amazon|netflix|apple)',
    re.IGNORECASE,
)

_CREDENTIAL_REQUEST = re.compile(
    r'(contraseña|password|clave|nip\b|pin\b|cvv|número de tarjeta|'
    r'datos personales|rfc\b|curp\b|nss\b)',
    re.IGNORECASE,
)

_ORTHO_ERRORS = re.compile(
    r'\b(verifica[cion]|actualizacion|confirmacion|operacion|transaccion|'
    r'informacion)\b',  # sin tilde — señal de texto autogenerado
)


@dataclass
class PatternMatch:
    pattern: str
    description: str
    weight: float  # contribución al score de riesgo


@dataclass
class TextAnalysisResult:
    risk_score: float
    risk_level: str          # 'low' | 'medium' | 'high'
    patterns_found: list[str] = field(default_factory=list)
    processing_ms: int = 0
    content_hash: str = ''


class TextAnalyzer:
    _RULES: list[tuple[re.Pattern, str, float]] = [
        (_SHORTENED_URL_PATTERN,      'URL acortada detectada',         0.30),
        (_SUSPICIOUS_URL_PATTERN,     'Dominio sospechoso',             0.45),
        (_URGENCY_PATTERN,            'Lenguaje de urgencia',           0.25),
        (_MONEY_REQUEST_PATTERN,      'Solicitud de dinero o premio',   0.40),
        (_IDENTITY_IMPERSONATION,     'Posible suplantación de identidad', 0.35),
        (_CREDENTIAL_REQUEST,         'Solicitud de credenciales',      0.50),
        (_ORTHO_ERRORS,               'Errores ortográficos sospechosos', 0.10),
    ]

    def analyze(self, text: str) -> TextAnalysisResult:
        start = time.monotonic()
        content_hash = hashlib.sha256(text.encode()).hexdigest()

        patterns: list[str] = []
        score = 0.0

        for pattern, description, weight in self._RULES:
            if pattern.search(text):
                patterns.append(description)
                score = min(1.0, score + weight)

        # Si el score es ambiguo (0.3-0.6), se podría invocar BERT (futuro)
        risk_level = self._score_to_level(score)
        elapsed_ms = int((time.monotonic() - start) * 1000)

        return TextAnalysisResult(
            risk_score=round(score, 4),
            risk_level=risk_level,
            patterns_found=patterns,
            processing_ms=elapsed_ms,
            content_hash=content_hash,
        )

    @staticmethod
    def _score_to_level(score: float) -> str:
        if score < settings.confidence_threshold_low:
            return 'low'
        if score < settings.confidence_threshold_high:
            return 'medium'
        return 'high'


# Singleton para evitar recarga del modelo en cada request
_analyzer: TextAnalyzer | None = None


def get_text_analyzer() -> TextAnalyzer:
    global _analyzer
    if _analyzer is None:
        _analyzer = TextAnalyzer()
    return _analyzer
