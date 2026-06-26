import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_client.dart';
import '../../historial/models/analysis_result.dart';
import '../../historial/services/local_history_service.dart';

final analysisServiceProvider = Provider<AnalysisService>((ref) {
  return RemoteAnalysisService(
    ref.read(apiClientProvider).dio,
    ref.read(localHistoryServiceProvider),
  );
});

/// Contrato del servicio de análisis. La inversión de dependencias permite
/// inyectar un fake en los tests del controller sin tocar red ni base de datos.
abstract interface class AnalysisService {
  Future<AnalysisResult> analyzeText(String text);
}

/// Implementación real: llama al backend y persiste el resultado en el
/// historial local del dispositivo.
class RemoteAnalysisService implements AnalysisService {
  final Dio _dio;
  final LocalHistoryService _history;

  RemoteAnalysisService(this._dio, this._history);

  @override
  Future<AnalysisResult> analyzeText(String text) async {
    final response = await _dio.post('/analysis/text', data: {'text': text});
    final result = AnalysisResult.fromJson(response.data as Map<String, dynamic>);
    // Vista previa: primeros 100 chars para el historial local
    final preview = text.length > 100 ? '${text.substring(0, 100)}…' : text;
    final withPreview = AnalysisResult(
      id: result.id,
      type: result.type,
      riskLevel: result.riskLevel,
      riskScore: result.riskScore,
      patternsFound: result.patternsFound,
      contentPreview: preview,
      processingMs: result.processingMs,
      createdAt: result.createdAt,
    );
    await _history.save(withPreview);
    return withPreview;
  }
}
