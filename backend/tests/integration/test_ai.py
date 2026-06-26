"""Tests de integración de los endpoints /ai con un proveedor de IA FAKE.

Nunca se llama a Groq real: se inyecta `FakeAIProvider` vía dependency_overrides
(mismo patrón de inversión de dependencias del resto del proyecto). Así la suite
es determinista, rápida y sin coste, y valida el cableado HTTP, el gating por
auth, la persistencia en el historial y la degradación a 503.
"""
import pytest
from httpx import AsyncClient

from app.main import app
from app.services.ai import get_ai_provider
from app.services.ai.base import (
    AssistantResult,
    SpeechResult,
    TranscriptionResult,
    VisionResult,
)
from app.services.ai.groq_client import GroqNotConfiguredError


class FakeAIProvider:
    """Implementa el Protocol AIProvider con respuestas fijas."""

    async def analyze_message(self, text, history=None, *, image=None, mime_type=None):
        # Con imagen el turno es multimodal: respondemos como el modelo de visión
        # para que el test distinga ambos caminos por el campo `model`.
        if image is not None:
            return AssistantResult(
                reply='En la captura veo que suplantan a un banco y piden tu clave.',
                risk_level='high',
                risk_score=0.9,
                reasons=['Suplanta a un banco', 'Pide credenciales'],
                sources=['Estafa de pago por adelantado'],
                model='fake-vision',
                processing_ms=18,
            )
        return AssistantResult(
            reply='Parece una estafa: no compartas tus datos.',
            risk_level='high',
            risk_score=0.92,
            reasons=['Solicita credenciales', 'Genera urgencia'],
            sources=['Estafa de pago por adelantado'],
            model='fake-chat',
            processing_ms=12,
        )

    async def transcribe(self, audio, filename, language=None):
        return TranscriptionResult(
            text='Su cuenta fue bloqueada, ingrese su contraseña urgentemente',
            language='es',
            model='fake-whisper',
            processing_ms=20,
        )

    async def synthesize(self, text, voice=None):
        return SpeechResult(
            audio=b'RIFFFAKEWAV', content_type='audio/wav',
            model='fake-tts', processing_ms=15,
        )

    async def analyze_image(self, image_bytes, mime_type):
        return VisionResult(
            risk_level='high', risk_score=0.88,
            reasons=['Suplanta a un banco'], extracted_text='BBVA: verifique su cuenta',
            model='fake-vision', processing_ms=30,
        )


class BrokenAIProvider(FakeAIProvider):
    async def analyze_message(self, text, history=None, *, image=None, mime_type=None):
        raise GroqNotConfiguredError('GROQ_API_KEY no configurada')


@pytest.fixture
def fake_ai():
    app.dependency_overrides[get_ai_provider] = lambda: FakeAIProvider()
    yield
    app.dependency_overrides.pop(get_ai_provider, None)


async def _auth_token(client: AsyncClient, email: str = 'aiuser@example.com') -> str:
    resp = await client.post('/api/v1/auth/register', json={
        'email': email, 'username': email.split('@')[0], 'password': 'secret123',
    })
    assert resp.status_code == 201, resp.text
    return resp.json()['access_token']


async def test_chat_requires_auth(client: AsyncClient, fake_ai):
    resp = await client.post('/api/v1/ai/chat', json={'message': 'hola'})
    assert resp.status_code == 401


