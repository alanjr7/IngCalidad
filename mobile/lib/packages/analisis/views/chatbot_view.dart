import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/theme/app_theme.dart';
import '../services/ai_chat_service.dart';
import '../services/transcription_service.dart';

/// Pestaña principal "Asistente" — interfaz de chat ShieldAI Assistant.
///
/// Reproduce el mockup: burbujas de chat, indicador "Analizando amenaza…"
/// y respuestas con veredicto de riesgo. Cada mensaje del usuario se analiza
/// con el servicio real ([analysisServiceProvider]); si el backend no está
/// disponible, cae a una heurística local por palabras clave para que el
/// asistente siempre responda.
class ChatbotView extends ConsumerStatefulWidget {
  const ChatbotView({super.key});

  @override
  ConsumerState<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends ConsumerState<ChatbotView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final List<_Msg> _messages = [];
  bool _analyzing = false;

  // Imagen pendiente de enviar (adjunta antes de pulsar enviar), estilo foto+caption.
  Uint8List? _pendingBytes;
  String? _pendingName;
  final _picker = ImagePicker();

  // Grabación de notas de voz.
  final _recorder = AudioRecorder();
  bool _recording = false;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;

  static const _aiBubble = Color(0xFFEAE7F2);

  @override
  void initState() {
    super.initState();
    // El botón de acción alterna entre micrófono y enviar según haya texto/imagen.
    _input.addListener(_onInputChanged);
    _messages.add(_Msg.ai(
      '¡Hola! Soy tu asistente de seguridad. Pegá un mensaje sospechoso, '
      'subí una captura o mandame una nota de voz y reviso si es una estafa. '
      '¿En qué te ayudo?',
    ));
  }

  void _onInputChanged() => setState(() {});

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final bytes = _pendingBytes;
    final name = _pendingName;
    // Se puede enviar con texto, con imagen, o con ambos; nunca vacío.
    if ((text.isEmpty && bytes == null) || _analyzing) return;
    setState(() {
      _messages.add(_Msg.user(text, imageBytes: bytes, imageName: name));
      _input.clear();
      _pendingBytes = null;
      _pendingName = null;
      _analyzing = true;
    });
    _scrollToBottom();

