from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.analysis import Analysis
from app.services.auth_service import get_current_user
from app.models.user import User
from app.services.report_generator import generate_pdf_report, generate_excel_report
from fastapi.responses import StreamingResponse, Response
import io

router = APIRouter()

# Tips hardcoded para MVP; en producción vienen de la tabla security_tips
_TIPS = [
    {
        'id': 1,
        'category': 'smishing',
        'title': '¿Qué es el smishing?',
        'content': 'El smishing usa SMS falsos para robarte datos. Nunca hagas clic en links de mensajes no solicitados.',
        'risk_level': 'high',
    },
    {
        'id': 2,
        'category': 'url',
        'title': 'Identificá URLs sospechosas',
        'content': 'Desconfiá de bit.ly, tinyurl y dominios como .xyz .click .top. Verificá siempre el dominio completo.',
        'risk_level': 'medium',
    },
    {
        'id': 3,
        'category': 'urgencia',
        'title': 'Tácticas de urgencia',
        'content': 'Las estafas crean urgencia: "Tu cuenta se bloqueará en 24hs". Ningún banco real presiona así.',
        'risk_level': 'high',
    },
    {
        'id': 4,
        'category': 'qr',
        'title': 'Codes QR maliciosos',
        'content': 'No escanees QR de fuentes desconocidas. Pueden redirigirte a sitios de phishing.',
        'risk_level': 'medium',
    },
    {
        'id': 5,
        'category': 'identidad',
        'title': 'Suplantación de identidad',
        'content': 'Los estafadores se hacen pasar por bancos, SAT o incluso amigos. Verificá siempre el remitente real.',
        'risk_level': 'high',
    },
]


@router.get('/tips')
async def get_tips(category: str | None = None):
    if category:
        return [t for t in _TIPS if t['category'] == category]
    return _TIPS


@router.get('/tips/{tip_id}')
async def get_tip(tip_id: int):
    tip = next((t for t in _TIPS if t['id'] == tip_id), None)
    if not tip:
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Consejo no encontrado')
    return tip


@router.get('/dashboard')
async def get_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from sqlalchemy import func
    # Estadísticas del usuario actual
    total = await db.scalar(
        select(func.count()).select_from(Analysis).where(Analysis.user_id == current_user.id)
    )
    by_level = await db.execute(
        select(Analysis.risk_level, func.count())
        .where(Analysis.user_id == current_user.id)
        .group_by(Analysis.risk_level)
    )
    by_type = await db.execute(
        select(Analysis.analysis_type, func.count())
        .where(Analysis.user_id == current_user.id)
        .group_by(Analysis.analysis_type)
    )
    return {
        'total_analyses': total or 0,
        'by_risk_level': {row[0]: row[1] for row in by_level},
        'by_type': {row[0]: row[1] for row in by_type},
    }


@router.get('/export/pdf')
async def export_pdf(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = await db.execute(
        select(Analysis).where(Analysis.user_id == current_user.id)
        .order_by(Analysis.created_at.desc()).limit(200)
    )
    data = [
        {
            'created_at': str(a.created_at),
            'analysis_type': a.analysis_type,
            'risk_level': a.risk_level,
            'risk_score': a.risk_score,
            'patterns_found': a.patterns_found,
        }
        for a in rows.scalars().all()
    ]
    pdf_bytes = generate_pdf_report(data, current_user.username)
    return Response(
        content=pdf_bytes,
        media_type='application/pdf',
        headers={'Content-Disposition': f'attachment; filename=scamshield_{current_user.username}.pdf'},
    )


@router.get('/export/excel')
async def export_excel(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = await db.execute(
        select(Analysis).where(Analysis.user_id == current_user.id)
        .order_by(Analysis.created_at.desc()).limit(200)
    )
    data = [
        {
            'created_at': str(a.created_at),
            'analysis_type': a.analysis_type,
            'risk_level': a.risk_level,
            'risk_score': a.risk_score,
            'patterns_found': a.patterns_found,
        }
        for a in rows.scalars().all()
    ]
    excel_bytes = generate_excel_report(data, current_user.username)
    return Response(
        content=excel_bytes,
        media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        headers={'Content-Disposition': f'attachment; filename=scamshield_{current_user.username}.xlsx'},
    )
