import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/risk_level.dart';
import '../../../shared/services/api_client.dart';

final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return RemoteAiChatService(ref.read(apiClientProvider).dio);
});

/// Un turno previo de la conversación, para dar contexto al asistente.
class ChatTurn {
  final String role; // 'user' | 'assistant'
  final String content;
  const ChatTurn(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Veredicto del asistente de IA: respuesta conversacional + nivel de riesgo
/// + razones + estafas del índice que fundamentaron la respuesta (RAG).
class ChatVerdict {
  final String reply;
  final RiskLevel risk;
  final double? score;
  final List<String> reasons;
  final List<String> sources;

  const ChatVerdict({
    required this.reply,
    required this.risk,
    this.score,
    this.reasons = const [],
    this.sources = const [],
  });
}

/// Contrato del servicio de chat con IA. La inversión de dependencias permite
/// inyectar un fake en los tests del widget sin tocar la red.
///
/// Un turno puede traer una imagen ([imageBytes]) además del texto: en ese caso
/// el contenido se analiza con el modelo de visión, pero el contrato de salida
/// ([ChatVerdict]) es el mismo, así la UI lo renderiza igual.
abstract interface class AiChatService {
  Future<ChatVerdict> chat(
    String message, {
    List<ChatTurn> history,
    Uint8List? imageBytes,
    String? imageName,
  });
}

/// Implementación real: llama a `/ai/chat` (texto, JSON) o a `/ai/chat-image`
/// (imagen + contexto, multipart). Ambos backends comparten Groq + RAG.
class RemoteAiChatService implements AiChatService {
  final Dio _dio;

  RemoteAiChatService(this._dio);

  @override
  Future<ChatVerdict> chat(
    String message, {
    List<ChatTurn> history = const [],
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final Response response;
    if (imageBytes != null) {
      // Multipart: la imagen va como archivo; el historial, serializado en un campo
      // de formulario (multipart no admite cuerpos JSON anidados).
      final form = FormData.fromMap({
        'message': message,
        'history': jsonEncode(history.map((t) => t.toJson()).toList()),
        'file': MultipartFile.fromBytes(imageBytes, filename: imageName ?? 'captura.jpg'),
      });
      response = await _dio.post('/ai/chat-image', data: form);
    } else {
      response = await _dio.post('/ai/chat', data: {
        'message': message,
        'history': history.map((t) => t.toJson()).toList(),
      });
    }
    final data = response.data as Map<String, dynamic>;
    final levelStr = data['risk_level'] as String?;
    return ChatVerdict(
      reply: (data['reply'] as String?)?.trim() ?? '',
      risk: levelStr != null ? RiskLevel.fromString(levelStr) : RiskLevel.low,
      score: (data['risk_score'] as num?)?.toDouble(),
      reasons:
          data['reasons'] != null ? List<String>.from(data['reasons'] as List) : const [],
      sources:
          data['sources'] != null ? List<String>.from(data['sources'] as List) : const [],
    );
  }
}
