"""
Motor de análisis de imágenes para detección de estafas.

Pipeline:
  1. OCR (Tesseract) — extrae texto de la imagen.
  2. TextAnalyzer — clasifica el texto extraído.
  3. Detector de QR/barcodes — extrae URLs de códigos QR.
  4. (Futuro) CNN — clasifica logos adulterados.

Tiempo objetivo: < 5 segundos (criterio de aceptación Sprint 3).
"""

import time
import hashlib
import re
from io import BytesIO
from dataclasses import dataclass, field
from pathlib import Path

try:
    import pytesseract
    from PIL import Image
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

from .text_analyzer import TextAnalyzer, TextAnalysisResult


@dataclass
class ImageAnalysisResult:
    risk_score: float
    risk_level: str
    patterns_found: list[str] = field(default_factory=list)
    extracted_text: str = ''
    qr_urls: list[str] = field(default_factory=list)
    processing_ms: int = 0
    content_hash: str = ''


_QR_PATTERN = re.compile(r'https?://[^\s]+', re.IGNORECASE)


class ImageAnalyzer:
    def __init__(self):
        self._text_analyzer = TextAnalyzer()

    def analyze(self, image_bytes: bytes) -> ImageAnalysisResult:
        start = time.monotonic()
        content_hash = hashlib.sha256(image_bytes).hexdigest()

        extracted_text = ''
        qr_urls: list[str] = []
        patterns: list[str] = []
        score = 0.0

        if OCR_AVAILABLE:
            try:
                image = Image.open(BytesIO(image_bytes))
                extracted_text = pytesseract.image_to_string(image, lang='spa+eng').strip()
            except Exception:
                patterns.append('Error al procesar imagen')

        # Buscar URLs en el texto extraído
        if extracted_text:
            qr_urls = _QR_PATTERN.findall(extracted_text)
            text_result: TextAnalysisResult = self._text_analyzer.analyze(extracted_text)
            score = text_result.risk_score
            patterns.extend(text_result.patterns_found)

        if qr_urls:
            patterns.append(f'QR/URL detectado: {qr_urls[0][:60]}')
            score = min(1.0, score + 0.20)

        risk_level = self._score_to_level(score)
        elapsed_ms = int((time.monotonic() - start) * 1000)

        return ImageAnalysisResult(
            risk_score=round(score, 4),
            risk_level=risk_level,
            patterns_found=patterns,
            extracted_text=extracted_text[:500],  # truncar para no almacenar texto largo
            qr_urls=qr_urls,
            processing_ms=elapsed_ms,
            content_hash=content_hash,
        )

    @staticmethod
    def _score_to_level(score: float) -> str:
        if score < 0.4:
            return 'low'
        if score < 0.75:
            return 'medium'
        return 'high'


_image_analyzer: ImageAnalyzer | None = None


def get_image_analyzer() -> ImageAnalyzer:
    global _image_analyzer
    if _image_analyzer is None:
        _image_analyzer = ImageAnalyzer()
    return _image_analyzer
