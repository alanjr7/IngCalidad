import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/widgets/risk_badge.dart';
import '../../historial/models/analysis_result.dart';
import '../../historial/services/local_history_service.dart';
import '../../../core/constants/risk_level.dart';

// Estado
sealed class ImageAnalysisState { const ImageAnalysisState(); }
class ImageIdle extends ImageAnalysisState { const ImageIdle(); }
class ImageLoading extends ImageAnalysisState { const ImageLoading(); }
class ImageSuccess extends ImageAnalysisState {
  final AnalysisResult result;
  const ImageSuccess(this.result);
}
class ImageError extends ImageAnalysisState {
  final String message;
  const ImageError(this.message);
}

// Controller
class ImageAnalysisController extends StateNotifier<ImageAnalysisState> {
  final Dio _dio;
  final LocalHistoryService _history;

  ImageAnalysisController(this._dio, this._history) : super(const ImageIdle());

  /// Analiza la imagen a partir de sus **bytes**, no de un `File` de `dart:io`.
  /// Así funciona igual en web (donde no hay sistema de archivos: el picker
  /// devuelve un blob) que en móvil. Subimos con [MultipartFile.fromBytes].
  Future<void> analyze(Uint8List bytes, String filename) async {
    state = const ImageLoading();
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post('/reports/image', data: formData);
      final result = AnalysisResult.fromJson(response.data as Map<String, dynamic>);
      await _history.save(result);
      state = ImageSuccess(result);
    } catch (e) {
      state = ImageError(e.toString().contains('Network')
          ? 'Sin conexión a internet'
          : 'Error al analizar la imagen');
    }
  }

  void reset() => state = const ImageIdle();
}

final imageAnalysisProvider =
    StateNotifierProvider<ImageAnalysisController, ImageAnalysisState>((ref) {
  return ImageAnalysisController(
    ref.read(apiClientProvider).dio,
    ref.read(localHistoryServiceProvider),
  );
});

// Vista
class ImageAnalysisView extends ConsumerStatefulWidget {
  const ImageAnalysisView({super.key});

  @override
  ConsumerState<ImageAnalysisView> createState() => _ImageAnalysisViewState();
}

class _ImageAnalysisViewState extends ConsumerState<ImageAnalysisView> {
  Uint8List? _selectedBytes;
  String? _selectedName;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      // readAsBytes() es multiplataforma: en móvil lee del archivo, en web del blob.
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedBytes = bytes;
        _selectedName = picked.name;
      });
      ref.read(imageAnalysisProvider.notifier).reset();
    }
  }

  Future<void> _analyze() async {
    if (_selectedBytes == null) return;
    await ref
        .read(imageAnalysisProvider.notifier)
        .analyze(_selectedBytes!, _selectedName ?? 'captura.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageAnalysisProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analizar Imagen')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de imagen
              GestureDetector(
                onTap: () => _showSourceDialog(context),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _selectedBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _selectedBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Toca para seleccionar imagen',
                                style: TextStyle(color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Text('Galería o cámara',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Cámara'),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (_selectedBytes == null || state is ImageLoading) ? null : _analyze,
                icon: state is ImageLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.image_search),
                label: Text(state is ImageLoading ? 'Analizando...' : 'Analizar Imagen'),
              ),

              if (state is ImageError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text((state as ImageError).message,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],

              if (state is ImageSuccess) ...[
                const SizedBox(height: 24),
                _ResultSummary(result: (state as ImageSuccess).result),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final AnalysisResult result;
  const _ResultSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Resultado del análisis',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                RiskBadge(level: result.riskLevel, large: true),
              ],
            ),
            if (result.patternsFound.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...result.patternsFound.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: result.riskLevel.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
