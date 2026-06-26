# ── Imagen base ligera ───────────────────────────────────────
FROM python:3.11-slim

# Sin .pyc, salida sin buffer, pip sin caché (imagen más chica y rápida)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Tesseract OCR (español + inglés) — única dependencia de sistema.
# Se quitaron libgl1/libglib (eran para opencv, que ya no se instala).
RUN apt-get update && apt-get install -y --no-install-recommends \
        tesseract-ocr \
        tesseract-ocr-spa \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1) Dependencias primero → capa cacheable (no se reinstala si no cambian)
COPY requirements-prod.txt .
RUN pip install -r requirements-prod.txt

# 2) Código de la aplicación
COPY . .

# Usuario no-root por seguridad
RUN addgroup --system app && adduser --system --ingroup app app
USER app

# Render inyecta $PORT; 8000 es el fallback para correr en local.
ENV PORT=8000
EXPOSE 8000

# Shell-form para que ${PORT} se expanda en tiempo de ejecución.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
