# Guía de Pruebas y Aseguramiento de Calidad — ScamShield

Documento índice de todo el sistema de pruebas del proyecto: **qué se prueba,
dónde está cada prueba, con qué herramienta y cómo ejecutarla**. Es el punto de
entrada para la evaluación de Ingeniería de Calidad.

> Stack: **Flutter (Dart, Android)** + **FastAPI (Python 3.11)** + PostgreSQL/SQLite + Groq (IA).
> Todos los resultados de este documento están **medidos por herramientas y son reproducibles**.

---

## 1. Resumen ejecutivo

| Indicador | Valor medido | Meta | Estado |
|-----------|--------------|------|--------|
| Casos de prueba | **135** (108 backend + 27 Flutter) | — | ✅ |
| Cobertura backend | **91.7%** | ≥ 85% | ✅ |
| Cobertura lógica Flutter | **94–100%** | ≥ 85% | ✅ |
| Calidad del detector (F1) | **0.943** | ≥ 0.85 | ✅ |
| Seguridad estática (Bandit) | **0 hallazgos** / 1843 LOC | 0 | ✅ |
| Complejidad ciclomática media | **2.26** (grado A) | ≤ 10 | ✅ |
| Trazabilidad de requisitos | **98%** (43/44) | 100% | ⏳ |

---

## 2. Tipos de prueba y dónde se encuentran

| Tipo de prueba | Ubicación | Herramienta | Nº |
|----------------|-----------|-------------|----|
| **Unitarias (backend)** | [backend/tests/unit/](backend/tests/unit/) | pytest | 64 |
| **Integración (backend)** | [backend/tests/integration/](backend/tests/integration/) | pytest + httpx | 35 |
| **Calidad del modelo ML** | [backend/tests/quality/](backend/tests/quality/) | evaluador propio | 3 |
| **Unitarias / Widget (Flutter)** | [mobile/test/](mobile/test/) | flutter_test | 27 |
| **Seguridad** | unit/integration (ver §6) | pytest + Bandit + pip-audit | 14+ |
| **Carga / rendimiento** | [backend/locustfile.py](backend/locustfile.py) | Locust | manual |

### Detalle de archivos de prueba

**Backend — unitarias** ([backend/tests/unit/](backend/tests/unit/)):
| Archivo | Qué prueba |
|---------|-----------|
| `test_text_analyzer.py` | Detección heurística de patrones (URL, urgencia, credenciales) |
| `test_image_analyzer.py` / `test_image_analyzer_ocr.py` | Análisis de imagen + rama OCR |
| `test_scam_index.py` | Índice RAG de estafas conocidas |
| `test_ai_provider.py` / `test_groq_provider.py` | Proveedor de IA (chat, visión, STT, TTS) sin red |
| `test_auth.py` | Registro, login, `/me` |
| `test_security.py` | bcrypt + JWT (firma/validación) |
| `test_prompt_injection.py` | Defensa anti prompt-injection |
| `test_report_generator.py` | Generación de PDF/Excel |
| `test_health.py` | Health check |

**Backend — integración** ([backend/tests/integration/](backend/tests/integration/)):
| Archivo | Qué prueba |
|---------|-----------|
| `test_analysis.py` | Flujo análisis de texto E2E + persistencia + aislamiento por usuario |
| `test_ai.py` | Chat IA (texto e imagen) + persistencia |
| `test_education.py` | Consejos, dashboard, exportación PDF/Excel |
| `test_auth_flow.py` | Refresh token + logout |
| `test_api_security.py` | Auth gating, token manipulado, inyección SQL |

**Calidad del modelo** ([backend/tests/quality/](backend/tests/quality/)):
| Archivo | Qué prueba |
|---------|-----------|
| `scam_dataset.json` | Dataset etiquetado (52 mensajes scam/safe) |
| `detector_eval.py` | Evaluador: matriz de confusión + precisión/recall/F1 |
| `test_detector_quality.py` | Compuerta: F1 ≥ 0.85, recall ≥ 0.85 |

**Flutter** ([mobile/test/](mobile/test/)):
| Archivo | Qué prueba |
|---------|-----------|
| `core/risk_level_test.dart` / `risk_level_presentation_test.dart` | Clasificación de riesgo + presentación |
| `core/app_constants_test.dart` | Resolución de URL base + criterios de tiempo |
| `usuario/user_model_test.dart` | Serialización de modelos de usuario/token |
| `historial/analysis_result_test.dart` | Mapeo de respuesta del backend |
| `analisis/text_analysis_controller_test.dart` | Estados del controlador (Idle/Success/Error) |
| `analisis/analysis_request_test.dart` | Serialización de la petición |
| `widget/risk_badge_test.dart` / `widget_test.dart` | Render del badge de riesgo |

---

## 3. Cómo ejecutar las pruebas

### Backend (FastAPI)
```bash
cd backend
pip install -r requirements-dev.txt          # deps de test (ligeras, sin TensorFlow)

pytest                                         # todas las pruebas
pytest --cov=app --cov-report=html            # con cobertura → abre htmlcov/index.html
pytest --cov=app --cov-fail-under=85          # con compuerta de cobertura
pytest tests/unit                              # solo unitarias
pytest tests/integration                       # solo integración
```

### Calidad del modelo (matriz de confusión / F1)
```bash
cd backend
python -m tests.quality.detector_eval          # imprime matriz de confusión y métricas
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter test                                   # todas las pruebas
flutter test --coverage                        # genera coverage/lcov.info
flutter analyze                                # análisis estático
```

