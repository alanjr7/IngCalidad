import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Float, Integer, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Analysis(Base):
    __tablename__ = 'analyses'

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    # UUID genérico (cross-dialecto): UUID nativo en Postgres, CHAR(32) en SQLite.
    # Así los tests corren sobre SQLite en memoria con el mismo esquema que prod.
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey('users.id', ondelete='SET NULL'), nullable=True
    )
    analysis_type: Mapped[str] = mapped_column(String(20), nullable=False)  # 'text' | 'image'
    risk_level: Mapped[str] = mapped_column(String(10), nullable=False)     # 'low'|'medium'|'high'
    risk_score: Mapped[float] = mapped_column(Float, nullable=False)
    content_hash: Mapped[str | None] = mapped_column(String, nullable=True)
    patterns_found: Mapped[list] = mapped_column(JSON, default=list)
    processing_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
