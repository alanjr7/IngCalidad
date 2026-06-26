import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/text_analysis_controller.dart';
import '../../historial/models/analysis_result.dart';
import '../../../core/constants/risk_level.dart';
import '../../../shared/widgets/risk_badge.dart';

class TextAnalysisView extends ConsumerStatefulWidget {
  const TextAnalysisView({super.key});

  @override
  ConsumerState<TextAnalysisView> createState() => _TextAnalysisViewState();
}

class _TextAnalysisViewState extends ConsumerState<TextAnalysisView> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _textCtrl.text = data!.text!;
    }
  }

  Future<void> _analyze() async {
    if (_textCtrl.text.trim().isEmpty) return;
    await ref.read(textAnalysisControllerProvider.notifier).analyze(_textCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(textAnalysisControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizar Texto'),
        actions: [
          if (state is! TextAnalysisIdle)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Nuevo análisis',
              onPressed: () {
                ref.read(textAnalysisControllerProvider.notifier).reset();
                _textCtrl.clear();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área de texto
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pegá el mensaje o URL',
                              style: theme.textTheme.titleSmall),
                          TextButton.icon(
                            icon: const Icon(Icons.content_paste, size: 16),
                            label: const Text('Pegar'),
                            onPressed: _paste,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textCtrl,
                        maxLines: 6,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          hintText: 'Ej: "Tu cuenta bancaria fue bloqueada...\nhttps://bit.ly/xxx"',
                          border: InputBorder.none,
                          counterStyle: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state is TextAnalysisLoading ? null : _analyze,
                icon: state is TextAnalysisLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: Text(state is TextAnalysisLoading
                    ? 'Analizando...'
                    : 'Analizar'),
              ),

              // Error
              if (state is TextAnalysisError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                ),
              ],

              // Resultado
              if (state is TextAnalysisSuccess) ...[
                const SizedBox(height: 24),
                _ResultCard(result: state.result),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AnalysisResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Resultado', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                RiskBadge(level: result.riskLevel, large: true),
              ],
            ),
            const SizedBox(height: 16),
            _ScoreBar(score: result.riskScore, level: result.riskLevel),
            const SizedBox(height: 20),
            if (result.patternsFound.isEmpty)
              const _NoPatterns()
            else ...[
              Text('Patrones detectados',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.grey.shade700,
                  )),
              const SizedBox(height: 8),
              ...result.patternsFound.map((p) => _PatternTile(pattern: p)),
            ],
            if (result.processingMs != null) ...[
              const SizedBox(height: 12),
              Text(
                'Procesado en ${result.processingMs}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final double score;
  final RiskLevel level;
  const _ScoreBar({required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Nivel de riesgo', style: TextStyle(fontSize: 13)),
            Text('${(score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: level.color,
                  fontSize: 15,
                )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(level.color),
          ),
        ),
      ],
    );
  }
}

class _PatternTile extends StatelessWidget {
  final String pattern;
  const _PatternTile({required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(child: Text(pattern, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _NoPatterns extends StatelessWidget {
  const _NoPatterns();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
        const SizedBox(width: 8),
        Text(
          'No se detectaron patrones sospechosos',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
