"""Tests de las primitivas de seguridad (hashing y JWT).

Evidencia para el atributo de Seguridad (ISO/IEC 25010): contraseñas cifradas con
bcrypt (nunca en claro) y tokens firmados/validados correctamente.
"""
import pytest

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)


def test_password_is_hashed_not_plaintext():
    hashed = hash_password("supersecreta")
    assert hashed != "supersecreta"
    assert hashed.startswith("$2")  # prefijo de bcrypt
    assert verify_password("supersecreta", hashed)
    assert not verify_password("incorrecta", hashed)


def test_access_token_roundtrip():
    token = create_access_token("user-123")
    payload = decode_token(token)
    assert payload["sub"] == "user-123"


def test_refresh_token_has_type_claim():
    token = create_refresh_token("user-123")
    payload = decode_token(token)
    assert payload["type"] == "refresh"


def test_decode_invalid_token_raises_401():
    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc:
        decode_token("token.basura.invalido")
    assert exc.value.status_code == 401
