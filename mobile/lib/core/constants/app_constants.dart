import 'package:flutter/foundation.dart' show kIsWeb;

abstract class AppConstants {
  static const String appName = 'ScamShield';
  static const String appVersion = '1.0.0';

  // ── API ──────────────────────────────────────────────────────────────
  static const int apiPort = 8000;
  static const String apiPrefix = '/api/v1';

  // Backend desplegado en Render (producción). Es el destino por defecto
  // cuando la app corre en un DISPOSITIVO FÍSICO. Incluye ya el prefijo
  // /api/v1, así que es una URL base completa (no se le agrega host:puerto).
  static const String prodApiBaseUrl = 'https://ingcalidad.onrender.com/api/v1';

  // IP LAN del PC de desarrollo. Se usa SOLO cuando la app corre en un
  // dispositivo FÍSICO (Android/iOS): el teléfono debe estar en la MISMA red
  // Wi-Fi y esta IP tiene que coincidir con la del PC (verificá con `ipconfig`).
  // El emulador NO la usa (usa 10.0.2.2). Todo esto se puede sobreescribir con:
  //   flutter run --dart-define=API_BASE_URL=http://TU_IP:8000/api/v1
  static const String devHostLanIp = '192.168.100.6';

  // URL base efectiva. La resuelve [NetworkConfig.init] al arrancar, según la
  // plataforma y si es emulador o dispositivo físico. Hasta que corra, el
  // getter devuelve un fallback razonable.
  static String? resolvedApiBaseUrl;

  // Prioridad: --dart-define=API_BASE_URL > valor resuelto por NetworkConfig >
  // fallback síncrono (web→localhost, Android→emulador).
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (resolvedApiBaseUrl != null) return resolvedApiBaseUrl!;
    const host = kIsWeb ? 'localhost' : '10.0.2.2';
    return 'http://$host:$apiPort$apiPrefix';
  }

  // 60s para absorber el "cold start" del plan free de Render: el servicio
  // se duerme tras inactividad y puede tardar ~50s en despertar. Con un
  // timeout menor, la PRIMERA request tras inactividad fallaría por timeout.
  static const Duration apiTimeout = Duration(seconds: 60);

  // Tiempos de respuesta objetivo (criterios de aceptación)
  static const Duration textAnalysisTimeout = Duration(seconds: 3);
  static const Duration imageAnalysisTimeout = Duration(seconds: 5);

  // Nombres de tablas SQLite local
  static const String tableAnalysisHistory = 'analysis_history';
  static const String tableUserSession = 'user_session';

  // SharedPreferences keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyOnboardingDone = 'onboarding_done';

  // Rutas nombradas
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeTextAnalysis = '/analysis/text';
  static const String routeImageAnalysis = '/analysis/image';
  static const String routeHistory = '/history';
  static const String routeReport = '/report';
  static const String routeEducation = '/education';
  static const String routeProfile = '/profile';
  static const String routeDashboard = '/dashboard';
}
