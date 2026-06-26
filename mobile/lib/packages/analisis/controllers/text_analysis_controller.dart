import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analysis_service.dart';
import '../../historial/models/analysis_result.dart';

sealed class TextAnalysisState {
  const TextAnalysisState();
}

class TextAnalysisIdle extends TextAnalysisState {
  const TextAnalysisIdle();
}

class TextAnalysisLoading extends TextAnalysisState {
  const TextAnalysisLoading();
}

class TextAnalysisSuccess extends TextAnalysisState {
  final AnalysisResult result;
  const TextAnalysisSuccess(this.result);
}

class TextAnalysisError extends TextAnalysisState {
  final String message;
  const TextAnalysisError(this.message);
}

class TextAnalysisController extends StateNotifier<TextAnalysisState> {
  final AnalysisService _service;

  TextAnalysisController(this._service) : super(const TextAnalysisIdle());

  Future<void> analyze(String text) async {
    state = const TextAnalysisLoading();
    try {
      final result = await _service.analyzeText(text);
      state = TextAnalysisSuccess(result);
    } catch (e) {
      state = TextAnalysisError(_mapError(e));
    }
  }

  void reset() => state = const TextAnalysisIdle();

  String _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return 'Sin conexión a internet.';
    }
    if (msg.contains('408') || msg.contains('timeout')) {
      return 'El análisis tardó demasiado. Intenta de nuevo.';
    }
    return 'Error al analizar. Intenta de nuevo.';
  }
}

final textAnalysisControllerProvider =
    StateNotifierProvider<TextAnalysisController, TextAnalysisState>((ref) {
  return TextAnalysisController(ref.read(analysisServiceProvider));
});
