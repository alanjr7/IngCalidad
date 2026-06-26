"""Tests de integración del flujo esencial: análisis de texto E2E.

Cubre: gating por autenticación, clasificación de riesgo, persistencia y
aislamiento del historial por usuario. Corre sobre SQLite en memoria con el
mismo esquema que producción (ver conftest.py).
"""
from httpx import AsyncClient

# Mensaje con múltiples señales de smishing (suplantación + credenciales +
# urgencia + dominio sospechoso) → debe clasificar como riesgo alto.
SMISHING_TEXT = (
    'Estimado cliente de BBVA, su cuenta fue bloqueada. '
    'Ingrese su contraseña y número de tarjeta URGENTEMENTE en: '
    'http://bbva-seguro.xyz/login'
)
SAFE_TEXT = 'Hola, ¿nos vemos el viernes para cenar?'


async def _auth_token(client: AsyncClient, email: str = 'ana@example.com') -> str:
    """Registra un usuario y devuelve su access token."""
    resp = await client.post('/api/v1/auth/register', json={
        'email': email,
        'username': email.split('@')[0],
        'password': 'secret123',
    })
    assert resp.status_code == 201, resp.text
    return resp.json()['access_token']


async def test_analyze_text_requires_auth(client: AsyncClient):
    resp = await client.post('/api/v1/analysis/text', json={'text': SAFE_TEXT})
    assert resp.status_code == 401


async def test_analyze_high_risk_text(client: AsyncClient):
    token = await _auth_token(client)
    resp = await client.post(
        '/api/v1/analysis/text',
        json={'text': SMISHING_TEXT},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data['analysis_type'] == 'text'
    assert data['risk_level'] == 'high'
    assert data['risk_score'] >= 0.75
    assert data['patterns_found'], 'debería detectar al menos un patrón'
    assert data['id']            # persistido con id generado
    assert data['created_at']    # timestamp asignado


async def test_analyze_safe_text_low_risk(client: AsyncClient):
    token = await _auth_token(client, 'safe@example.com')
    resp = await client.post(
        '/api/v1/analysis/text',
        json={'text': SAFE_TEXT},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()['risk_level'] == 'low'


async def test_analyze_empty_text_rejected(client: AsyncClient):
    token = await _auth_token(client, 'empty@example.com')
    resp = await client.post(
        '/api/v1/analysis/text',
        json={'text': '   '},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 422  # validación del schema


async def test_analysis_is_persisted_and_in_history(client: AsyncClient):
    token = await _auth_token(client, 'hist@example.com')
    headers = {'Authorization': f'Bearer {token}'}

    await client.post('/api/v1/analysis/text',
                      json={'text': SMISHING_TEXT}, headers=headers)

    hist = await client.get('/api/v1/analysis/history', headers=headers)
    assert hist.status_code == 200
    items = hist.json()
    assert len(items) == 1
    assert items[0]['risk_level'] == 'high'
    assert items[0]['analysis_type'] == 'text'


async def test_history_is_isolated_per_user(client: AsyncClient):
    t1 = await _auth_token(client, 'user1@example.com')
    t2 = await _auth_token(client, 'user2@example.com')

    await client.post('/api/v1/analysis/text', json={'text': SMISHING_TEXT},
                      headers={'Authorization': f'Bearer {t1}'})

    # El usuario 2 no debe ver los análisis del usuario 1.
    hist2 = await client.get('/api/v1/analysis/history',
                             headers={'Authorization': f'Bearer {t2}'})
    assert hist2.status_code == 200
    assert hist2.json() == []