    final outcome = await _analyze(text, imageBytes: bytes, imageName: name);
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      if (outcome.verdict != null) {
        _messages.add(_Msg.result(outcome.verdict!));
      } else {
        _messages.add(_Msg.error(outcome.error!));
      }
    });
    _scrollToBottom();
  }

  Future<_Outcome> _analyze(String text,
      {Uint8List? imageBytes, String? imageName}) async {
    // Pequeña espera para que el indicador sea perceptible.
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      // Llama a la IA real (Groq + RAG): /ai/chat para texto, /ai/chat-image
      // (visión) cuando el turno trae una captura.
      final result = await ref
          .read(aiChatServiceProvider)
          .chat(text,
              history: _historyTurns(),
              imageBytes: imageBytes,
              imageName: imageName)
          .timeout(const Duration(seconds: 25));
      await minDelay;
      return _Outcome.verdict(_Verdict(
        risk: result.risk,
        reasons: result.reasons,
        reply: result.reply,
        sources: result.sources,
      ));
    } catch (e) {
      // El error real (401, timeout, sin conexión…) queda en la consola de Flutter
      // para diagnóstico. NUNCA mostramos un "parece seguro" cuando el análisis falló.
      debugPrint('ShieldAI: fallo al llamar /ai/chat → $e');
      await minDelay;
      final local = _localHeuristic(text);
      if (local.risk != RiskLevel.low) {
        // La heurística offline detectó señales: las mostramos, avisando el modo.
        return _Outcome.verdict(_Verdict(
          risk: local.risk,
          reasons: local.reasons,
          offline: true,
        ));
      }
      // Sin IA y sin señales locales: no afirmamos que sea seguro.
      return const _Outcome.error(
        'No pude completar el análisis: no logré conectar con el servidor o tu '
        'sesión venció. Revisá tu conexión o cerrá sesión y volvé a entrar, y '
        'probá de nuevo.',
      );
    }
  }

  /// Construye el historial de turnos previos (excluye el mensaje actual, que ya
  /// fue agregado a [_messages] antes de analizar). Limitado a los últimos 10.
  List<ChatTurn> _historyTurns() {
    final turns = <ChatTurn>[];
    for (final m in _messages) {
      if (m.isResult) continue;
      // En las notas de voz el contenido es el transcripto, no el texto escrito.
      final content = m.isAudio ? (m.transcript ?? '') : m.text;
      if (content.trim().isEmpty) continue;
      turns.add(ChatTurn(m.sender == _Sender.user ? 'user' : 'assistant', content));
    }
    if (turns.isNotEmpty && turns.last.role == 'user') {
      turns.removeLast(); // el último 'user' es el mensaje que estamos analizando
    }
    return turns.length > 10 ? turns.sublist(turns.length - 10) : turns;
  }

  Future<void> _pasteIntoInput() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _input.text = data!.text!;
      _focus.requestFocus();
    }
  }

  /// Selecciona una imagen (galería o cámara) y la deja como adjunto pendiente.
  /// No se envía hasta pulsar enviar, para que el usuario pueda escribir contexto.
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pendingBytes = bytes;
      _pendingName = picked.name;
    });
    _focus.requestFocus();
  }

  // ── Notas de voz ───────────────────────────────────────────────────
  /// Empieza a grabar. Pide permiso de micrófono si hace falta; si se deniega,
  /// avisa sin romper el flujo del chat.
  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          _showSnack('Necesito permiso de micrófono para grabar notas de voz.');
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/shieldai_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordElapsed = Duration.zero;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordElapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      debugPrint('ShieldAI: no se pudo iniciar la grabación → $e');
      if (mounted) _showSnack('No pude iniciar la grabación.');
    }
  }

  /// Descarta la grabación en curso sin enviarla.
  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {/* nada que enviar */}
    if (mounted) setState(() => _recording = false);
  }

  /// Detiene la grabación y dispara la transcripción + análisis.
  Future<void> _stopAndSendAudio() async {
    _recordTimer?.cancel();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('ShieldAI: fallo al detener la grabación → $e');
    }
    if (!mounted) return;
    setState(() => _recording = false);
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    if (!mounted || bytes.isEmpty) return;
    await _sendAudio(bytes);
  }

  /// Flujo de la nota de voz: transcribe (/ai/transcribe) y, con el texto, pide el
  /// veredicto conversacional (/ai/chat con RAG), igual que un mensaje escrito.
  Future<void> _sendAudio(Uint8List bytes) async {
    final audioIndex = _messages.length;
    setState(() {
      _messages.add(_Msg.audio()); // burbuja de voz; el transcripto llega luego
      _analyzing = true;
    });
    _scrollToBottom();

    String transcript;
    try {
      transcript = await ref
          .read(transcriptionServiceProvider)
          .transcribe(bytes, 'nota.m4a')
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('ShieldAI: fallo al transcribir → $e');
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _messages.add(_Msg.error(
          'No pude transcribir el audio: revisá tu conexión e intentá de nuevo.',
        ));
      });
      _scrollToBottom();
      return;
    }

    if (!mounted) return;
    // Ya tenemos el transcripto: lo mostramos dentro de la burbuja de voz.
    setState(() => _messages[audioIndex] = _Msg.audio(transcript: transcript));

    if (transcript.isEmpty) {
      setState(() {
        _analyzing = false;
        _messages.add(_Msg.error(
          'No se entendió ningún mensaje en el audio. Probá de nuevo, hablando '
          'más cerca y claro.',
        ));
      });
      _scrollToBottom();
      return;
    }

    _scrollToBottom();
    final outcome = await _analyze(transcript);
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      if (outcome.verdict != null) {
        _messages.add(_Msg.result(outcome.verdict!));
      } else {
        _messages.add(_Msg.error(outcome.error!));
      }
    });
    _scrollToBottom();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openAttachMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.accentViolet),
              title: const Text('Subir captura de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.accentViolet),
              title: const Text('Tomar una foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste, color: AppTheme.primary),
              title: const Text('Pegar del portapapeles'),
              onTap: () {
                Navigator.pop(ctx);
                _pasteIntoInput();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                children: [
                  const _DateChip('Hoy'),
                  const SizedBox(height: 16),
                  for (final m in _messages) ...[
                    _MsgBubble(msg: m, aiBubble: _aiBubble, onChip: _onChip),
                    const SizedBox(height: 16),
                  ],
                  if (_analyzing) const _AnalyzingIndicator(),
                ],
              ),
            ),
            _InputBar(
              controller: _input,
              focusNode: _focus,
              onSend: _send,
              onAttach: _openAttachMenu,
              sending: _analyzing,
              pendingImage: _pendingBytes,
              onRemoveImage: () => setState(() {
                _pendingBytes = null;
                _pendingName = null;
              }),
              canSend: _input.text.trim().isNotEmpty || _pendingBytes != null,
              recording: _recording,
              recordElapsed: _recordElapsed,
              onMicStart: _startRecording,
              onMicStop: _stopAndSendAudio,
              onMicCancel: _cancelRecording,
            ),
          ],
        ),
      ),
    );
  }

  void _onChip(_ChipAction action) {
    switch (action) {
      case _ChipAction.shareScreenshot:
        _openAttachMenu();
      case _ChipAction.pasteNumber:
        _pasteIntoInput();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 12,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'ShieldAI Assistant',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  fontSize: 18,
                ),
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secureSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingDot(),
              SizedBox(width: 6),
              Text(
                'Sesión cifrada',
                style: TextStyle(
                  color: AppTheme.secure,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

// ── Modelo de mensajes ─────────────────────────────────────────────
enum _Sender { user, ai }

enum _ChipAction { shareScreenshot, pasteNumber }

/// Resultado de analizar un mensaje: o un veredicto, o un error (la llamada
/// falló y NO podemos afirmar nada sobre la seguridad del mensaje).
class _Outcome {
  final _Verdict? verdict;
  final String? error;
  const _Outcome.verdict(this.verdict) : error = null;
  const _Outcome.error(this.error) : verdict = null;
}

class _Verdict {
  final RiskLevel risk;
  final List<String> reasons;
  final String reply; // texto generado por la IA (vacío si vino del fallback)
  final List<String> sources; // estafas del índice citadas (RAG)
  final bool offline; // veredicto de la heurística local (sin IA)
  const _Verdict({
    required this.risk,
    required this.reasons,
    this.reply = '',
    this.sources = const [],
    this.offline = false,
  });
}

class _Msg {
  final _Sender sender;
  final String text;
  final DateTime time;
  final _Verdict? verdict;
  final bool isError;
  final Uint8List? imageBytes; // captura adjunta (solo mensajes del usuario)
  final String? imageName;
  final bool isAudio; // nota de voz del usuario
  final String? transcript; // texto reconocido (null mientras transcribe)

  _Msg.user(this.text, {this.imageBytes, this.imageName})
      : sender = _Sender.user,
        verdict = null,
        isError = false,
        isAudio = false,
        transcript = null,
        time = DateTime.now();

  _Msg.audio({this.transcript})
      : sender = _Sender.user,
        text = '',
        verdict = null,
        isError = false,
        isAudio = true,
        imageBytes = null,
        imageName = null,
        time = DateTime.now();

  _Msg.ai(this.text)
      : sender = _Sender.ai,
        verdict = null,
        isError = false,
        imageBytes = null,
        imageName = null,
        isAudio = false,
        transcript = null,
        time = DateTime.now();

  _Msg.result(this.verdict)
      : sender = _Sender.ai,
        text = '',
        isError = false,
        imageBytes = null,
        imageName = null,
        isAudio = false,
        transcript = null,
        time = DateTime.now();

  _Msg.error(this.text)
      : sender = _Sender.ai,
        verdict = null,
        isError = true,
        imageBytes = null,
        imageName = null,
        isAudio = false,
        transcript = null,
        time = DateTime.now();

  bool get isResult => verdict != null;
}

// ── Heurística local (fallback sin backend) ────────────────────────
_Verdict _localHeuristic(String raw) {
  final text = raw.toLowerCase();
  final reasons = <String>[];

  void hit(List<String> keys, String reason) {
    if (keys.any(text.contains)) reasons.add(reason);
  }

  hit(['contraseña', 'password', 'clave', 'pin', 'otp', 'código de seguridad'],
      'Solicita credenciales o códigos: nunca los compartas.');
  hit(['banco', 'bank', 'tarjeta', 'cuenta bancaria'],
      'Se hace pasar por tu banco o entidad financiera.');
  hit(['urgente', 'inmediato', 'ahora', '24 horas', 'suspendid', 'bloquead'],
      'Genera urgencia para presionarte a actuar rápido.');
  hit(['premio', 'ganaste', 'gratis', 'felicidades', 'sorteo'],
      'Promete premios o dinero fácil.');
  hit(['http', 'bit.ly', 'www.', '.click', 'verifica', 'verificar', 'ingresa a'],
      'Incluye un enlace para que ingreses tus datos.');

  final RiskLevel risk;
  if (reasons.length >= 3) {
    risk = RiskLevel.high;
  } else if (reasons.isNotEmpty) {
    risk = RiskLevel.medium;
  } else {
    risk = RiskLevel.low;
  }
  return _Verdict(risk: risk, reasons: reasons);
}

// ── Widgets de UI ──────────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  final Color aiBubble;
  final ValueChanged<_ChipAction> onChip;

  const _MsgBubble({
    required this.msg,
    required this.aiBubble,
    required this.onChip,
  });

  String get _time {
    final h = msg.time.hour.toString().padLeft(2, '0');
    final m = msg.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == _Sender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppTheme.primary
                      : msg.isError
                          ? const Color(0xFFFEF3C7) // ámbar suave: algo falló
                          : aiBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                ),
                child: msg.isError
                    ? _ErrorContent(text: msg.text, time: _time)
                    : msg.isResult
                        ? _ResultContent(
                            verdict: msg.verdict!, time: _time, onChip: onChip)
                        : msg.isAudio
                            ? _AudioContent(
                                transcript: msg.transcript, time: _time)
                            : _TextContent(
                                text: msg.text,
                                time: _time,
                                isUser: isUser,
                                imageBytes: msg.imageBytes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final String text;
  final String time;
  final bool isUser;
  final Uint8List? imageBytes;
  const _TextContent(
      {required this.text,
      required this.time,
      required this.isUser,
      this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final fg = isUser ? Colors.white : AppTheme.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          if (text.isNotEmpty) const SizedBox(height: 8),
        ],
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(color: fg, fontSize: 14.5, height: 1.45),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textTertiary,
                fontSize: 10.5,
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 4),
              Icon(Icons.done_all_rounded,
                  size: 13, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ],
    );
  }
}

/// Burbuja de nota de voz del usuario: ícono de audio y, una vez transcripto,
/// el texto reconocido (mientras tanto, "Transcribiendo…").
class _AudioContent extends StatelessWidget {
  final String? transcript;
  final String time;
  const _AudioContent({required this.transcript, required this.time});

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    final pending = transcript == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, size: 16, color: fg),
            ),
            const SizedBox(width: 8),
            const Text(
              'Nota de voz',
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pending)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
              const SizedBox(width: 8),
              Text(
                'Transcribiendo…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          )
        else
          Text(
            '“$transcript”',
            style: const TextStyle(color: fg, fontSize: 14.5, height: 1.4),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.done_all_rounded,
                size: 13, color: Colors.white.withValues(alpha: 0.7)),
          ],
        ),
      ],
    );
  }
}

