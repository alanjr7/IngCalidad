from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        case_sensitive=False,
        extra='ignore',
    )

    # App
    app_name: str = 'ScamShield API'
    app_version: str = '1.0.0'
    environment: str = 'development'
    debug: bool = False

    # Base de Datos
    postgres_host: str = 'localhost'
    postgres_port: int = 5432
    postgres_db: str = 'scam_detection_db'
    postgres_user: str = 'scam_user'
    postgres_password: str = 'change_me'

    @property
    def database_url(self) -> str:
        return (
            f'postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}'
            f'@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}'
        )

    @property
    def database_url_sync(self) -> str:
        return (
            f'postgresql://{self.postgres_user}:{self.postgres_password}'
            f'@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}'
        )

    # Auth JWT
    api_secret_key: str = 'dev_secret_key_change_in_production'
    api_algorithm: str = 'HS256'
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # CORS
    cors_origins: list[str] = ['http://localhost:3000']

    # ML Models
    text_model_path: str = 'ml_models/text/bert_small_smishing.tflite'
    image_model_path: str = 'ml_models/image/cnn_scam_detector.tflite'
    confidence_threshold_low: float = 0.4
    confidence_threshold_high: float = 0.75

    # OCR
    tesseract_path: str = '/usr/bin/tesseract'

    # ── IA / Groq ────────────────────────────────────────────
    # La API key SOLO se toma del entorno (.env), nunca se versiona.
    groq_api_key: str = ''
    groq_chat_model: str = 'llama-3.3-70b-versatile'
    groq_vision_model: str = 'meta-llama/llama-4-scout-17b-16e-instruct'
    groq_transcription_model: str = 'whisper-large-v3-turbo'
    groq_tts_model: str = 'playai-tts'
    groq_tts_voice: str = 'Fritz-PlayAI'
    groq_timeout_seconds: float = 30.0
    groq_max_retries: int = 2
    groq_max_output_tokens: int = 1024


@lru_cache
def get_settings() -> Settings:
    return Settings()