async def test_chat_returns_reply_and_verdict(client: AsyncClient, fake_ai):
    token = await _auth_token(client)
    resp = await client.post(
        '/api/v1/ai/chat',
        json={'message': 'Su cuenta BBVA fue bloqueada, ingrese su clave'},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data['risk_level'] == 'high'
    assert data['reply']
    assert data['reasons']
    assert data['sources'] == ['Estafa de pago por adelantado']  # RAG: fuentes citadas
    assert data['model'] == 'fake-chat'


async def test_chat_persists_to_history(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'hist_ai@example.com')
    headers = {'Authorization': f'Bearer {token}'}
    await client.post('/api/v1/ai/chat', json={'message': 'clave urgente'}, headers=headers)

    hist = await client.get('/api/v1/analysis/history', headers=headers)
    assert hist.status_code == 200
    assert len(hist.json()) == 1
    assert hist.json()[0]['risk_level'] == 'high'


async def test_chat_503_when_ai_not_configured(client: AsyncClient):
    app.dependency_overrides[get_ai_provider] = lambda: BrokenAIProvider()
    try:
        token = await _auth_token(client, 'broken@example.com')
        resp = await client.post(
            '/api/v1/ai/chat', json={'message': 'hola'},
            headers={'Authorization': f'Bearer {token}'},
        )
        assert resp.status_code == 503
    finally:
        app.dependency_overrides.pop(get_ai_provider, None)


async def test_chat_image_returns_reply_and_verdict(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'chatimg@example.com')
    resp = await client.post(
        '/api/v1/ai/chat-image',
        data={'message': '¿Esto es seguro?', 'history': '[]'},
        files={'file': ('captura.png', b'\x89PNGfakebytes', 'image/png')},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data['risk_level'] == 'high'
    assert data['reply']
    assert data['reasons']
    assert data['model'] == 'fake-vision'  # se enrutó al camino multimodal


async def test_chat_image_works_without_caption(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'chatimg2@example.com')
    resp = await client.post(
        '/api/v1/ai/chat-image',
        files={'file': ('captura.jpg', b'\xff\xd8\xfffake', 'image/jpeg')},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()['risk_level'] == 'high'


async def test_chat_image_rejects_unsupported_type(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'chatimgbad@example.com')
    resp = await client.post(
        '/api/v1/ai/chat-image',
        files={'file': ('doc.pdf', b'%PDF-1.4', 'application/pdf')},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 415


async def test_chat_image_rejects_invalid_history(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'chatimghist@example.com')
    resp = await client.post(
        '/api/v1/ai/chat-image',
        data={'history': '{not valid json'},
        files={'file': ('captura.png', b'\x89PNGfakebytes', 'image/png')},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 422


async def test_chat_image_persists_to_history(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'chatimghx@example.com')
    headers = {'Authorization': f'Bearer {token}'}
    await client.post(
        '/api/v1/ai/chat-image',
        files={'file': ('captura.png', b'\x89PNGfakebytes', 'image/png')},
        headers=headers,
    )
    hist = await client.get('/api/v1/analysis/history', headers=headers)
    assert hist.status_code == 200
    assert len(hist.json()) == 1
    assert hist.json()[0]['analysis_type'] == 'image'


async def test_transcribe_returns_text_and_heuristic_risk(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'stt@example.com')
    resp = await client.post(
        '/api/v1/ai/transcribe',
        files={'file': ('nota.wav', b'fakeaudiobytes', 'audio/wav')},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert 'contraseña' in data['text'].lower()
    # La heurística local debe marcar riesgo sobre el texto transcrito.
    assert data['risk_level'] in {'low', 'medium', 'high'}
    assert data['model'] == 'fake-whisper'


async def test_speak_returns_wav_bytes(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'tts@example.com')
    resp = await client.post(
        '/api/v1/ai/speak', json={'text': 'Esto parece una estafa'},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    assert resp.headers['content-type'] == 'audio/wav'
    assert resp.content == b'RIFFFAKEWAV'


async def test_vision_returns_verdict(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'vis@example.com')
    resp = await client.post(
        '/api/v1/ai/vision',
        files={'file': ('captura.png', b'\x89PNGfakebytes', 'image/png')},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data['risk_level'] == 'high'
    assert data['extracted_text']
    assert data['model'] == 'fake-vision'


async def test_vision_rejects_unsupported_type(client: AsyncClient, fake_ai):
    token = await _auth_token(client, 'badimg@example.com')
    resp = await client.post(
        '/api/v1/ai/vision',
        files={'file': ('doc.pdf', b'%PDF-1.4', 'application/pdf')},
        headers={'Authorization': f'Bearer {token}'},
    )
    assert resp.status_code == 415
