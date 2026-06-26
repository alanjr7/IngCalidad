import pytest


@pytest.mark.asyncio
async def test_health_check(client):
    response = await client.get('/health')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'ok'
    assert 'version' in data


@pytest.mark.asyncio
async def test_auth_ping(client):
    response = await client.get('/api/v1/auth/ping')
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_analysis_ping(client):
    response = await client.get('/api/v1/analysis/ping')
    assert response.status_code == 200
