# Integración Continua y Cobertura (Evidencia QA)

Este documento describe el pipeline de CI/CD y cómo aporta evidencia al
**Plan de Aseguramiento de la Calidad (IEEE 730)** y a las **métricas de calidad**.

## Pipeline (`.github/workflows/ci.yml`)

Se ejecuta en cada `push` y `pull_request` a `main`/`develop`, y manualmente
(`workflow_dispatch`). Tres jobs:

| Job | Qué hace | Herramientas |
|-----|----------|--------------|
| `backend-tests` | Pruebas unitarias + integración con cobertura | pytest, pytest-cov |
| `mobile-tests` | Análisis estático + pruebas + cobertura | flutter analyze, flutter test |
| `static-analysis` | Linter de Python (informativo) | ruff |

Cada job publica **artefactos de evidencia** (reporte HTML de cobertura, `coverage.xml`,
`pytest-report.xml`, `lcov.info`) descargables desde la pestaña *Actions*.

## Cómo reproducir localmente

```bash
# Backend (desde backend/)
pip install -r requirements-dev.txt
pytest --cov=app --cov-report=term-missing --cov-report=html
# Abre htmlcov/index.html

# Mobile (desde mobile/)
flutter pub get
flutter analyze
flutter test --coverage
# Genera coverage/lcov.info
```

## Mapeo a la rúbrica de evaluación

| Punto de la rúbrica | Evidencia que genera el pipeline |
|---------------------|----------------------------------|
| 3.6.2 Revisión de código | `ruff` + `flutter analyze` en cada PR |
| 3.6.3 Pruebas unitarias | Job `backend-tests` / `mobile-tests` en verde |
| 3.9 Herramientas (CI) | GitHub Actions reemplaza a Jenkins del modelo |
| 4.2.2 Cobertura de pruebas | Reporte de cobertura por job |
| 4.3.2 Lead Time QA | Tiempo commit → CI verde, visible en Actions |

## Línea base de cobertura (medida)

### Backend (FastAPI) — toda la lógica de negocio y ML
- **91.5%** con **91 pruebas pasando**. Meta SQA: **≥ 85%** → **cumplida**.
- Evolución: 70.5% (51 pruebas) → 91.5% (91 pruebas) tras reforzar
  `report_generator`, `endpoints/education`, `providers/groq`, `image_analyzer`,
  `core/security` y los flujos de `auth` (refresh/logout).
- La compuerta `--cov-fail-under=85` ya está **activa** en el CI: el pipeline
  falla si la cobertura cae por debajo de la meta.

### Mobile (Flutter) — **27 pruebas pasando**
- **Lógica de negocio: 94–100%** (modelos, clasificación de riesgo, controlador):
  `risk_level` 100%, `user_model` 100%, `analysis_result` 100%,
  `analysis_request` 100%, `text_analysis_controller` 94.7%.
- **Global ~17%**: las *vistas UI* (login, registro, chatbot, dashboard, etc.)
  no se cubren con pruebas unitarias; se validan con *widget tests* y, a futuro,
  *integration tests* (`integration_test`/Patrol). La meta ≥85% aplica a la
  lógica de negocio, no al renderizado de pantallas.

## Próximos ajustes de rigor

- Eliminar `continue-on-error: true` del job `static-analysis` cuando el código
  quede sin hallazgos de `ruff`, para convertirlo en compuerta obligatoria.
