# Matriz de Trazabilidad (Requisito → Caso de Prueba)

Vincula cada requisito del sistema con el/los caso(s) de prueba que lo verifican
y su estado. Evidencia para la rúbrica **3.6.1 (Verificación de requerimientos)**
y la trazabilidad exigida por **IEEE 730**.

- **Estado:** ✅ Verificado · ⏳ Parcial · 🔜 Pendiente
- **Convención de rutas:** `backend/tests/...` (pytest) y `mobile/test/...` (flutter test).

---

## Requisitos Funcionales

### Módulo Usuario / Autenticación (RF-AUTH)

| ID | Requisito | Caso(s) de prueba | Estado |
|----|-----------|-------------------|--------|
| RF-AUTH-01 | Registro de usuario devuelve JWT (access + refresh) | `unit/test_auth.py::test_register_success` | ✅ |
| RF-AUTH-02 | Email/username duplicado retorna 409 | `unit/test_auth.py::test_register_duplicate_email` | ✅ |
| RF-AUTH-03 | Login válido retorna token; inválido retorna 401 | `unit/test_auth.py::test_login_success`, `::test_login_wrong_password` | ✅ |
| RF-AUTH-04 | `GET /me` requiere autenticación | `unit/test_auth.py::test_me_requires_auth`, `::test_me_with_token` | ✅ |
| RF-AUTH-05 | Renovación de sesión con refresh token | `integration/test_auth_flow.py::test_refresh_returns_new_tokens` | ✅ |
| RF-AUTH-06 | Refresh rechaza un access token (claim `type`) | `integration/test_auth_flow.py::test_refresh_rejects_access_token` | ✅ |
| RF-AUTH-07 | Logout requiere token y responde 204 | `integration/test_auth_flow.py::test_logout_*` | ✅ |
| RF-AUTH-08 | Contraseña almacenada con bcrypt (no texto plano) | `unit/test_security.py::test_password_is_hashed_not_plaintext` | ✅ |
| RF-AUTH-09 | Modelos `UserModel`/`AuthTokenModel` (de/serialización) | `mobile/test/usuario/user_model_test.dart` | ✅ |

### Módulo Análisis (RF-ANL)

| ID | Requisito | Caso(s) de prueba | Estado |
|----|-----------|-------------------|--------|
| RF-ANL-01 | Análisis de texto requiere autenticación | `integration/test_analysis.py::test_analyze_text_requires_auth` | ✅ |
| RF-ANL-02 | Clasifica smishing como riesgo alto | `integration/test_analysis.py::test_analyze_high_risk_text`; `unit/test_text_analyzer.py::test_credential_request_is_high_risk` | ✅ |
| RF-ANL-03 | Clasifica mensaje legítimo como riesgo bajo | `integration/test_analysis.py::test_analyze_safe_text_low_risk`; `unit/test_text_analyzer.py::test_safe_text_is_low_risk` | ✅ |
| RF-ANL-04 | Detección de patrones (URL acortada, urgencia, dinero, suplantación) | `unit/test_text_analyzer.py::test_shortened_url_raises_score` y otros | ✅ |
| RF-ANL-05 | Texto vacío es rechazado (422) | `integration/test_analysis.py::test_analyze_empty_text_rejected` | ✅ |
| RF-ANL-06 | Análisis de imagen vía OCR + clasificación | `unit/test_image_analyzer.py`, `unit/test_image_analyzer_ocr.py` | ✅ |
| RF-ANL-07 | Controlador de UI mapea estados (Idle/Success/Error) | `mobile/test/analisis/text_analysis_controller_test.dart` | ✅ |
| RF-ANL-08 | Clasificación de nivel de riesgo por umbrales | `mobile/test/core/risk_level_test.dart` | ✅ |

### Módulo Historial (RF-HIST)

| ID | Requisito | Caso(s) de prueba | Estado |
|----|-----------|-------------------|--------|
| RF-HIST-01 | El análisis se persiste y aparece en el historial | `integration/test_analysis.py::test_analysis_is_persisted_and_in_history` | ✅ |
| RF-HIST-02 | El historial está aislado por usuario | `integration/test_analysis.py::test_history_is_isolated_per_user` | ✅ |
| RF-HIST-03 | Mapeo del resultado del backend (`AnalysisResult.fromJson`) | `mobile/test/historial/analysis_result_test.dart` | ✅ |

### Módulo Educativo / Dashboard / Reportes (RF-EDU)

