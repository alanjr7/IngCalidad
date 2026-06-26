import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Resuelve la URL base del backend según CÓMO se está ejecutando la app, para
/// que llegue al servidor correcto sin tener que pasar flags a mano:
///
/// - Web / escritorio        → `localhost` (backend local en la misma máquina).
/// - Emulador Android (AVD)  → `10.0.2.2` (alias del host dentro del emulador).
/// - Simulador iOS           → `localhost`.
/// - Dispositivo físico      → backend en Render ([AppConstants.prodApiBaseUrl]),
///                             para que el teléfono funcione desde cualquier red.
///
/// Llamar UNA sola vez en `main()` (después de `ensureInitialized`, antes de
/// `runApp`). Respeta el override por `--dart-define=API_BASE_URL` (útil para
/// apuntar un dispositivo físico a un backend local en la LAN durante el dev).
class NetworkConfig {
  const NetworkConfig._();

  static Future<void> init() async {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      AppConstants.resolvedApiBaseUrl = fromEnv;
      _log(fromEnv, 'dart-define');
      return;
    }

    final url = await _resolveBaseUrl();
    AppConstants.resolvedApiBaseUrl = url;
    _log(url, 'auto');
  }

  /// URL base completa según plataforma. Los entornos locales se arman con
  /// `http://host:puerto/prefijo`; el dispositivo físico usa directamente la
  /// URL de producción (https, sin puerto), que ya incluye el prefijo.
  static Future<String> _resolveBaseUrl() async {
    if (kIsWeb) return _local('localhost');

    final info = DeviceInfoPlugin();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = await info.androidInfo;
        // Físico → Render (producción); emulador AVD → backend local del host.
        return android.isPhysicalDevice
            ? AppConstants.prodApiBaseUrl
            : _local('10.0.2.2');
      case TargetPlatform.iOS:
        final ios = await info.iosInfo;
        // Físico → Render (producción); simulador → backend local.
        return ios.isPhysicalDevice
            ? AppConstants.prodApiBaseUrl
            : _local('localhost');
      default:
        // Windows / macOS / Linux: backend local en la misma máquina.
        return _local('localhost');
    }
  }

  static String _local(String host) =>
      'http://$host:${AppConstants.apiPort}${AppConstants.apiPrefix}';

  static void _log(String url, String how) {
    if (kDebugMode) {
      debugPrint('[NetworkConfig] API base URL = $url  (detectado: $how)');
    }
  }
}