/// Burbuja cuando el análisis NO se pudo completar (red/auth). Es deliberadamente
/// distinta de un veredicto: nunca insinúa que el mensaje sea seguro.
class _ErrorContent extends StatelessWidget {
  final String text;
  final String time;
  const _ErrorContent({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 16, color: AppTheme.warning),
            SizedBox(width: 6),
            Text(
              'NO SE PUDO ANALIZAR',
              style: TextStyle(
                color: AppTheme.warning,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _ResultContent extends StatelessWidget {
  final _Verdict verdict;
  final String time;
  final ValueChanged<_ChipAction> onChip;
  const _ResultContent(
      {required this.verdict, required this.time, required this.onChip});

  ({String header, Color color, String body}) get _meta {
    switch (verdict.risk) {
      case RiskLevel.high:
        return (
          header: 'ALTO RIESGO DETECTADO',
          color: AppTheme.danger,
          body:
              'Esto parece una estafa. Los bancos y servicios legítimos nunca '
                  'piden tu contraseña ni códigos por mensaje. No respondas ni '
                  'toques los enlaces.',
        );
      case RiskLevel.medium:
        return (
          header: 'RIESGO MEDIO',
          color: AppTheme.warning,
          body:
              'Hay señales sospechosas. Revisá con cautela antes de responder o '
                  'abrir cualquier enlace. Ante la duda, verificá por un canal oficial.',
        );
      case RiskLevel.low:
        return (
          header: 'PARECE SEGURO',
          color: AppTheme.secure,
          body:
              'No detecté señales claras de estafa. Aun así, no compartas datos '
                  'sensibles si algo te genera dudas.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    final showActions = verdict.risk != RiskLevel.low;
    // Si la IA generó una explicación propia, la mostramos; si no (fallback
    // local), usamos el texto plantilla según el nivel de riesgo.
    final bodyText = verdict.reply.isNotEmpty ? verdict.reply : m.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              verdict.risk == RiskLevel.high
                  ? Icons.warning_rounded
                  : verdict.risk == RiskLevel.medium
                      ? Icons.error_outline_rounded
                      : Icons.verified_user_rounded,
              size: 16,
              color: m.color,
            ),
            const SizedBox(width: 6),
            Text(
              m.header,
              style: TextStyle(
                color: m.color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        if (verdict.offline) ...[
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 13, color: AppTheme.textTertiary),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Análisis offline limitado (sin conexión con la IA)',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          bodyText,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
        if (verdict.reasons.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...verdict.reasons.take(4).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: m.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
        if (verdict.sources.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Basado en: ${verdict.sources.join(' · ')}',
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ],
        if (showActions) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: Icons.upload_file_rounded,
                label: 'Compartir captura',
                onTap: () => onChip(_ChipAction.shareScreenshot),
              ),
              _ActionChip(
                icon: Icons.tag_rounded,
                label: 'Pegar número',
                onTap: () => onChip(_ChipAction.pasteNumber),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analizando amenaza de seguridad…',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: AppTheme.surfaceMuted,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool sending;
  final Uint8List? pendingImage;
  final VoidCallback onRemoveImage;
  final bool canSend; // hay texto o imagen → muestra "enviar"; si no, "micrófono"
  final bool recording;
  final Duration recordElapsed;
  final VoidCallback onMicStart;
  final VoidCallback onMicStop;
  final VoidCallback onMicCancel;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.sending,
    required this.pendingImage,
    required this.onRemoveImage,
    required this.canSend,
    required this.recording,
    required this.recordElapsed,
    required this.onMicStart,
    required this.onMicStop,
    required this.onMicCancel,
  });

  String get _elapsedLabel {
    final m = recordElapsed.inMinutes.toString().padLeft(2, '0');
    final s = (recordElapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = pendingImage != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage && !recording)
            _PendingImagePreview(bytes: pendingImage!, onRemove: onRemoveImage),
          recording ? _buildRecordingRow() : _buildComposeRow(hasImage),
        ],
      ),
    );
  }

  /// Barra normal de composición: adjuntar + texto + (enviar | micrófono).
  Widget _buildComposeRow(bool hasImage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _RoundIconButton(
          icon: Icons.add_rounded,
          background: AppTheme.surfaceMuted,
          iconColor: AppTheme.textSecondary,
          onTap: sending ? null : onAttach,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(fontSize: 14.5),
            decoration: InputDecoration(
              hintText: hasImage
                  ? 'Agregá un contexto (opcional)…'
                  : 'Escribí, pegá o grabá un mensaje…',
              filled: true,
              fillColor: AppTheme.surfaceMuted,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Sin texto ni imagen → micrófono; con contenido → enviar.
        canSend
            ? _RoundIconButton(
                icon: Icons.send_rounded,
                background: AppTheme.primary,
                iconColor: Colors.white,
                onTap: sending ? null : onSend,
              )
            : _RoundIconButton(
                icon: Icons.mic_rounded,
                background: AppTheme.primary,
                iconColor: Colors.white,
                onTap: sending ? null : onMicStart,
              ),
      ],
    );
  }

  /// Barra en modo grabación: cancelar (papelera) + contador animado + enviar.
  Widget _buildRecordingRow() {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.delete_outline_rounded,
          background: AppTheme.surfaceMuted,
          iconColor: AppTheme.danger,
          onTap: onMicCancel,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const _PulsingDot(color: AppTheme.danger),
                const SizedBox(width: 10),
                Text(
                  'Grabando…  $_elapsedLabel',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: Icons.send_rounded,
          background: AppTheme.primary,
          iconColor: Colors.white,
          onTap: onMicStop,
        ),
      ],
    );
  }
}

/// Miniatura de la imagen adjunta antes de enviarla, con botón para quitarla.
class _PendingImagePreview extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;
  const _PendingImagePreview({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -7,
              right: -7,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 2),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({this.color = AppTheme.secure});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