### Seguridad
```bash
cd backend
bandit -r app -ll                              # análisis estático de seguridad
pip-audit -r requirements-local.txt            # vulnerabilidades en dependencias
```

### Carga / rendimiento
```bash
cd backend
uvicorn app.main:app --port 8000               # 1) levantar API
locust -f locustfile.py --host http://localhost:8000   # 2) UI en http://localhost:8089
```

---

## 4. Herramientas utilizadas

| Categoría | Herramienta | Uso |
|-----------|-------------|-----|
| Pruebas unitarias backend | **pytest**, pytest-asyncio | Lógica de negocio y ML |
| Cliente de pruebas de API | **httpx** (ASGI) | Integración sobre SQLite |
| Cobertura | **pytest-cov** / **lcov** | Backend / Flutter |
| Pruebas Flutter | **flutter_test**, mockito | Modelos, controladores, widgets |
| Análisis estático Python | **ruff**, **radon** | Lint + complejidad ciclomática |
| Análisis estático Dart | **flutter analyze** | Lints del cliente |
| Seguridad (SAST) | **Bandit** | Vulnerabilidades en código |
| Auditoría de dependencias | **pip-audit** | CVEs en librerías |
| Seguridad (DAST) | **OWASP ZAP** | Escaneo dinámico de la API |
| Pruebas de carga | **Locust** | Rendimiento / concurrencia |
| Calidad de ML | Evaluador propio | F1 / matriz de confusión |
| Integración continua | **GitHub Actions** | Ejecuta todo en cada push/PR |

---

## 5. Integración Continua (CI/CD)

Pipeline en [.github/workflows/ci.yml](.github/workflows/ci.yml) — se ejecuta en cada `push` y `pull_request`.

| Job | Qué hace |
|-----|----------|
| `backend-tests` | pytest + cobertura (compuerta ≥85%) + reporte de calidad del detector |
| `mobile-tests` | flutter analyze + flutter test + cobertura |
| `static-analysis` | ruff (lint Python) |
| `security-scan` | Bandit + pip-audit |

Cada job publica **artefactos de evidencia** (cobertura HTML, lcov, reportes) descargables desde la pestaña *Actions*.

---

## 6. Pruebas de seguridad (detalle)

| Escenario | Prueba | Resultado |
|-----------|--------|-----------|
| Acceso sin token | Endpoints protegidos → 401 | ✅ |
| Token manipulado (firma alterada) | → 401 | ✅ |
| Inyección SQL (`' OR '1'='1`, `DROP TABLE`) | ORM parametrizado, tratado como dato | ✅ Seguro |
| Prompt injection | Contenido como dato no confiable, nunca en el system prompt | ✅ |
| Contraseñas | bcrypt + salt, nunca en texto plano | ✅ |
| Dependencias | pip-audit sin CVEs críticos | ✅ |

> **Diferenciador del proyecto:** la **seguridad de IA** (defensa anti prompt-injection
> + validación de la salida del LLM con Pydantic) y la **calidad del modelo** (F1 del
> detector) son controles que el modelo de evaluación tradicional no contempla.

---

## 7. Documentación de calidad (entregables)

| Documento | Contenido |
|-----------|-----------|
| [docs/plan-calidad-SQA.md](docs/plan-calidad-SQA.md) | **Documento principal**: Cap III (SQA IEEE 730), Cap IV (Métricas), Cap V (ISO/IEC 25010) |
| [docs/matriz-trazabilidad.md](docs/matriz-trazabilidad.md) | Requisito → caso de prueba (44 requisitos) |
| [docs/ci-cd.md](docs/ci-cd.md) | Pipeline de CI/CD y cobertura |
| [docs/seguridad-y-carga.md](docs/seguridad-y-carga.md) | Guía de Bandit, pip-audit, OWASP ZAP y Locust |
| [docs/sprints/](docs/sprints/) | Bitácora SCRUM por sprint |

---

## 8. Cómo se mapea a la rúbrica de evaluación

| Punto de la rúbrica | Evidencia en este proyecto |
|---------------------|----------------------------|
| 3.6.1 Verificación de requerimientos | [docs/matriz-trazabilidad.md](docs/matriz-trazabilidad.md) |
| 3.6.2 Revisión de código | ruff, flutter analyze, radon, Bandit |
| 3.6.3 Pruebas unitarias | [backend/tests/unit/](backend/tests/unit/) + [mobile/test/](mobile/test/) |
| 3.6.4 Pruebas de integración | [backend/tests/integration/](backend/tests/integration/) |
| 3.6.7 Pruebas de seguridad | §6 + [docs/seguridad-y-carga.md](docs/seguridad-y-carga.md) |
| 3.6.8 Auditoría ISO/IEC 25010 | [docs/plan-calidad-SQA.md](docs/plan-calidad-SQA.md) Cap. V |
| 4.2.2 Cobertura de pruebas | 91.7% backend (pytest-cov) |
| 4.2.4 Rendimiento | [backend/locustfile.py](backend/locustfile.py) |
| 4.2.5 Mantenibilidad (complejidad) | radon (CC 2.26) |
| 4.2.6 Calidad del producto (ML) | F1 0.943 — [backend/tests/quality/](backend/tests/quality/) |
| 3.9 Herramientas / CI | GitHub Actions ([.github/workflows/ci.yml](.github/workflows/ci.yml)) |
