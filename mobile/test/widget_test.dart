import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/core/constants/risk_level.dart';
import 'package:scam_detection/shared/widgets/risk_badge.dart';

void main() {
  testWidgets('RiskBadge muestra la etiqueta del nivel de riesgo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RiskBadge(level: RiskLevel.high)),
      ),
    );

    expect(find.text('Riesgo Alto'), findsOneWidget);
    expect(find.byIcon(RiskLevel.high.icon), findsOneWidget);
  });
}
