"""Pruebas de carga/rendimiento de la API ScamShield con Locust.

Equivalente Python a JMeter (rúbrica 3.9 / 4.2.4 — Tiempo de respuesta).
Mide tiempo de respuesta y throughput bajo usuarios concurrentes sobre los
flujos críticos: análisis de texto, historial y dashboard.

Uso:
    # 1) Levantá la API:
    uvicorn app.main:app --port 8000
    # 2) Corré Locust (UI web en http://localhost:8089):
    locust -f locustfile.py --host http://localhost:8000
    # 3) Headless (50 usuarios, 5/s, 2 min), con reporte HTML:
    locust -f locustfile.py --host http://localhost:8000 \
        --users 50 --spawn-rate 5 --run-time 2m --headless \
        --html reporte_carga.html

Criterios de aceptación (del Plan SQA):
    - Análisis de texto (heurística local): p95 < 800 ms
    - Consultas de historial/dashboard: p95 < 800 ms
"""
import uuid

from locust import HttpUser, between, task

SMISHING = (
    "Estimado cliente de BBVA, su cuenta fue bloqueada. "
    "Ingrese su contraseña y número de tarjeta URGENTEMENTE en: "
    "http://bbva-seguro.xyz/login"
)
SAFE = "Hola, ¿nos vemos el viernes para cenar?"


class ScamShieldUser(HttpUser):
    """Simula un usuario que inicia sesión y analiza mensajes."""

    # Pausa realista entre acciones de un usuario (0.5–2 s).
    wait_time = between(0.5, 2.0)

    def on_start(self):
        """Registra un usuario único y guarda el token para las tareas."""
        email = f"load_{uuid.uuid4().hex[:12]}@example.com"
        resp = self.client.post(
            "/api/v1/auth/register",
            json={"email": email, "username": email.split("@")[0], "password": "secret123"},
            name="POST /auth/register",
        )
        if resp.status_code == 201:
            self.token = resp.json()["access_token"]
        else:
            self.token = None

    @property
    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self.token}"} if self.token else {}

    @task(5)
    def analyze_smishing(self):
        self.client.post(
            "/api/v1/analysis/text",
            json={"text": SMISHING},
            headers=self._headers,
            name="POST /analysis/text (smishing)",
        )

    @task(3)
    def analyze_safe(self):
        self.client.post(
            "/api/v1/analysis/text",
            json={"text": SAFE},
            headers=self._headers,
            name="POST /analysis/text (seguro)",
        )

    @task(2)
    def view_history(self):
        self.client.get(
            "/api/v1/analysis/history",
            headers=self._headers,
            name="GET /analysis/history",
        )

    @task(1)
    def view_dashboard(self):
        self.client.get(
            "/api/v1/education/dashboard",
            headers=self._headers,
            name="GET /education/dashboard",
        )
