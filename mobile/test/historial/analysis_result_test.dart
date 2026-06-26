import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/core/constants/risk_level.dart';
import 'package:scam_detection/packages/historial/models/analysis_result.dart';

void main() {
  group('AnalysisResult.fromJson', () {
    test('mapea correctamente la respuesta del backend', () {
      final json = {
        'id': 'abc-123',
        'analysis_type': 'text',
        'risk_level': 'high',
        'risk_score': 0.92,
        'patterns_found': [
          'Solicitud de credenciales',
          'Lenguaje de urgencia',
        ],
        'processing_ms': 15,
        'created_at': '2024-06-22T10:05:00Z',
      };

      final result = AnalysisResult.fromJson(json);

      expect(result.id, 'abc-123');
      expect(result.type, 'text');
      expect(result.riskLevel, RiskLevel.high);
      expect(result.riskScore, 0.92);
      expect(result.patternsFound, hasLength(2));
      expect(result.processingMs, 15);
      expect(result.createdAt, DateTime.parse('2024-06-22T10:05:00Z'));
    });

    test('acepta listas de patrones vacías y processing_ms nulo', () {
      final json = {
        'analysis_type': 'text',
        'risk_level': 'low',
        'risk_score': 0.1,
        'patterns_found': <String>[],
        'created_at': '2024-06-22T10:05:00Z',
      };

      final result = AnalysisResult.fromJson(json);

      expect(result.riskLevel, RiskLevel.low);
      expect(result.patternsFound, isEmpty);
      expect(result.processingMs, isNull);
      expect(result.id, isNull);
    });
  });
}