| ID | Requisito | Caso(s) de prueba | Estado |
|----|-----------|-------------------|--------|
| RF-EDU-01 | Listado de consejos de seguridad | `integration/test_education.py::test_get_all_tips` | ✅ |
| RF-EDU-02 | Filtrado de consejos por categoría | `integration/test_education.py::test_get_tips_filtered_by_category` | ✅ |
| RF-EDU-03 | Detalle de consejo + 404 si no existe | `integration/test_education.py::test_get_tip_by_id`, `::test_get_tip_not_found` | ✅ |
| RF-EDU-04 | Dashboard agrega estadísticas por usuario | `integration/test_education.py::test_dashboard_aggregates_user_analyses` | ✅ |
| RF-EDU-05 | Exportación de reporte PDF | `integration/test_education.py::test_export_pdf`; `unit/test_report_generator.py` | ✅ |
| RF-EDU-06 | Exportación de reporte Excel | `integration/test_education.py::test_export_excel`; `unit/test_report_generator.py` | ✅ |

### Módulo IA / Groq (RF-AI)

| ID | Requisito | Caso(s) de prueba | Estado |
|----|-----------|-------------------|--------|
| RF-AI-01 | Chat asistente devuelve veredicto de riesgo | `unit/test_groq_provider.py::test_analyze_message_text` | ✅ |
| RF-AI-02 | Análisis multimodal (texto + imagen) | `unit/test_groq_provider.py::test_analyze_message_with_image_uses_vision_model` | ✅ |
| RF-AI-03 | Transcripción de audio (STT) | `unit/test_groq_provider.py::test_transcribe_strips_text` | ✅ |
| RF-AI-04 | Síntesis de voz (TTS) | `unit/test_groq_provider.py::test_synthesize_returns_wav_bytes` | ✅ |
| RF-AI-05 | Análisis de imagen (visión) con degradación segura | `unit/test_groq_provider.py::test_analyze_image_*` | ✅ |
| RF-AI-06 | Parseo robusto de salida del LLM | `unit/test_ai_provider.py::test_extract_json_*` | ✅ |

---

## Requisitos No Funcionales

| ID | Requisito | Verificación | Estado |
|----|-----------|--------------|--------|
| RNF-SEC-01 | RBAC: endpoints protegidos rechazan acceso sin token (401) | `integration/test_api_security.py::test_protected_endpoints_require_auth` | ✅ |
| RNF-SEC-02 | Tokens manipulados son rechazados | `integration/test_api_security.py::test_tampered_token_is_rejected` | ✅ |
| RNF-SEC-03 | Resistencia a inyección SQL | `integration/test_api_security.py::test_sql_injection_*` | ✅ |
| RNF-SEC-04 | Defensa anti prompt-injection (contenido como dato no confiable) | `unit/test_prompt_injection.py` | ✅ |
| RNF-SEC-05 | Análisis estático de seguridad sin hallazgos | Bandit (job `security-scan`) — 0 hallazgos | ✅ |
| RNF-SEC-06 | Dependencias sin vulnerabilidades conocidas | pip-audit (job `security-scan`) | ✅ |
| RNF-CAL-01 | Calidad del detector: F1 ≥ 0.85, recall ≥ 0.85 | `quality/test_detector_quality.py` (F1=0.943) | ✅ |
| RNF-MNT-01 | Cobertura de pruebas backend ≥ 85% | `pytest --cov` (91.7%) + compuerta `--cov-fail-under=85` | ✅ |
| RNF-MNT-02 | Cobertura lógica de negocio Flutter ≥ 85% | `flutter test --coverage` (94–100% en modelos/lógica) | ✅ |
| RNF-PERF-01 | Análisis de texto local < 3 s | `unit/test_text_analyzer.py::test_processing_time_under_3_seconds` | ✅ |
| RNF-PERF-02 | Tiempo de respuesta de API p95 < 800 ms bajo carga | `backend/locustfile.py` (ejecución manual) | ⏳ |
| RNF-CICD-01 | Integración continua en cada push/PR | GitHub Actions `.github/workflows/ci.yml` | ✅ |

---

## Resumen de cobertura de requisitos

| Categoría | Total | Verificados | % |
|-----------|-------|-------------|---|
| Funcionales | 32 | 32 | 100% |
| No funcionales | 12 | 11 | 92% |
| **Total** | **44** | **43** | **98%** |

> Único pendiente de automatización completa: **RNF-PERF-02** (carga con Locust),
> que hoy se ejecuta de forma manual y se documenta en
> [seguridad-y-carga.md](seguridad-y-carga.md).
