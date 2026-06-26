"""Tests de integración del módulo Educación y Dashboard.

Cubre: consejos de seguridad (listado, filtro por categoría, detalle + 404),
estadísticas del dashboard por usuario (con gating de autenticación) y la
exportación de reportes PDF/Excel.
"""
import pytest
from httpx import AsyncClient

SMISHING_TEXT = (
    "Estimado cliente de BBVA, su cuenta fue bloqueada. "
    "Ingrese su contraseña y número de tarjeta URGENTEMENTE en: "
    "http://bbva-seguro.xyz/login"
)


async def _auth_headers(client: AsyncClient, email: str) -> dict:
    resp = await client.post("/api/v1/auth/register", json={
        "email": email,
        "username": email.split("@")[0],
        "password": "secret123",
    })
    assert resp.status_code == 201, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


# ── Consejos de seguridad ────────────────────────────────────
async def test_get_all_tips(client: AsyncClient):
    resp = await client.get("/api/v1/education/tips")
    assert resp.status_code == 200
    tips = resp.json()
    assert len(tips) == 5
    assert all({"id", "category", "title", "content"} <= set(t) for t in tips)


async def test_get_tips_filtered_by_category(client: AsyncClient):
    resp = await client.get("/api/v1/education/tips", params={"category": "smishing"})
    assert resp.status_code == 200
    tips = resp.json()
    assert len(tips) == 1
    assert tips[0]["category"] == "smishing"


async def test_get_tip_by_id(client: AsyncClient):
    resp = await client.get("/api/v1/education/tips/1")
    assert resp.status_code == 200
    assert resp.json()["id"] == 1


async def test_get_tip_not_found(client: AsyncClient):
    resp = await client.get("/api/v1/education/tips/999")
    assert resp.status_code == 404


# ── Dashboard ────────────────────────────────────────────────
async def test_dashboard_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/education/dashboard")
    assert resp.status_code == 401


async def test_dashboard_aggregates_user_analyses(client: AsyncClient):
    headers = await _auth_headers(client, "dash@example.com")
    # Genera un análisis para que el dashboard tenga datos.
    await client.post("/api/v1/analysis/text", json={"text": SMISHING_TEXT}, headers=headers)

    resp = await client.get("/api/v1/education/dashboard", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["total_analyses"] == 1
    assert body["by_risk_level"].get("high") == 1
    assert body["by_type"].get("text") == 1


# ── Exportación de reportes ──────────────────────────────────
async def test_export_pdf(client: AsyncClient):
    pytest.importorskip("reportlab")
    headers = await _auth_headers(client, "pdf@example.com")
    await client.post("/api/v1/analysis/text", json={"text": SMISHING_TEXT}, headers=headers)

    resp = await client.get("/api/v1/education/export/pdf", headers=headers)
    assert resp.status_code == 200
    assert resp.headers["content-type"] == "application/pdf"
    assert resp.content[:4] == b"%PDF"


async def test_export_excel(client: AsyncClient):
    pytest.importorskip("openpyxl")
    headers = await _auth_headers(client, "xls@example.com")
    await client.post("/api/v1/analysis/text", json={"text": SMISHING_TEXT}, headers=headers)

    resp = await client.get("/api/v1/education/export/excel", headers=headers)
    assert resp.status_code == 200
    assert "spreadsheetml" in resp.headers["content-type"]
    assert resp.content[:2] == b"PK"
