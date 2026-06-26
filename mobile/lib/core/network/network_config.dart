import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Resuelve la URL base del backend según CÓMO se está ejecutando la app, para
/// que llegue al servidor correcto sin tener que pasar flags a mano:
///
/// - Web / escritorio        → `localhost` (backend en la misma máquina).
/// - Emulador Android (AVD)  → `10.0.2.2` (alias del host dentro del emulador).
/// - Simulador iOS           → `localhost`.
/// - Dispositivo físico      → IP LAN del PC ([AppConstants.devHostLanIp]); el
///                             teléfono debe estar en la misma red Wi-Fi.
///
/// Llamar UNA sola vez en `main()` (después de `ensureInitialized`, antes de
/// `runApp`). Respeta el override por `--dart-define=API_BASE_URL`.
class NetworkConfig {
  const NetworkConfig._();

  static Future<void> init() async {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      AppConstants.resolvedApiBaseUrl = fromEnv;
      _log(fromEnv, 'dart-define');
      return;
    }

    final host = await _resolveHost();
    final url = 'http://$host:${AppConstants.apiPort}${AppConstants.apiPrefix}';
    AppConstants.resolvedApiBaseUrl = url;
    _log(url, host);
  }

  static Future<String> _resolveHost() async {
    if (kIsWeb) return 'localhost';

    final info = DeviceInfoPlugin();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = await info.androidInfo;
        // Físico → IP LAN del PC; emulador AVD → 10.0.2.2.
        return android.isPhysicalDevice
            ? AppConstants.devHostLanIp
            : '10.0.2.2';
      case TargetPlatform.iOS:
        final ios = await info.iosInfo;
        // Físico → IP LAN del PC; simulador → localhost.
        return ios.isPhysicalDevice ? AppConstants.devHostLanIp : 'localhost';
      default:
        // Windows / macOS / Linux: backend en la misma máquina.
        return 'localhost';
    }
  }

  static void _log(String url, String how) {
    if (kDebugMode) {
      debugPrint('[NetworkConfig] API base URL = $url  (detectado: $how)');
    }
  }
}
