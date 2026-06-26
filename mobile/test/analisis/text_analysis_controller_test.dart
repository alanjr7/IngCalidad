import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_detection/core/constants/risk_level.dart';
import 'package:scam_detection/packages/analisis/services/analysis_service.dart';
import 'package:scam_detection/packages/analisis/controllers/text_analysis_controller.dart';
import 'package:scam_detection/packages/historial/models/analysis_result.dart';

/// Fake del servicio: implementa el contrato sin red ni base de datos.
class FakeAnalysisService implements AnalysisService {
  final AnalysisResult? result;
  final Object? error;
  String? lastText;

  FakeAnalysisService({this.result, this.error});

  @override
  Future<AnalysisResult> analyzeText(String text) async {
    lastText = text;
    if (error != null) throw error!;
    return result!;
  }
}

AnalysisResult _highRisk() => AnalysisResult(
      id: '1',
      type: 'text',
      riskLevel: RiskLevel.high,
      riskScore: 0.9,
      patternsFound: const ['Solicitud de credenciales'],
      contentPreview: null,
      processingMs: 12,
      createdAt: DateTime(2024, 6, 22),
    );

/// Crea un contenedor de Riverpod con el servicio falso inyectado.
ProviderContainer _containerWith(FakeAnalysisService fake) {
  final container = ProviderContainer(
    overrides: [analysisServiceProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('TextAnalysisController', () {
    test('el estado inicial es Idle', () {
      final container = _containerWith(FakeAnalysisService(result: _highRisk()));
      final state = container.read(textAnalysisControllerProvider);
      expect(state, isA<TextAnalysisIdle>());
    });

    test('un análisis exitoso emite Success con el resultado del servicio',
        () async {
      final fake = FakeAnalysisService(result: _highRisk());
      final container = _containerWith(fake);

      await container
          .read(textAnalysisControllerProvider.notifier)
          .analyze('ingrese su contraseña ahora');

      final state = container.read(textAnalysisControllerProvider);
      expect(state, isA<TextAnalysisSuccess>());
      expect((state as TextAnalysisSuccess).result.riskLevel, RiskLevel.high);
      expect(fake.lastText, 'ingrese su contraseña ahora');
    });

    test('un error de red se mapea a un mensaje amable', () async {
      final container = _containerWith(
        FakeAnalysisService(error: Exception('SocketException: host')),
      );

      await container
          .read(textAnalysisControllerProvider.notifier)
          .analyze('hola');

      final state = container.read(textAnalysisControllerProvider);
      expect(state, isA<TextAnalysisError>());
      expect((state as TextAnalysisError).message, contains('conexión'));
    });

    test('reset vuelve el estado a Idle', () async {
      final container = _containerWith(FakeAnalysisService(result: _highRisk()));
      final notifier = container.read(textAnalysisControllerProvider.notifier);

      await notifier.analyze('x');
      expect(container.read(textAnalysisControllerProvider),
          isA<TextAnalysisSuccess>());

      notifier.reset();
      expect(container.read(textAnalysisControllerProvider),
          isA<TextAnalysisIdle>());
    });
  });
}
