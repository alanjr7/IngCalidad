"""Tests de la rama OCR del analizador de imágenes.

El OCR real (Tesseract) no está disponible en CI, así que inyectamos fakes en el
módulo para ejercitar la extracción de texto, la detección de QR/URL y el manejo
de errores sin depender del binario de Tesseract.
"""
from types import SimpleNamespace

from app.services.ml import image_analyzer as ia
from app.services.ml.image_analyzer import ImageAnalyzer, get_image_analyzer


def _enable_fake_ocr(monkeypatch, text: str):
    monkeypatch.setattr(ia, "OCR_AVAILABLE", True, raising=False)
    monkeypatch.setattr(ia, "Image", SimpleNamespace(open=lambda _b: object()), raising=False)
    monkeypatch.setattr(
        ia, "pytesseract",
        SimpleNamespace(image_to_string=lambda _img, lang=None: text),
        raising=False,
    )


def test_ocr_extracts_text_and_detects_url(monkeypatch):
    _enable_fake_ocr(
        monkeypatch,
        "Ganaste un premio, ingresá tu contraseña en http://bit.ly/premio URGENTE",
    )
    result = ImageAnalyzer().analyze(b"fake-image-bytes")
    assert result.extracted_text  # se extrajo texto
    assert result.qr_urls and result.qr_urls[0].startswith("http")
    assert any("QR/URL detectado" in p for p in result.patterns_found)
    assert result.risk_score > 0.0


def test_ocr_failure_is_handled(monkeypatch):
    monkeypatch.setattr(ia, "OCR_AVAILABLE", True, raising=False)
    monkeypatch.setattr(ia, "Image", SimpleNamespace(open=lambda _b: object()), raising=False)

    def _boom(_img, lang=None):
        raise RuntimeError("tesseract no encontrado")

    monkeypatch.setattr(ia, "pytesseract", SimpleNamespace(image_to_string=_boom), raising=False)
    result = ImageAnalyzer().analyze(b"fake-image-bytes")
    assert "Error al procesar imagen" in result.patterns_found
    assert result.risk_level == "low"  # sin texto, score 0


def test_score_to_level_thresholds():
    assert ImageAnalyzer._score_to_level(0.1) == "low"
    assert ImageAnalyzer._score_to_level(0.5) == "medium"
    assert ImageAnalyzer._score_to_level(0.9) == "high"


def test_get_image_analyzer_is_singleton():
    assert get_image_analyzer() is get_image_analyzer()
