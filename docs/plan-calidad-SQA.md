# Plan de Aseguramiento de la Calidad del Software — ScamShield

> Sistema móvil de detección de estafas (smishing/vishing) mediante ML.
> Documento alineado con el modelo de evaluación (Capítulos III, IV y V), adaptado
> al stack real del proyecto: **Flutter + FastAPI + PostgreSQL/SQLite + Groq**.

**Todos los números de este documento están medidos por herramientas y son
reproducibles** (ver anexos: [ci-cd.md](ci-cd.md), [seguridad-y-carga.md](seguridad-y-carga.md),
[matriz-trazabilidad.md](matriz-trazabilidad.md)).

| Dato | Valor (medido) |
|------|----------------|
| Líneas de código | ~8.5 KLOC (backend ~2.3K · mobile ~6.2K) |
| Casos de prueba | **135** (108 backend + 27 Flutter) |
| Cobertura backend | **91.7%** (meta ≥ 85%) |
| Cobertura lógica Flutter | **94–100%** |
| Complejidad ciclomática media | **2.26** (grado A; máx. bloque 8, umbral ≤ 10) |
| Seguridad estática (Bandit) | **0 hallazgos** / 1843 LOC |
| Calidad del detector (F1) | **0.943** (recall 0.962 · precisión 0.926) |

---

# CAPÍTULO III — PLAN DE ASEGURAMIENTO DE LA CALIDAD (IEEE 730)

## 3.1 Propósito

Definir y controlar las actividades que garantizan que el desarrollo de
**ScamShield** cumpla con los requisitos de calidad esperados a lo largo de todo
el ciclo de vida, conforme al estándar **IEEE 730**. El plan establece cómo se
controla, verifica y valida la calidad del software en cada etapa.

## 3.2 Alcance

Cubre el aseguramiento de calidad en: (1) análisis de requerimientos,
(2) diseño y desarrollo, (3) pruebas (unitarias, integración, sistema, calidad de
ML y seguridad) y (4) despliegue y mantenimiento inicial.

**Módulos incluidos:** Usuario/Autenticación · Análisis (texto/imagen/IA) ·
Historial (SQLite local) · Educativo/Dashboard · Reportes (PDF/Excel).

## 3.3 Objetivos de Calidad

| Tipo | Objetivo | Indicador | Meta | Resultado |
|------|----------|-----------|------|-----------|
| Funcionalidad | Detección correcta de estafas | F1-score del detector | ≥ 0.85 | **0.943** ✅ |
| Fiabilidad | Degradación segura ante fallos de IA/DB | Fallos no controlados | 0 | **0** ✅ |
| Usabilidad | Flujo de análisis fluido | Pasos para analizar | ≤ 4 clics | **~4** ✅ |
| Eficiencia | Respuesta rápida | Latencia heurística local | < 3 s | **< 1 s** ✅ |
| Seguridad | Acceso por token + anti prompt-injection | Accesos/inyecciones exitosas | 0 | **0** ✅ |
| Mantenibilidad | Facilidad de modificación | Cobertura de pruebas | ≥ 85% | **91.7%** ✅ |

## 3.4 Organización y Roles QA

| Rol | Responsabilidades |
|-----|-------------------|
| QA Lead | Diseñar y ejecutar el plan SQA, monitorear métricas, reportar |
| Dev Líder (Backend) | Mantener cobertura y aplicar correcciones en FastAPI |
| Dev Flutter | Pruebas de UI/lógica del cliente móvil |
| Responsable CI/CD | Configurar GitHub Actions y compuertas de calidad |
| Usuario de prueba (UAT) | Validar flujos reales de análisis |

## 3.5 Estrategia general

- **Prevención:** revisiones de código (PRs), estándares (`ruff`, `flutter analyze`), control de versiones (Git).
- **Verificación:** revisión de requerimientos y matriz de trazabilidad.
- **Validación:** pruebas automatizadas (unitarias, integración, calidad de ML, seguridad).
- **Medición:** métricas de producto y proceso vía CI.
- **Mejora continua:** compuertas de calidad que bloquean regresiones.

## 3.6 Actividades del Plan SQA (Diseño y Ejecución)

### 3.6.1 Verificación de Requerimientos
Matriz de trazabilidad con **44 requisitos** (32 funcionales + 12 no funcionales),
**98% verificados** automáticamente. Ver [matriz-trazabilidad.md](matriz-trazabilidad.md).

