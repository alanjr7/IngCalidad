import 'package:flutter/material.dart';

enum RiskLevel {
  low,
  medium,
  high;

  String get label {
    return switch (this) {
      RiskLevel.low => 'Bajo',
      RiskLevel.medium => 'Medio',
      RiskLevel.high => 'Alto',
    };
  }

  Color get color {
    return switch (this) {
      RiskLevel.low => const Color(0xFF22C55E),    // verde
      RiskLevel.medium => const Color(0xFFF59E0B), // amarillo
      RiskLevel.high => const Color(0xFFEF4444),   // rojo
    };
  }

  Color get backgroundColor {
    return switch (this) {
      RiskLevel.low => const Color(0xFFDCFCE7),
      RiskLevel.medium => const Color(0xFFFEF3C7),
      RiskLevel.high => const Color(0xFFFEE2E2),
    };
  }

  IconData get icon {
    return switch (this) {
      RiskLevel.low => Icons.check_circle_outline,
      RiskLevel.medium => Icons.warning_amber_outlined,
      RiskLevel.high => Icons.dangerous_outlined,
    };
  }

  static RiskLevel fromScore(double score) {
    if (score < 0.4) return RiskLevel.low;
    if (score < 0.75) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static RiskLevel fromString(String value) {
    return RiskLevel.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RiskLevel.low,
    );
  }
}
