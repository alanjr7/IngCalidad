import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/core/constants/app_constants.dart';

void main() {
  group('AppConstants.apiBaseUrl', () {
    tearDown(() => AppConstants.resolvedApiBaseUrl = null);

    test('usa la URL resuelta por NetworkConfig cuando está disponible', () {
      AppConstants.resolvedApiBaseUrl = 'http://192.168.1.50:8000/api/v1';
      expect(AppConstants.apiBaseUrl, 'http://192.168.1.50:8000/api/v1');
    });

    test('cae a un fallback con el puerto y prefijo correctos', () {
      AppConstants.resolvedApiBaseUrl = null;
      expect(AppConstants.apiBaseUrl, contains(':8000'));
      expect(AppConstants.apiBaseUrl, endsWith(AppConstants.apiPrefix));
    });

    test('expone los criterios de aceptación de tiempo de respuesta', () {
      expect(AppConstants.textAnalysisTimeout, const Duration(seconds: 3));
      expect(AppConstants.imageAnalysisTimeout, const Duration(seconds: 5));
    });
  });
}