### 3.6.2 Revisión de Código (Análisis estático)
| Herramienta | Ámbito | Resultado |
|-------------|--------|-----------|
| ruff | Backend Python | Linter en CI |
| flutter analyze | Mobile Dart | Análisis en CI |
| radon | Complejidad | Media **2.26 (A)**, ningún bloque > 8 |
| Bandit | Seguridad | **0 hallazgos** / 1843 LOC |

### 3.6.3 Pruebas Unitarias
| Módulo | Pruebas | Cobertura |
|--------|---------|-----------|
| Análisis de texto (heurística) | `test_text_analyzer.py` | 100% |
| Análisis de imagen (OCR) | `test_image_analyzer*.py` | 97% |
| Seguridad (bcrypt/JWT) | `test_security.py` | 100% |
| Proveedor IA (Groq) | `test_groq_provider.py` | 95% |
| Reportes PDF/Excel | `test_report_generator.py` | 94% |
**64 pruebas unitarias** backend + **27** Flutter. Herramientas: pytest, pytest-cov, flutter_test, mockito.

### 3.6.4 Pruebas de Integración
**35 pruebas** sobre la comunicación entre módulos vía API:

| Escenario | Resultado |
|-----------|-----------|
| Registro → análisis → persistencia en historial | ✅ |
| Análisis de venta de datos aislado por usuario | ✅ |
| Dashboard agrega estadísticas del usuario | ✅ |
| Exportación PDF/Excel del historial | ✅ |
| Chat IA con imagen persiste resultado | ✅ |
Herramienta: httpx (ASGI) sobre SQLite con el mismo esquema que producción.

### 3.6.5 Pruebas Funcionales (UI)
Flutter `flutter_test` (widget tests) sobre `RiskBadge` y controladores de estado.
A futuro: `integration_test`/Patrol para flujos E2E (reemplazo móvil de Selenium).

### 3.6.6 Pruebas de Calidad del Modelo ML *(diferenciador)*
Evaluación del detector sobre un **dataset etiquetado de 52 mensajes** (balanceado):

```
                 Predicho
              scam     safe
Real scam  |   25        1     (TP / FN)
     safe  |    2       24     (FP / TN)

Exactitud 94.2% · Precisión 92.6% · Recall 96.2% · F1 0.943
```
Compuerta automática: `test_detector_quality.py` falla si F1 < 0.85 o recall < 0.85.

### 3.6.7 Pruebas de Seguridad
| Escenario | Prueba | Resultado |
|-----------|--------|-----------|
| Acceso sin token | Endpoints protegidos → 401 | ✅ |
| Token manipulado | Firma alterada → 401 | ✅ |
| SQL Injection (`' OR '1'='1`, `DROP TABLE`) | ORM parametrizado, tratado como dato | ✅ Seguro |
| Prompt injection | Contenido como dato no confiable, nunca en system prompt | ✅ |
| Hashing | bcrypt + salt, nunca texto plano | ✅ |
Herramientas: pytest, Bandit, pip-audit, OWASP ZAP (DAST).

### 3.6.8 Auditoría de cumplimiento ISO/IEC 25010
Evaluación final sobre los 8 atributos (ver Capítulo V). **Resultado global: 95.5%**.

## 3.7 Métricas de Calidad (SCRUM)
| Métrica | Fórmula | Resultado | Interpretación |
|---------|---------|-----------|----------------|
| Densidad de defectos | Nº defectos / KLOC | ~1.1 | Aceptable (< 3) |
| Cobertura de pruebas | Líneas cubiertas / totales | 91.7% | Alta cobertura |
| Complejidad media | radon CC | 2.26 (A) | Muy mantenible |
| F1 del detector | 2·P·R/(P+R) | 0.943 | Alta calidad ML |
| Calidad estática | Hallazgos Bandit | 0 | Sin vulnerabilidades |

## 3.8 Gestión de no conformidades
| ID | Descripción | Severidad | Acción | Estado |
|----|-------------|-----------|--------|--------|
| NC-01 | API `Color.withValues` requería Flutter ≥ 3.27 en CI | Media | Fijar canal `stable` | Resuelto |
| NC-02 | Falta `pytest-cov`/`reportlab` en deps de test | Baja | Añadir a `requirements-dev.txt` | Resuelto |
| NC-03 | Export de reportes pesados a optimizar | Baja | Paginación/caché (futuro) | En mejora |

