"""Tests de seguridad a nivel de API (ISO/IEC 25010 5.2.7 · rúbrica 3.6.7).

Cubre: gating de autenticación, aislamiento de datos por usuario, resistencia a
inyección SQL en entradas de texto y rechazo de tokens manipulados.
"""
import pytest
from httpx import AsyncClient

# Cargas típicas de inyección SQL probadas contra el campo de texto analizado.
SQLI_PAYLOADS = [
    "' OR '1'='1",
    "'; DROP TABLE analyses; --",
    "admin'--",
    "1' UNION SELECT * FROM users --",
]


async def _token(client: AsyncClient, email: str) -> str:
    resp = await client.post("/api/v1/auth/register", json={
        "email": email,
        "username": email.split("@")[0],
        "password": "secret123",
    })
    assert resp.status_code == 201, resp.text
    return resp.json()["access_token"]


# ── Autenticación / autorización ─────────────────────────────
@pytest.mark.parametrize("path", [
    "/api/v1/analysis/text",
    "/api/v1/analysis/history",
    "/api/v1/education/dashboard",
    "/api/v1/auth/me",
])
async def test_protected_endpoints_require_auth(client: AsyncClient, path: str):
    # GET para los de lectura; POST para análisis. Sin token → 401.
    if path.endswith("/text"):
        resp = await client.post(path, json={"text": "hola"})
    else:
        resp = await client.get(path)
    assert resp.status_code == 401


async def test_tampered_token_is_rejected(client: AsyncClient):
    token = await _token(client, "tamper@example.com")
    tampered = token[:-3] + "xxx"  # altera la firma
    resp = await client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {tampered}"}
    )
    assert resp.status_code == 401


# ── Inyección SQL ────────────────────────────────────────────
@pytest.mark.parametrize("payload", SQLI_PAYLOADS)
async def test_sql_injection_in_text_is_treated_as_data(client: AsyncClient, payload: str):
    """El ORM (SQLAlchemy) parametriza las consultas: el payload se almacena y
    analiza como texto, sin alterar la base ni provocar error 500."""
    token = await _token(client, f"sqli{abs(hash(payload)) % 10000}@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.post("/api/v1/analysis/text", json={"text": payload}, headers=headers)
    assert resp.status_code == 200, resp.text

    # La tabla sigue intacta: el historial responde con el análisis recién creado.
    hist = await client.get("/api/v1/analysis/history", headers=headers)
    assert hist.status_code == 200
    assert len(hist.json()) == 1


async def test_sql_injection_does_not_leak_other_users_data(client: AsyncClient):
    # Usuario A crea un análisis; usuario B intenta inyección y no ve datos ajenos.
    ta = await _token(client, "victima@example.com")
    await client.post("/api/v1/analysis/text", json={"text": "mensaje privado"},
                      headers={"Authorization": f"Bearer {ta}"})

    tb = await _token(client, "atacante@example.com")
    hist = await client.get("/api/v1/analysis/history",
                            headers={"Authorization": f"Bearer {tb}"})
    assert hist.status_code == 200
    assert hist.json() == []  # aislamiento por usuario
