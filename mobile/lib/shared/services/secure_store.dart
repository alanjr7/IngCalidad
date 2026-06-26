import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento de credenciales **resiliente y multiplataforma**.
///
/// En móvil (Android/iOS) usa `flutter_secure_storage`, respaldado por el
/// Keystore/Keychain del sistema operativo, donde funciona de forma fiable.
///
/// En **Flutter web** ese backend cifra con WebCrypto (AES-GCM) guardando la
/// clave AES en `localStorage`. Cuando esa clave queda desincronizada con el
/// dato cifrado —algo habitual tras un hot-restart o un cambio de versión del
/// paquete— `decrypt()` lanza `OperationError`: el token se escribe pero NO se
/// puede volver a leer, así que cada request sale sin `Authorization` (→ 401) y
/// el login "exitoso" deja igual la sesión rota. Además, en web ese cifrado no
/// aporta seguridad real: la clave vive en `localStorage`, junto al dato.
///
/// Por eso en web usamos `shared_preferences` (localStorage plano): elimina el
/// `OperationError` y mantiene la misma superficie de seguridad efectiva.
///
/// Cada operación va envuelta en try/catch: una lectura fallida devuelve `null`
/// y descarta el entry posiblemente corrupto, de modo que un nuevo login lo
/// reescribe limpio. La API pública (read/write/delete) es idéntica en todas las
/// plataformas, así que el resto del código no cambia.
class SecureStore {
  const SecureStore();

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<String?> read(String key) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
      return await _secure.read(key: key);
    } catch (e) {
      debugPrint('SecureStore.read("$key") falló: $e');
      // Entry corrupto (p. ej. OperationError en web): lo descartamos para que
      // el próximo login lo reescriba bien.
      await delete(key);
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
        return;
      }
      await _secure.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStore.write("$key") falló: $e');
    }
  }

  Future<void> delete(String key) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        return;
      }
      await _secure.delete(key: key);
    } catch (e) {
      debugPrint('SecureStore.delete("$key") falló: $e');
    }
  }
}
