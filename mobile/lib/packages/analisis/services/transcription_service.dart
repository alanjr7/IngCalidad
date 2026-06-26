import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_client.dart';

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return RemoteTranscriptionService(ref.read(apiClientProvider).dio);
});

/// Contrato del servicio de transcripción de audio (Whisper vía backend).
///
/// Separado de [AiChatService] a propósito: transcribir es una capacidad distinta
/// del chat. El chat de voz primero transcribe con este servicio y luego envía el
/// texto resultante al asistente, de modo que el veredicto (RAG + LLM) es idéntico
/// al de un mensaje escrito.
abstract interface class TranscriptionService {
  /// Sube el audio a `/ai/transcribe` y devuelve el texto reconocido (vacío si
  /// no se entendió nada).
  Future<String> transcribe(Uint8List bytes, String filename);
}

class RemoteTranscriptionService implements TranscriptionService {
  final Dio _dio;

  RemoteTranscriptionService(this._dio);

  @override
  Future<String> transcribe(Uint8List bytes, String filename) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post('/ai/transcribe', data: form);
    final data = response.data as Map<String, dynamic>;
    return (data['text'] as String?)?.trim() ?? '';
  }
}
