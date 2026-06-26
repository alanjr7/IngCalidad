# Sprint 0 — Planificación, Investigación y Configuración del Entorno

**Duración:** ~1 semana  
**Estado:** ✅ Completado

## Objetivos

- [x] Definir arquitectura y stack tecnológico
- [x] Crear estructura de carpetas (mobile + backend)
- [x] Configurar Flutter: tema, router, constants, pubspec.yaml
- [x] Configurar Backend: FastAPI, config, security, database
- [x] Docker Compose para entorno local
- [x] Schema inicial PostgreSQL
- [x] Test de humo (health check)
- [x] Documentación de arquitectura (README)

## Criterios de Aceptación Sprint 0

| Criterio | Estado |
|----------|--------|
| Estructura de paquetes definida (usuario, analisis, historial, educativo) | ✅ |
| Docker Compose levanta db + api sin errores | ✅ |
| Health endpoint `/health` retorna 200 | ✅ |
| Tests unitarios base configurados | ✅ |
| Variables de entorno documentadas (.env.example) | ✅ |

## Decisiones Técnicas

| Decisión | Justificación |
|----------|---------------|
| Flutter + Riverpod | State management reactivo, code generation, sin boilerplate |
| GoRouter | Declarativo, compatible con deep linking y sharing intent |
| FastAPI + asyncpg | Performance async nativa, tipado fuerte con Pydantic |
| SQLAlchemy 2.0 async | ORM moderno con soporte async/await |
| Alembic | Migraciones versionadas para PostgreSQL |
| JWT (jose) + bcrypt | Estándar de industria para auth móvil |
| structlog | Logs estructurados JSON para producción en DO |

## Riesgos Identificados

1. **Tamaño de modelos TFLite** — BERT pequeño puede superar 20MB; evaluar cuantización INT8
2. **Latencia OCR en dispositivos bajos** — Tesseract puede ser lento; priorizar ML Kit on-device
3. **Privacidad y GDPR** — Implementar anonimización de hash antes de enviar al servidor

## Próximo: Sprint 1

- Pantalla de Login / Registro (Flutter)
- Endpoints POST /auth/register, POST /auth/login, POST /auth/refresh
- Persistencia de sesión con flutter_secure_storage
- Modelo SQLAlchemy `User` + esquema Pydantic
