import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'secure_store.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;
  final _store = const SecureStore();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_store, _dio),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Dio get dio => _dio;
}

/// Adjunta el access token a cada request y, ante un 401, intenta renovarlo con
/// el refresh token y reintenta la request original una sola vez.
///
/// Regla de oro: este interceptor JAMÁS debe lanzar ni dejar de avanzar el
/// handler; si el storage falla, la request continúa sin token (→ 401 limpio),
/// nunca colgada. Por eso todo acceso a storage pasa por [SecureStore].
class _AuthInterceptor extends Interceptor {
  final SecureStore _store;
  final Dio _dio;

  _AuthInterceptor(this._store, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _store.read(AppConstants.keyAuthToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final isUnauthorized = err.response?.statusCode == 401;
      // Solo excluimos los endpoints del propio flujo de auth (evita recursión en
      // /auth/refresh y reintentos inútiles en login/register). /auth/me SÍ se renueva.
      final path = err.requestOptions.path;
      final isAuthFlow = path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh');
      final alreadyRetried = err.requestOptions.extra['retried'] == true;

      if (isUnauthorized && !isAuthFlow && !alreadyRetried) {
        final newToken = await _tryRefresh();
        if (newToken != null) {
          // Reintenta la request original con el token renovado (una sola vez).
          final opts = err.requestOptions
            ..headers['Authorization'] = 'Bearer $newToken'
            ..extra['retried'] = true;
          final clone = await _dio.fetch(opts);
          return handler.resolve(clone);
        }
        // No se pudo renovar: sesión vencida. Limpiamos para que el splash
        // redirija a login en el próximo arranque.
        await _clear();
      }
    } catch (e) {
      // Nunca dejamos que un fallo del refresh rompa la cadena: propaga el 401.
    }
    handler.next(err);
  }

  /// Renueva el access token usando el refresh token. Usa un Dio limpio para no
  /// recursar este interceptor. Devuelve el nuevo access token o null.
  Future<String?> _tryRefresh() async {
    final refresh = await _store.read(AppConstants.keyRefreshToken);
    if (refresh == null) return null;
    try {
      final tokenDio = Dio(BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        headers: {'Content-Type': 'application/json'},
      ));
      final res = await tokenDio.post('/auth/refresh', data: {'refresh_token': refresh});
      final data = res.data as Map<String, dynamic>;
      final access = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;
      if (access == null) return null;
      await _store.write(AppConstants.keyAuthToken, access);
      if (newRefresh != null) {
        await _store.write(AppConstants.keyRefreshToken, newRefresh);
      }
      return access;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clear() async {
    await Future.wait([
      _store.delete(AppConstants.keyAuthToken),
      _store.delete(AppConstants.keyRefreshToken),
      _store.delete(AppConstants.keyUserId),
    ]);
  }
}
