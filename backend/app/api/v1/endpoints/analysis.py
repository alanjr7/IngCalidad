import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.user import User
from app.models.analysis import Analysis
from app.schemas.analysis import TextAnalysisRequest, AnalysisResponse
from app.services.auth_service import get_current_user
from app.services.ml.text_analyzer import get_text_analyzer

router = APIRouter()


@router.get('/ping', summary='Liveness del módulo de análisis')
async def ping():
    return {'status': 'ok'}


@router.post(
    '/text',
    response_model=AnalysisResponse,
    status_code=status.HTTP_200_OK,
    summary='Analizar texto/URL para detectar smishing',
)
async def analyze_text(
    data: TextAnalysisRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    analyzer = get_text_analyzer()
    result = analyzer.analyze(data.text)

    analysis = Analysis(
        user_id=current_user.id,
        analysis_type='text',
        risk_level=result.risk_level,
        risk_score=result.risk_score,
        content_hash=result.content_hash,
        patterns_found=result.patterns_found,
        processing_ms=result.processing_ms,
    )
    db.add(analysis)
    await db.flush()

    return AnalysisResponse.model_validate(analysis)


@router.get(
    '/history',
    response_model=list[AnalysisResponse],
    summary='Obtener historial de análisis del usuario',
)
async def get_history(
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from sqlalchemy import select
    stmt = (
        select(Analysis)
        .where(Analysis.user_id == current_user.id)
        .order_by(Analysis.created_at.desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    return [AnalysisResponse.model_validate(a) for a in result.scalars().all()]
