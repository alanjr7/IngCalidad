import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Estado de autenticación
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Controlador
class AuthController extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthController(this._service) : super(const AuthInitial()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    state = const AuthLoading();
    final loggedIn = await _service.isLoggedIn();
    if (!loggedIn) {
      state = const AuthUnauthenticated();
      return;
    }
    try {
      // Hay token guardado: validamos la sesión cargando el perfil. Si el access
      // token venció, el interceptor lo renueva con el refresh token; si tampoco
      // sirve, el backend devuelve 401 y caemos a no-autenticado.
      final user = await _service.me();
      state = AuthAuthenticated(user);
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final tokens = await _service.login(email: email, password: password);
      state = AuthAuthenticated(tokens.user);
    } catch (e) {
      state = AuthError(_mapError(e));
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = const AuthLoading();
    try {
      final tokens = await _service.register(
        email: email,
        username: username,
        password: password,
      );
      state = AuthAuthenticated(tokens.user);
    } catch (e) {
      state = AuthError(_mapError(e));
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthUnauthenticated();
  }

  String _mapError(Object e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('409')) return 'El email ya está registrado.';
      if (msg.contains('401')) return 'Email o contraseña incorrectos.';
      if (msg.contains('SocketException')) return 'Sin conexión a internet.';
    }
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authServiceProvider));
});
