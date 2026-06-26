"""Tests del generador de reportes PDF/Excel (módulo de Reportes).

Verifican que se produzcan binarios válidos (firma de archivo correcta) para los
tres niveles de riesgo, el truncado de filas/patrones y la degradación segura
(RuntimeError) cuando la librería opcional no está instalada.
"""
import pytest

from app.services import report_generator as rg

# Sin reportlab/openpyxl no tiene sentido ejercitar la generación real.
reportlab = pytest.importorskip("reportlab")
openpyxl = pytest.importorskip("openpyxl")


def _analyses(n: int = 3) -> list[dict]:
    niveles = ["low", "medium", "high"]
    return [
        {
            "created_at": "2026-06-20T10:30:00",
            "analysis_type": "text",
            "risk_level": niveles[i % 3],
            "risk_score": 0.1 + (i % 3) * 0.4,
            "patterns_found": ["URL acortada detectada", "Lenguaje de urgencia", "extra"],
        }
        for i in range(n)
    ]


# ── PDF ──────────────────────────────────────────────────────
def test_pdf_report_is_valid_binary():
    data = rg.generate_pdf_report(_analyses(3), "ana")
    assert isinstance(data, bytes)
    assert data[:4] == b"%PDF"  # firma de archivo PDF


def test_pdf_report_handles_empty_history():
    data = rg.generate_pdf_report([], "vacio")
    assert data[:4] == b"%PDF"


def test_pdf_report_caps_at_100_rows():
    # No debe fallar aunque haya más de 100 análisis (la tabla se trunca).
    data = rg.generate_pdf_report(_analyses(120), "muchos")
    assert data[:4] == b"%PDF"


def test_pdf_report_raises_without_reportlab(monkeypatch):
    monkeypatch.setattr(rg, "PDF_AVAILABLE", False)
    with pytest.raises(RuntimeError, match="reportlab"):
        rg.generate_pdf_report(_analyses(), "x")


# ── Excel ────────────────────────────────────────────────────
def test_excel_report_is_valid_xlsx():
    data = rg.generate_excel_report(_analyses(3), "ana")
    assert isinstance(data, bytes)
    assert data[:2] == b"PK"  # xlsx es un ZIP → empieza con 'PK'


def test_excel_report_handles_empty_history():
    data = rg.generate_excel_report([], "vacio")
    assert data[:2] == b"PK"


def test_excel_report_raises_without_openpyxl(monkeypatch):
    monkeypatch.setattr(rg, "EXCEL_AVAILABLE", False)
    with pytest.raises(RuntimeError, match="openpyxl"):
        rg.generate_excel_report(_analyses(), "x")
