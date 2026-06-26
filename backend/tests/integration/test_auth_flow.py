"""Tests de integración de los flujos de sesión: refresh y logout.

Complementan a test_auth.py (registro/login/me) cubriendo la renovación de
tokens y el cierre de sesión.
"""
from httpx import AsyncClient


async def _register(client: AsyncClient, email: str) -> dict:
    resp = await client.post("/api/v1/auth/register", json={
        "email": email,
        "username": email.split("@")[0],
        "password": "secret123",
    })
    assert resp.status_code == 201, resp.text
    return resp.json()


async def test_refresh_returns_new_tokens(client: AsyncClient):
    tokens = await _register(client, "refresh@example.com")
    resp = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()


async def test_refresh_rejects_access_token(client: AsyncClient):
    # Usar un access token (sin claim type=refresh) debe rechazarse.
    tokens = await _register(client, "badrefresh@example.com")
    resp = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": tokens["access_token"]},
    )
    assert resp.status_code == 401


async def test_logout_requires_auth(client: AsyncClient):
    resp = await client.post("/api/v1/auth/logout")
    assert resp.status_code == 401


async def test_logout_succeeds_with_token(client: AsyncClient):
    tokens = await _register(client, "logout@example.com")
    resp = await client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert resp.status_code == 204
