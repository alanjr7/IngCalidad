# Pruebas de Seguridad y de Carga (Evidencia QA)

Evidencia para **ISO/IEC 25010 §5.2.7 (Seguridad)**, **§5.2.4 (Eficiencia de
Desempeño)** y la **rúbrica 3.6.7 / 4.2.4**.

---

## 1. Análisis estático de seguridad — Bandit

Detecta patrones inseguros en el código Python (secretos embebidos, `eval`,
deserialización insegura, etc.).

```bash
cd backend
pip install bandit
bandit -r app -ll        # -ll = solo severidad media/alta
```

**Resultado de línea base:** `No issues identified` sobre 1843 líneas → **0 hallazgos**.

---

## 2. Auditoría de dependencias — pip-audit

Cruza las dependencias contra la base de vulnerabilidades conocidas (CVE/OSV).

```bash
cd backend
pip install pip-audit
pip-audit -r requirements-local.txt --desc
```

Se ejecuta también en el CI (job `security-scan`). Ante un CVE, actualizar la
versión afectada en `requirements*.txt`.

---

## 3. Pruebas de seguridad automatizadas (pytest)

| Prueba | Archivo | Qué valida |
|--------|---------|------------|
| Gating de autenticación | `tests/integration/test_api_security.py` | Endpoints protegidos → 401 sin token |
| Token manipulado | `tests/integration/test_api_security.py` | Firma alterada → 401 |
| Inyección SQL | `tests/integration/test_api_security.py` | Payloads `' OR '1'='1`, `DROP TABLE` tratados como dato (ORM parametrizado) |
| Aislamiento por usuario | `tests/integration/test_api_security.py` | Un usuario no ve datos de otro |
| Anti prompt-injection | `tests/unit/test_prompt_injection.py` | El texto adversario viaja como `user` envuelto, nunca en el `system`; el system prompt tiene la regla inviolable |
| Hashing y JWT | `tests/unit/test_security.py` | bcrypt (no texto plano), firma/validación de tokens |

> **Diferenciador del proyecto:** la defensa **anti prompt-injection** y la
> validación de la salida del LLM con Pydantic son controles de seguridad de IA
> que el modelo de evaluación tradicional (sistema de ventas) no contempla.

---

## 4. Escaneo dinámico — OWASP ZAP (DAST)

Escaneo activo contra la API en ejecución. Requiere la API levantada.

```bash
# 1) Levantar la API
cd backend && uvicorn app.main:app --port 8000

# 2) Baseline scan con ZAP en Docker (en otra terminal)
docker run --rm -t \
  -v "$(pwd)":/zap/wrk/:rw \
  ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t http://host.docker.internal:8000 \
  -r zap_report.html
```

Alternativa por interfaz gráfica: ZAP Desktop → *Automated Scan* → URL
`http://localhost:8000` → revisar Alertas y exportar reporte HTML.

**Checklist de revisión manual (Postman/navegador):**
- [ ] Cabeceras de seguridad (CORS, `Content-Type`).
- [ ] Endpoints de export/dashboard responden 401 sin token.
- [ ] Mensajes de error no filtran stack traces ni SQL.

---

## 5. Pruebas de carga / rendimiento — Locust

Equivalente Python de JMeter. Mide tiempo de respuesta (p50/p95) y throughput.

```bash
# 1) API levantada en :8000
cd backend
pip install locust

# 2a) UI web (recomendado para explorar): http://localhost:8089
locust -f locustfile.py --host http://localhost:8000

# 2b) Headless con reporte HTML (50 usuarios, 5/s, 2 min)
locust -f locustfile.py --host http://localhost:8000 \
    --users 50 --spawn-rate 5 --run-time 2m --headless \
    --html reporte_carga.html
```

**Escenarios simulados** (ver `backend/locustfile.py`): registro + análisis de
texto (smishing/seguro), historial y dashboard, con pesos realistas.

**Criterios de aceptación (Plan SQA):**

| Transacción | Meta p95 |
|-------------|----------|
| Análisis de texto (heurística local) | < 800 ms |
| Historial / dashboard | < 800 ms |
| Análisis con IA (Groq) | < 3 s |

> El módulo de reportes pesados (export PDF/Excel con muchos registros) es el
> candidato a optimización, igual que el "reporte mensual" del modelo de referencia.
