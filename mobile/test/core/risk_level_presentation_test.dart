import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/core/constants/risk_level.dart';

void main() {
  group('RiskLevel — presentación (label/color/icono)', () {
    test('cada nivel tiene su etiqueta en español', () {
      expect(RiskLevel.low.label, 'Bajo');
      expect(RiskLevel.medium.label, 'Medio');
      expect(RiskLevel.high.label, 'Alto');
    });

    test('cada nivel tiene un color distintivo', () {
      expect(RiskLevel.low.color, const Color(0xFF22C55E));
      expect(RiskLevel.medium.color, const Color(0xFFF59E0B));
      expect(RiskLevel.high.color, const Color(0xFFEF4444));
    });

    test('cada nivel tiene un color de fondo propio', () {
      expect(RiskLevel.low.backgroundColor, const Color(0xFFDCFCE7));
      expect(RiskLevel.medium.backgroundColor, const Color(0xFFFEF3C7));
      expect(RiskLevel.high.backgroundColor, const Color(0xFFFEE2E2));
    });

    test('cada nivel tiene un icono distinto', () {
      final iconos = {
        RiskLevel.low.icon,
        RiskLevel.medium.icon,
        RiskLevel.high.icon,
      };
      expect(iconos, hasLength(3)); // los tres iconos son distintos
    });
  });
}
