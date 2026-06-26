"""Tests del índice de estafas (la 'R' del RAG).

Verifica la recuperación en cascada (título → subtítulo → descripción), la
insensibilidad a tildes y que el caso del screenshot —estafa de pago por
adelantado— se recupere como coincidencia principal.
"""
from app.services.ai.scam_index import get_scam_index


def test_index_loads_catalog():
    idx = get_scam_index()
    assert len(idx) >= 5


def test_advance_fee_scam_is_top_match():
    # El mensaje del screenshot: "te enviaré 300$ si me envías primero el envío".
    idx = get_scam_index()
    matches = idx.search('hola soy el ing alan te enviare 300 si me envias primero el costo del envio 50')
    assert matches, 'debería recuperar al menos una estafa'
    assert matches[0].entry.id == 'advance-fee'
    assert matches[0].entry.risk_level == 'high'


def test_search_is_accent_insensitive():
    idx = get_scam_index()
    con_tilde = idx.search('me pediste el código de verificación por SMS')
    sin_tilde = idx.search('me pediste el codigo de verificacion por sms')
    assert con_tilde and sin_tilde
    assert con_tilde[0].entry.id == sin_tilde[0].entry.id == 'otp-theft'


def test_bank_smishing_match():
    idx = get_scam_index()
    matches = idx.search('Su cuenta del banco fue bloqueada, verifique sus datos en el enlace')
    assert matches[0].entry.id == 'bank-smishing'


def test_irrelevant_text_returns_no_matches():
    idx = get_scam_index()
    assert idx.search('hola, nos vemos el viernes para almorzar') == []


def test_title_outranks_description():
    # 'premio' aparece en el título de prize-lottery → debe ganarle a entradas
    # donde solo aparecería en descripción.
    idx = get_scam_index()
    matches = idx.search('gané un premio en un sorteo')
    assert matches[0].entry.id == 'prize-lottery'


def test_format_for_prompt_includes_titles():
    idx = get_scam_index()
    matches = idx.search('te envío dinero si pagás el envío primero')
    context = idx.format_for_prompt(matches)
    assert 'Estafa de pago por adelantado' in context
    assert idx.format_for_prompt([]) == ''