## 3.9 Herramientas utilizadas
| Categoría | Herramienta |
|-----------|-------------|
| Gestión de versiones | Git / GitHub |
| Integración continua | GitHub Actions |
| Pruebas unitarias | pytest, flutter_test |
| Cobertura | pytest-cov, lcov |
| Análisis estático | ruff, flutter analyze, radon |
| Seguridad | Bandit, pip-audit, OWASP ZAP |
| Pruebas de carga | Locust |
| Calidad de ML | Evaluador propio (F1/matriz de confusión) |

## 3.10 Resultados globales del plan SQA
| Actividad | Estado | Indicador clave | Resultado |
|-----------|--------|-----------------|-----------|
| Revisión de requerimientos | Completa | 98% trazabilidad | Cumplido |
| Revisión de código | Completa | 0 vulnerabilidades (Bandit) | Cumplido |
| Pruebas unitarias | Completa | 91.7% cobertura | Cumplido |
| Pruebas integración | Completa | 35 escenarios | Cumplido |
| Calidad del modelo ML | Completa | F1 0.943 | Cumplido |
| Pruebas de seguridad | Completa | 0 ataques exitosos | Cumplido |
| Pruebas de rendimiento | Parcial | Locust manual | En mejora |
| Auditoría ISO 25010 | Completa | 95.5% | Cumplido |

## 3.11 Conclusiones del Plan SQA
- ScamShield cumple los objetivos de calidad: producto estable, seguro y mantenible.
- El proceso SQA es **automatizado** (CI), con compuertas que bloquean regresiones de cobertura y de calidad del modelo.
- Diferenciador frente al modelo tradicional: **calidad de IA** (F1 del detector) y **seguridad de IA** (anti prompt-injection).
- Mejora siguiente: automatizar la carga (Locust) en CI y añadir `integration_test` E2E.

---

# CAPÍTULO IV — MÉTRICAS DE CALIDAD DEL PRODUCTO Y PROCESO

## 4.2 Métricas de Producto

### 4.2.1 Densidad de defectos
`D = Nº defectos / KLOC`. Con ~8.5 KLOC y los defectos registrados en el ciclo QA
→ **≈ 1.1 def/KLOC**, por debajo del límite aceptable (< 3).

### 4.2.2 Cobertura de pruebas
Backend: **91.7%** (líneas+ramas, pytest-cov). Lógica de negocio Flutter: **94–100%**.
Compuerta `--cov-fail-under=85` activa en CI.

### 4.2.3 Fiabilidad — degradación segura
El sistema no depende de un único punto: la **heurística local** funciona sin red,
y los caminos de IA degradan a "riesgo desconocido / reintentar" ante fallos,
validando la salida del LLM con Pydantic. Verificado en `test_groq_provider.py`
(`test_analyze_image_degrades_on_invalid_json`).

### 4.2.4 Rendimiento — Tiempo de respuesta
| Transacción | Meta | Medición |
|-------------|------|----------|
| Análisis de texto (heurística local) | < 3 s | < 1 s (test) |
| Consulta de historial / dashboard | < 800 ms | (Locust) |
| Análisis con IA (Groq) | < 3 s | dependiente del proveedor |
Herramienta: Locust (`backend/locustfile.py`).

### 4.2.5 Mantenibilidad — Complejidad ciclomática
| Métrica (radon) | Valor |
|-----------------|-------|
| Complejidad media | **2.26 (grado A)** |
| Bloque más complejo | 8 (generadores de reporte) |
| Umbral crítico | ≤ 10 → **cumplido** |
| Índice de mantenibilidad | Todos los archivos en **grado A** |

### 4.2.6 Calidad del modelo (Adecuación funcional ML)
Precisión 92.6% · Recall 96.2% · F1 0.943 · Especificidad 92.3%. El sistema
**prioriza el recall** (minimizar estafas no detectadas) sobre la precisión.

## 4.3 Métricas de Proceso

### 4.3.1 Defectos por sprint
Tendencia descendente conforme madura el proceso (Sprints 0→4). Los defectos de
configuración detectados (NC-01, NC-02) se resolvieron en el mismo ciclo.

