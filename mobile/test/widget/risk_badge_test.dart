import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_detection/core/constants/risk_level.dart';
import 'package:scam_detection/shared/widgets/risk_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RiskBadge', () {
    testWidgets('renderiza etiqueta e icono para riesgo bajo', (tester) async {
      await tester.pumpWidget(_wrap(const RiskBadge(level: RiskLevel.low)));
      expect(find.text('Riesgo Bajo'), findsOneWidget);
      expect(find.byIcon(RiskLevel.low.icon), findsOneWidget);
    });

    testWidgets('renderiza etiqueta para riesgo medio', (tester) async {
      await tester.pumpWidget(_wrap(const RiskBadge(level: RiskLevel.medium)));
      expect(find.text('Riesgo Medio'), findsOneWidget);
    });

    testWidgets('la variante large usa un icono más grande', (tester) async {
      await tester.pumpWidget(
        _wrap(const RiskBadge(level: RiskLevel.high, large: true)),
      );
      final icon = tester.widget<Icon>(find.byIcon(RiskLevel.high.icon));
      expect(icon.size, 20); // large: 20 vs normal: 16
      expect(find.text('Riesgo Alto'), findsOneWidget);
    });
  });
}
