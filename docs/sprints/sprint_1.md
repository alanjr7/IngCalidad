# Sprint 1 — Autenticación y Gestión de Entrada de Mensajes

**Duración:** ~1 semana  
**Estado:** ✅ Completado

## Objetivos

- [x] Backend: modelo `User` (SQLAlchemy)
- [x] Backend: schemas Pydantic para auth (register, login, token, me)
- [x] Backend: `AuthService` con hash bcrypt + JWT
- [x] Backend: endpoints POST /register, POST /login, POST /refresh, GET /me, POST /logout
- [x] Backend: tests unitarios de autenticación (6 casos)
- [x] Flutter: `UserModel` + `AuthTokenModel`
- [x] Flutter: `AuthService` con flutter_secure_storage
- [x] Flutter: `AuthController` (Riverpod StateNotifier)
- [x] Flutter: `LoginView` con validación de formulario
- [x] Flutter: `RegisterView` con validación de contraseña
- [x] Flutter: `HomeView` con accesos rápidos
- [x] Flutter: `SplashScreen` con detección de sesión persistente
- [x] Flutter: Router actualizado con rutas reales

## Criterios de Aceptación Sprint 1

| Criterio | Estado |
|----------|--------|
| Registro de usuario retorna JWT en < 500ms | ✅ |
| Login incorrecto retorna 401 | ✅ |
| Email duplicado retorna 409 | ✅ |
| Sesión persiste en `flutter_secure_storage` hasta logout explícito | ✅ |
| SplashScreen redirige a Home si hay token, a Login si no | ✅ |
| Formularios muestran errores de validación inline | ✅ |

## Flujo de Autenticación

```
SplashScreen (2s)
    │
    ├─ token en storage? ──YES──► HomeView
    │
    └─ NO ──► LoginView
                  │
                  ├─ POST /auth/login → guarda JWT → HomeView
                  │
                  └─ RegisterView → POST /auth/register → guarda JWT → HomeView
```

## Próximo: Sprint 2

- Modelo `Analysis` + esquema en backend
- `AnalizadorTexto`: endpoint POST /analysis/text
- Motor NLP local en Flutter (TFLite BERT pequeño)
- Vista de análisis de texto con copy/paste + share intent
- Gestión de historial local con Drift (SQLite)
- Guardar análisis en historial + vista de historial
