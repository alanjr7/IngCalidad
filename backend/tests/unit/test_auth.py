import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    response = await client.post('/api/v1/auth/register', json={
        'email': 'test@example.com',
        'username': 'testuser',
        'password': 'securepass123',
    })
    assert response.status_code == 201
    data = response.json()
    assert 'access_token' in data
    assert 'refresh_token' in data
    assert data['user']['email'] == 'test@example.com'


@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient):
    payload = {'email': 'dup@example.com', 'username': 'user1', 'password': 'pass1234'}
    await client.post('/api/v1/auth/register', json=payload)
    response = await client.post('/api/v1/auth/register', json={
        **payload, 'username': 'user2'
    })
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient):
    await client.post('/api/v1/auth/register', json={
        'email': 'login@example.com',
        'username': 'loginuser',
        'password': 'mypassword1',
    })
    response = await client.post('/api/v1/auth/login', json={
        'email': 'login@example.com',
        'password': 'mypassword1',
    })
    assert response.status_code == 200
    assert 'access_token' in response.json()


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient):
    await client.post('/api/v1/auth/register', json={
        'email': 'wrong@example.com',
        'username': 'wronguser',
        'password': 'correct123',
    })
    response = await client.post('/api/v1/auth/login', json={
        'email': 'wrong@example.com',
        'password': 'wrongpass',
    })
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_requires_auth(client: AsyncClient):
    response = await client.get('/api/v1/auth/me')
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_with_token(client: AsyncClient):
    reg = await client.post('/api/v1/auth/register', json={
        'email': 'me@example.com',
        'username': 'meuser',
        'password': 'mepassword1',
    })
    token = reg.json()['access_token']
    response = await client.get(
        '/api/v1/auth/me',
        headers={'Authorization': f'Bearer {token}'},
    )
    assert response.status_code == 200
    assert response.json()['email'] == 'me@example.com'
