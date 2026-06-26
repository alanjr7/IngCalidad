import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/core/constants/risk_level.dart';

void main() {
  group('RiskLevel.fromScore', () {
    test('score < 0.4 es bajo', () {
      expect(RiskLevel.fromScore(0.0), RiskLevel.low);
      expect(RiskLevel.fromScore(0.39), RiskLevel.low);
    });

    test('0.4 <= score < 0.75 es medio', () {
      expect(RiskLevel.fromScore(0.4), RiskLevel.medium);
      expect(RiskLevel.fromScore(0.74), RiskLevel.medium);
    });

    test('score >= 0.75 es alto', () {
      expect(RiskLevel.fromScore(0.75), RiskLevel.high);
      expect(RiskLevel.fromScore(1.0), RiskLevel.high);
    });
  });

  group('RiskLevel.fromString', () {
    test('es insensible a mayúsculas', () {
      expect(RiskLevel.fromString('HIGH'), RiskLevel.high);
      expect(RiskLevel.fromString('medium'), RiskLevel.medium);
    });

    test('cae en bajo ante valores desconocidos', () {
      expect(RiskLevel.fromString('desconocido'), RiskLevel.low);
    });
  });
}
