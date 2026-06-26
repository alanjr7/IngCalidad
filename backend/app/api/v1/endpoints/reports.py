import io
from datetime import datetime
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.core.database import get_db
from app.models.user import User
from app.models.report import AnonymousReport
from app.models.analysis import Analysis
from app.schemas.report import AnonymousReportCreate, AnonymousReportResponse
from app.services.auth_service import get_current_user
from app.services.ml.image_analyzer import get_image_analyzer
from app.schemas.analysis import AnalysisResponse

router = APIRouter()


# ── Análisis de imagen ───────────────────────────────────────

@router.post(
    '/image',
    response_model=AnalysisResponse,
    tags=['Análisis ML'],
    summary='Analizar imagen con OCR + CNN para detectar estafas',
)
async def analyze_image(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if file.content_type not in ('image/jpeg', 'image/png', 'image/webp', 'image/gif'):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail='Solo se admiten imágenes JPG, PNG, WEBP o GIF',
        )

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:  # 10 MB
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail='La imagen no puede superar 10 MB',
        )

    analyzer = get_image_analyzer()
    result = analyzer.analyze(image_bytes)

    analysis = Analysis(
        user_id=current_user.id,
        analysis_type='image',
        risk_level=result.risk_level,
        risk_score=result.risk_score,
        content_hash=result.content_hash,
        patterns_found=result.patterns_found,
        processing_ms=result.processing_ms,
    )
    db.add(analysis)
    await db.flush()

    return AnalysisResponse.model_validate(analysis)


# ── Reporte anónimo ──────────────────────────────────────────

@router.post(
    '/anonymous',
    response_model=AnonymousReportResponse,
    status_code=status.HTTP_201_CREATED,
    summary='Enviar reporte anónimo (sin datos personales)',
)
async def submit_anonymous_report(
    data: AnonymousReportCreate,
    db: AsyncSession = Depends(get_db),
):
    report = AnonymousReport(**data.model_dump())
    db.add(report)
    await db.flush()
    return AnonymousReportResponse.model_validate(report)


# ── Estadísticas globales (para dashboard) ───────────────────

@router.get('/stats', summary='Estadísticas globales de reportes anónimos')
async def get_global_stats(db: AsyncSession = Depends(get_db)):
    total = await db.scalar(select(func.count()).select_from(AnonymousReport))
    by_level = await db.execute(
        select(AnonymousReport.risk_level, func.count())
        .group_by(AnonymousReport.risk_level)
    )
    return {
        'total_reports': total,
        'by_risk_level': {row[0]: row[1] for row in by_level},
    }