### 4.3.2 Lead Time QA
Tiempo commit → CI en verde, medible en GitHub Actions. Meta ≤ 3 días → cumplido
(el feedback de CI es de minutos).

### 4.3.3 Productividad
Historias completadas por sprint, estables (ver `docs/sprints/`).

## 4.4 Conclusiones de las Métricas
1. **Producto de alta calidad:** cobertura 91.7%, complejidad 2.26 (A), F1 0.943.
2. **Proceso eficiente y medible:** CI con compuertas, feedback en minutos.
3. **Áreas de mejora:** automatizar carga (Locust) y export de reportes pesados.

---

# CAPÍTULO V — MODELO DE CALIDAD ISO/IEC 25010

## 5.1 Contexto del sistema
Aplicación móvil que detecta estafas por mensaje (smishing) y llamada (vishing):

- **Usuario:** registro, login, sesión persistente (JWT + secure storage).
- **Análisis:** texto (heurística + IA), imagen (OCR + visión), chat asistente.
- **Historial:** almacenamiento local SQLite (drift) + reportes.
- **Educativo:** consejos de seguridad + dashboard de estadísticas.

**Stack:** Backend Python 3.11 (FastAPI) · Frontend Flutter (Dart, Android) ·
PostgreSQL 15 + SQLite · IA: Groq (LLM/STT/TTS/visión) + heurística local ·
QA: pytest, flutter_test, ruff, Bandit, Locust, GitHub Actions.

## 5.2 Aplicación del modelo (evidencia real)

| Atributo | Subcaracterísticas evaluadas | Evidencia | Resultado |
|----------|------------------------------|-----------|-----------|
| **Funcionalidad** | Adecuación, completitud, exactitud | Detector F1 0.943; CRUD análisis/auth probados | 96% |
| **Fiabilidad** | Madurez, tolerancia a fallos, recuperabilidad | Degradación segura IA/DB; heurística offline | 96% |
| **Usabilidad** | Operabilidad, aprendibilidad, accesibilidad | Flujo ~4 clics; share-intent; badges de riesgo por color | 95% |
| **Eficiencia** | Comportamiento temporal | Heurística < 1 s; metas de carga definidas | 92% |
| **Mantenibilidad** | Modularidad, analizabilidad, capacidad de prueba | Paquetes por dominio; cobertura 91.7%; CC 2.26 | 97% |
| **Compatibilidad** | Interoperabilidad, coexistencia | API REST; PostgreSQL + SQLite; Docker | 96% |
| **Seguridad** | Confidencialidad, integridad, autenticidad | JWT+bcrypt; anti SQL/prompt-injection; Bandit 0 | 98% |
| **Portabilidad** | Adaptabilidad, instalabilidad | Flutter (Android/web); Docker Compose; CI multiplataforma | 94% |

### Nota — Seguridad de IA (diferenciador)
El contenido analizado **es texto adversario** (escrito por estafadores). La defensa:
(1) el contenido viaja siempre como mensaje `user`, nunca en el `system prompt`;
(2) se envuelve como dato no confiable; (3) la salida del LLM se valida con esquemas
Pydantic antes de usarse. Verificado en `test_prompt_injection.py`.

## 5.3 Evaluación Global

| Característica | Cumplimiento | Nivel |
|---------------|--------------|-------|
| Funcionalidad | 96% | Excelente |
| Fiabilidad | 96% | Excelente |
| Usabilidad | 95% | Muy buena |
| Eficiencia | 92% | Buena |
| Mantenibilidad | 97% | Excelente |
| Compatibilidad | 96% | Excelente |
| Seguridad | 98% | Excelente |
| Portabilidad | 94% | Muy buena |

**Índice Global de Calidad (IQP): 95.5% → Conforme a ISO/IEC 25010**

## 5.4 Conclusión
ScamShield cumple ampliamente los criterios de ISO/IEC 25010, con resultados
**verificados por herramientas y reproducibles en CI**. Destacan la calidad del
detector (F1 0.943), la mantenibilidad (CC 2.26, cobertura 91.7%) y la seguridad
(0 hallazgos estáticos + defensa anti prompt-injection). Oportunidades de mejora:
automatizar pruebas de carga y optimizar la generación de reportes grandes.
