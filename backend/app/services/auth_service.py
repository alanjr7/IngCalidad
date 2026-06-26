import uuid
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.models.user import User
from app.schemas.user import UserRegisterRequest, TokenResponse, UserResponse

oauth2_scheme = OAuth2PasswordBearer(tokenUrl='/api/v1/auth/login')


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register(self, data: UserRegisterRequest) -> TokenResponse:
        existing = await self.db.scalar(
            select(User).where(
                or_(User.email == data.email, User.username == data.username)
            )
        )
        if existing:
            detail = (
                'El email ya está registrado'
                if existing.email == data.email
                else 'El nombre de usuario ya está en uso'
            )
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=detail)

        user = User(
            email=data.email,
            username=data.username,
            hashed_pw=hash_password(data.password),
        )
        self.db.add(user)
        try:
            await self.db.flush()
        except IntegrityError:
            # Salvaguarda ante condición de carrera entre el chequeo y el insert:
            # otra petición pudo registrar el mismo email/username en paralelo.
            # get_db hace rollback al propagarse la excepción.
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail='El email o el nombre de usuario ya están en uso',
            )

        return self._build_token_response(user)

    async def login(self, email: str, password: str) -> TokenResponse:
        user = await self.db.scalar(select(User).where(User.email == email))
        if not user or not verify_password(password, user.hashed_pw):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail='Credenciales inválidas',
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail='Cuenta desactivada',
            )
        return self._build_token_response(user)

    async def refresh(self, refresh_token: str) -> TokenResponse:
        payload = decode_token(refresh_token)
        if payload.get('type') != 'refresh':
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail='Token de refresh inválido',
            )
        user_id = uuid.UUID(payload['sub'])
        user = await self.db.get(User, user_id)
        if not user or not user.is_active:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Usuario no encontrado')
        return self._build_token_response(user)

    def _build_token_response(self, user: User) -> TokenResponse:
        return TokenResponse(
            access_token=create_access_token(str(user.id)),
            refresh_token=create_refresh_token(str(user.id)),
            user=UserResponse.model_validate(user),
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_token(token)
    user_id = uuid.UUID(payload['sub'])
    user = await db.get(User, user_id)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Usuario no encontrado o inactivo',
        )
    return user
