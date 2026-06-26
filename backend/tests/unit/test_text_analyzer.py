import pytest
from app.services.ml.text_analyzer import TextAnalyzer

analyzer = TextAnalyzer()


def test_safe_text_is_low_risk():
    result = analyzer.analyze('Hola, ¿cómo estás? ¿Cenamos el viernes?')
    assert result.risk_level == 'low'
    assert result.risk_score < 0.4


def test_shortened_url_raises_score():
    result = analyzer.analyze('Hacé clic aquí para ver tu premio: bit.ly/abc123')
    assert result.risk_score >= 0.3
    assert 'URL acortada detectada' in result.patterns_found


def test_credential_request_is_high_risk():
    result = analyzer.analyze(
        'Estimado cliente, su cuenta fue bloqueada. '
        'Ingrese su contraseña y número de tarjeta en: http://banco-falso.xyz/login'
    )
    assert result.risk_level == 'high'
    assert result.risk_score >= 0.75


def test_identity_impersonation_detected():
    result = analyzer.analyze(
        'BBVA: Detectamos actividad inusual. Confirme sus datos URGENTEMENTE.'
    )
    assert 'Posible suplantación de identidad' in result.patterns_found
    assert 'Lenguaje de urgencia' in result.patterns_found


def test_processing_time_under_3_seconds():
    import time
    start = time.monotonic()
    analyzer.analyze('A' * 5000)  # texto máximo
    elapsed = time.monotonic() - start
    assert elapsed < 3.0, f'Análisis tardó {elapsed:.2f}s (> 3s)'


def test_content_hash_is_sha256():
    result = analyzer.analyze('test')
    assert len(result.content_hash) == 64  # SHA-256 hex


def test_money_request_detected():
    result = analyzer.analyze('Ganaste $50,000 pesos. Transfierí ahora o perderás el premio.')
    assert 'Solicitud de dinero o premio' in result.patterns_found
