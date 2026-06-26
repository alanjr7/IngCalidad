import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_client.dart';
import '../../../core/constants/risk_level.dart';

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(apiClientProvider).dio;
  final response = await dio.get('/education/dashboard');
  return Map<String, dynamic>.from(response.data as Map);
});

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final total = data['total_analyses'] as int? ?? 0;
          final byLevel = Map<String, int>.from(
            (data['by_risk_level'] as Map?)?.cast<String, int>() ?? {},
          );
          final byType = Map<String, int>.from(
            (data['by_type'] as Map?)?.cast<String, int>() ?? {},
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta total
                Card(
                  color: theme.colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Total de análisis realizados',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Por nivel de riesgo
                Text('Por nivel de riesgo', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final level in RiskLevel.values)
                      Expanded(
                        child: _StatChip(
                          label: level.label,
                          count: byLevel[level.name] ?? 0,
                          color: level.color,
                          bgColor: level.backgroundColor,
                        ),
                      ),
                  ].expand((w) => [w, const SizedBox(width: 8)]).toList()
                    ..removeLast(),
                ),
                const SizedBox(height: 24),

                // Gráfico de pastel
                if (total > 0) ...[
                  Text('Distribución de riesgo', style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          for (final level in RiskLevel.values)
                            if ((byLevel[level.name] ?? 0) > 0)
                              PieChartSectionData(
                                value: (byLevel[level.name] ?? 0).toDouble(),
                                color: level.color,
                                title: level.label,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                radius: 80,
                              ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Por tipo
                Text('Por tipo de análisis', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Texto',
                        count: byType['text'] ?? 0,
                        color: const Color(0xFF1E40AF),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        label: 'Imagen',
                        count: byType['image'] ?? 0,
                        color: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFF5F3FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Exportar
                Text('Exportar datos', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('PDF'),
                        onPressed: () => _export(context, ref, 'pdf'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Excel'),
                        onPressed: () => _export(context, ref, 'excel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generando reporte $format...')),
    );
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(
        '/education/export/$format',
        options: Options(responseType: ResponseType.bytes),
      );
      // En producción: usar open_file o share_plus para abrir/compartir el archivo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte generado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar reporte: $e')),
      );
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
