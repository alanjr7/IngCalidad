    -- ============================================================
    -- ScamShield — Schema inicial PostgreSQL
    -- Sprint 0: Estructura base de tablas
    -- ============================================================

    -- Extensiones
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- para búsqueda de texto similar

    -- ── Tabla: usuarios ─────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS users (
        id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        email       VARCHAR(255) UNIQUE NOT NULL,
        username    VARCHAR(100) UNIQUE NOT NULL,
        hashed_pw   TEXT NOT NULL,
        is_active   BOOLEAN NOT NULL DEFAULT TRUE,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- ── Tabla: análisis ─────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS analyses (
        id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
        analysis_type   VARCHAR(20) NOT NULL CHECK (analysis_type IN ('text', 'image')),
        risk_level      VARCHAR(10) NOT NULL CHECK (risk_level IN ('low', 'medium', 'high')),
        risk_score      FLOAT NOT NULL CHECK (risk_score BETWEEN 0 AND 1),
        content_hash    TEXT,                   -- hash del contenido analizado (privacidad)
        patterns_found  JSONB NOT NULL DEFAULT '[]',
        processing_ms   INTEGER,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- ── Tabla: reportes anónimos ─────────────────────────────────
    CREATE TABLE IF NOT EXISTS anonymous_reports (
        id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        analysis_type   VARCHAR(20) NOT NULL,
        risk_level      VARCHAR(10) NOT NULL,
        risk_score      FLOAT NOT NULL,
        patterns_found  JSONB NOT NULL DEFAULT '[]',
        region          VARCHAR(10),            -- solo código de país, sin datos personales
        app_version     VARCHAR(20),
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- ── Tabla: consejos de seguridad ────────────────────────────
    CREATE TABLE IF NOT EXISTS security_tips (
        id          SERIAL PRIMARY KEY,
        category    VARCHAR(50) NOT NULL,
        title       TEXT NOT NULL,
        content     TEXT NOT NULL,
        risk_level  VARCHAR(10),
        active      BOOLEAN NOT NULL DEFAULT TRUE,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- ── Índices ──────────────────────────────────────────────────
    CREATE INDEX IF NOT EXISTS idx_analyses_user_id ON analyses(user_id);
    CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON analyses(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_analyses_risk_level ON analyses(risk_level);
    CREATE INDEX IF NOT EXISTS idx_anonymous_reports_created_at ON anonymous_reports(created_at DESC);

    -- ── Datos iniciales: consejos de seguridad ───────────────────
    INSERT INTO security_tips (category, title, content, risk_level) VALUES
    ('smishing', '¿Qué es el smishing?', 'El smishing es una forma de phishing que usa mensajes de texto SMS para engañarte y obtener tus datos personales.', 'high'),
    ('vishing', '¿Qué es el vishing?', 'El vishing usa llamadas de voz falsas para hacerse pasar por bancos o entidades oficiales y robar información.', 'high'),
    ('url', 'Cómo identificar URLs sospechosas', 'Desconfía de enlaces acortados (bit.ly, tinyurl). Verifica siempre el dominio completo antes de hacer clic.', 'medium'),
    ('urgencia', 'Tácticas de urgencia', 'Las estafas suelen generar urgencia: "Tu cuenta será bloqueada en 24hs". Ningún banco legítimo actúa así.', 'high'),
    ('qr', 'Códigos QR maliciosos', 'No escanees QR de fuentes desconocidas. Pueden redirigirte a sitios fraudulentos.', 'medium')
    ON CONFLICT DO NOTHING;
