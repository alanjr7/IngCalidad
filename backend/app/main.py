from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
import structlog

from app.core.config import get_settings
from app.core.database import engine, Base
from app.api.v1.router import api_router

settings = get_settings()
logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info('startup', app=settings.app_name, env=settings.environment)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    logger.info('shutdown')
    await engine.dispose()


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    docs_url='/docs' if settings.debug else None,
    redoc_url='/redoc' if settings.debug else None,
    lifespan=lifespan,
)

# ── Middlewares ──────────────────────────────────────────────
cors_kwargs: dict = dict(
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)
# En desarrollo Flutter web sirve la app desde un puerto aleatorio de
# localhost; permitimos cualquiera para no bloquear las llamadas por CORS.
if settings.environment != 'production':
    cors_kwargs['allow_origin_regex'] = r'https?://(localhost|127\.0\.0\.1)(:\d+)?'

app.add_middleware(CORSMiddleware, **cors_kwargs)

if settings.environment == 'production':
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=['*'])

# ── Rutas ────────────────────────────────────────────────────
app.include_router(api_router, prefix='/api/v1')


@app.get('/health', tags=['health'])
async def health_check():
    return {'status': 'ok', 'version': settings.app_version}
