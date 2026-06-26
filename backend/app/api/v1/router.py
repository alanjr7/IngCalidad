from fastapi import APIRouter
from .endpoints import auth, analysis, reports, education, ai

api_router = APIRouter()

api_router.include_router(auth.router, prefix='/auth', tags=['Autenticación'])
api_router.include_router(analysis.router, prefix='/analysis', tags=['Análisis ML'])
api_router.include_router(ai.router, prefix='/ai', tags=['IA (Groq)'])
api_router.include_router(reports.router, prefix='/reports', tags=['Reportes e Imágenes'])
api_router.include_router(education.router, prefix='/education', tags=['Educación y Dashboard'])
