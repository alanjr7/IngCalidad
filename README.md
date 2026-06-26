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


----------------------base como funciona ---------------
Flujo de un mensaje a la IA (ShieldAI)
El sistema tiene dos lados: la app Flutter (mobile/) y el backend FastAPI (backend/). El "cerebro" de IA es Groq, y antes de preguntarle al modelo se hace RAG (se buscan estafas parecidas en un catálogo). Te lo sigo paso a paso.

1. El usuario escribe y toca enviar — la pantalla
En chatbot_view.dart, el método _send():

Toma el texto (y/o la imagen adjunta).
Pinta la burbuja del usuario en el chat y muestra el indicador "Analizando amenaza…".
Llama a _analyze(), que arma el historial de turnos previos (últimos 10) y llama al servicio de IA con un timeout de 25 s.
2. El servicio decide a qué endpoint llamar
RemoteAiChatService.chat() elige según haya imagen o no:

Solo texto → POST /ai/chat (JSON con message + history).
Con imagen → POST /ai/chat-image (multipart: el archivo + el historial serializado).
La petición sale por Dio (apiClientProvider), que adjunta automáticamente el token JWT del usuario (sesión autenticada).

3. El backend recibe y valida
En ai.py, el endpoint chat():

Exige usuario autenticado (get_current_user).
Convierte el historial a objetos ChatMessage.
Llama a ai.analyze_message(...) envuelto en _guard, que traduce fallos a códigos HTTP claros (503 si Groq no está configurado, 502 si el proveedor falla).
ai es un AIProvider (un Protocol, contrato en base.py) — esto permite inyectar un fake en los tests sin tocar la red.

4. El corazón: RAG + Groq
En GroqAIProvider.analyze_message() pasan tres cosas:

Recuperar (la R de RAG) — scam_index.search() busca en un catálogo curado de estafas (data/scam_index.json) las 3 más parecidas al mensaje. Es búsqueda léxica ponderada: el título pesa más que el subtítulo, que pesa más que la descripción, y las "frases-gatillo" pesan mucho. No usa embeddings.

Aumentar el prompt — build_assistant_messages() arma la conversación:

system: las reglas de ShieldAI (blindadas contra prompt-injection: el mensaje del estafador va envuelto en delimitadores <<<CONTENIDO_NO_CONFIABLE>>> y marcado como dato, no como orden).
system: el conocimiento de referencia (las estafas recuperadas).
el historial previo.
el mensaje del usuario, envuelto.
Generar — _generate_reply() llama a Groq (llama-3.3-70b para texto, modelo de visión si hay imagen) con temperature=0 (determinista) y exigiendo salida JSON. Esa salida se valida con Pydantic (AssistantReply); si el modelo devuelve basura, se degrada de forma segura.

El resultado es un AssistantResult: reply (texto conversacional) + risk_level + risk_score + reasons + sources (las estafas citadas).

5. Se guarda en el historial y se responde
De vuelta en el endpoint, _persist() guarda el veredicto en la BD (tabla Analysis, guardando solo un hash del mensaje, no el texto) y devuelve un ChatResponse al móvil.

6. La app pinta el veredicto
El servicio convierte la respuesta en un ChatVerdict y _ResultContent lo dibuja: encabezado por color de riesgo (rojo/ámbar/verde), la explicación de la IA, los motivos y "Basado en: …" con las estafas citadas.

Detalle importante: el fallback offline
Si la llamada falla (sin conexión, sesión vencida, timeout, Groq caído), la app no dice "parece seguro". En _analyze() corre una heurística local por palabras clave (busca "contraseña", "urgente", "premio", enlaces…):

Si detecta señales → muestra el veredicto marcado como "Análisis offline limitado".
Si no detecta nada → muestra un error honesto ("No pude completar el análisis"), nunca un falso "seguro".
Resumen en una línea
Usuario escribe → app elige /ai/chat o /ai/chat-image (con token JWT) → backend valida → busca estafas parecidas en el catálogo (RAG) → arma un prompt blindado → Groq responde en JSON → se valida, se guarda en historial y se devuelve → la app pinta el veredicto (o cae a la heurística local si algo falla).

Las variantes (voz e imagen sola) entran al mismo flujo: la nota de voz se transcribe primero con /ai/transcribe (Whisper) y el texto resultante sigue exactamente el mismo camino del chat.
