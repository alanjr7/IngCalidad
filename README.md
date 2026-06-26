# Mobile Scam Detection App — via Machine Learning

Aplicación Android desarrollada en Flutter para detectar estafas (smishing/vishing) en tiempo real mediante análisis de texto, URLs e imágenes con modelos de ML.

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter (Dart) — Android |
| Backend | Python 3.11 + FastAPI |
| Base de Datos | PostgreSQL 15 (central) + SQLite (local) |
| IA/ML | Groq (LLM, Whisper STT, PlayAI TTS, visión Llama 4) + heurística local; TensorFlow Lite/BERT/CNN/Tesseract a futuro |
| Infraestructura | DigitalOcean + Docker |

## Arquitectura de Paquetes

```
lib/
├── core/           # Configuración global, tema, rutas
├── packages/
│   ├── usuario/    # Autenticación, perfil
│   ├── analisis/   # Motor ML: texto + imagen
│   ├── historial/  # Almacenamiento local SQLite + reportes
│   └── educativo/  # Tips de seguridad, tutoriales
└── shared/         # Widgets y servicios reutilizables
```

## Ciclos SCRUM

| Sprint | Objetivo | Estado |
|--------|----------|--------|
| Sprint 0 | Planificación, entorno y arquitectura base | ✅ En progreso |
| Sprint 1 | Autenticación y gestión de entrada de mensajes | ⏳ Pendiente |
| Sprint 2 | Análisis PLN (texto) + historial local | ⏳ Pendiente |
| Sprint 3 | Análisis de imagen (CNN + OCR) + reportes | ⏳ Pendiente |
| Sprint 4 | Dashboard, PDF/Excel, notificaciones, deploy | ⏳ Pendiente |

## Inicio Rápido

### Prerequisitos
- Flutter SDK >= 3.16
- Python 3.11+
- Docker & Docker Compose
- PostgreSQL 15

### Backend
```bash
cd backend
cp ../.env.example .env
docker-compose up -d db
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

### Con Docker (completo)
```bash
cp .env.example .env
docker-compose up -d
```

## Niveles de Riesgo

- 🟢 **Bajo** — Contenido seguro
- 🟡 **Medio** — Revisar con cautela
- 🔴 **Alto** — Posible estafa, no interactuar

## Privacidad

El análisis heurístico (patrones de texto) se realiza localmente. El **análisis avanzado con IA** (chat, transcripción de audio, voz y visión) se procesa a través de **Groq**, un proveedor externo: el contenido a analizar (mensaje, audio o captura) se envía a sus servidores para inferencia. No se adjuntan metadatos personales ni identificadores de usuario, y los reportes al servidor propio siguen siendo anónimos, pero el contenido analizado **sí sale del dispositivo** cuando se usa IA.

> Si el contenido a analizar pudiera incluir datos sensibles de la víctima (teléfonos, tarjetas, nombres), considerá la opción de redacción de PII antes del envío.

### IA / Groq
- La `GROQ_API_KEY` se configura **solo** por variable de entorno (`.env`), nunca en el repo. Si una key se filtra, **revocala** en https://console.groq.com/keys y generá otra.
- Modelos por defecto (ajustables en `.env`): chat `llama-3.3-70b-versatile`, STT `whisper-large-v3-turbo`, TTS `playai-tts`, visión `llama-4-scout`.
- El contenido a analizar viaja como dato no confiable y aislado del prompt del sistema (defensa contra *prompt injection*); la salida del modelo se valida con esquemas antes de usarse.
