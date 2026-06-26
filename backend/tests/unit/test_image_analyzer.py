import pytest
from app.services.ml.image_analyzer import ImageAnalyzer
import time


def _dummy_png() -> bytes:
    """PNG válido mínimo (1x1 px rojo) para pruebas sin OCR real."""
    return (
        b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01'
        b'\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00'
        b'\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82'
    )


def test_analysis_returns_result():
    analyzer = ImageAnalyzer()
    result = analyzer.analyze(_dummy_png())
    assert result.risk_level in ('low', 'medium', 'high')
    assert 0.0 <= result.risk_score <= 1.0


def test_processing_time_under_5_seconds():
    analyzer = ImageAnalyzer()
    start = time.monotonic()
    analyzer.analyze(_dummy_png())
    elapsed = time.monotonic() - start
    assert elapsed < 5.0, f'Análisis de imagen tardó {elapsed:.2f}s (> 5s)'


def test_content_hash_sha256():
    analyzer = ImageAnalyzer()
    result = analyzer.analyze(_dummy_png())
    assert len(result.content_hash) == 64
