import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/secure_store.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider).dio);
});

class AuthService {
  final Dio _dio;
  final _store = const SecureStore();

  AuthService(this._dio);

  Future<AuthTokenModel> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'username': username,
      'password': password,
    });
    final tokens = AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    await _persistTokens(tokens);
    return tokens;
  }

  Future<AuthTokenModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final tokens = AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    await _persistTokens(tokens);
    return tokens;
  }

  Future<AuthTokenModel> refreshToken() async {
    final refresh = await _store.read(AppConstants.keyRefreshToken);
    if (refresh == null) throw Exception('No hay refresh token');
    final response = await _dio.post('/auth/refresh', data: {'refresh_token': refresh});
    final tokens = AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    await _persistTokens(tokens);
    return tokens;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await _clearTokens();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _store.read(AppConstants.keyAuthToken);
    return token != null;
  }

  /// Carga el perfil del usuario autenticado. Si el access token está vencido,
  /// el interceptor lo renueva con el refresh token de forma transparente.
  Future<UserModel> me() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> _persistTokens(AuthTokenModel tokens) async {
    await Future.wait([
      _store.write(AppConstants.keyAuthToken, tokens.accessToken),
      _store.write(AppConstants.keyRefreshToken, tokens.refreshToken),
      _store.write(AppConstants.keyUserId, tokens.user.id),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _store.delete(AppConstants.keyAuthToken),
      _store.delete(AppConstants.keyRefreshToken),
      _store.delete(AppConstants.keyUserId),
    ]);
  }
}
