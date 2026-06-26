import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/local_history_service.dart';
import '../models/analysis_result.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/risk_level.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shield_widgets.dart';

final historyProvider = FutureProvider<List<AnalysisResult>>((ref) async {
  return ref.read(localHistoryServiceProvider).getAll();
});

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: shieldBrandBar(
        context,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            color: AppTheme.textSecondary,
            tooltip: 'Dashboard',
            onPressed: () => context.push(AppConstants.routeDashboard),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            color: AppTheme.textSecondary,
            tooltip: 'Limpiar historial',
            onPressed: () => _confirmClear(context, ref),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar historial: $e')),
        data: (items) => _HistoryBody(items: items),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Eliminar todos los registros locales?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(localHistoryServiceProvider).clearAll();
      ref.invalidate(historyProvider);
    }
  }
}

class _HistoryBody extends StatelessWidget {
  final List<AnalysisResult> items;
  const _HistoryBody({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final safe = items.where((e) => e.riskLevel == RiskLevel.low).length;
    final safeRate = total == 0 ? 0 : ((safe / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const ScreenHeading(
          title: 'Historial de Análisis',
          subtitle: 'Revisá tus chequeos de seguridad anteriores.',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 20),
        // IntrinsicHeight acota la altura del Row (= la tarjeta más alta) para
        // que 'stretch' iguale ambas; sin él, dentro del ListView la altura es
        // infinita y el Row falla en layout (size: MISSING).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total de Escaneos',
                  value: '$total',
                  valueColor: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  label: 'Tasa Segura',
                  value: '$safeRate%',
                  valueColor: AppTheme.secure,
                  accentColor: AppTheme.secure,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (items.isEmpty)
          const _EmptyHistory()
        else
          ..._buildTimeline(context),
      ],
    );
  }

  List<Widget> _buildTimeline(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      widgets.add(_HistoryCard(result: items[i]));
      widgets.add(const SizedBox(height: 14));
      // Inserta la tarjeta promocional tras los primeros 3 registros.
      if (i == 2) {
        widgets.add(const _LearningPromo());
        widgets.add(const SizedBox(height: 14));
      }
    }
    return widgets;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color? accentColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShieldCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AnalysisResult result;
  const _HistoryCard({required this.result});

  ({String title, String badge, Color color, Color bg}) get _meta {
    switch (result.riskLevel) {
      case RiskLevel.high:
        return (
          title: 'Riesgo Alto Detectado',
          badge: 'Amenaza Bloqueada',
          color: AppTheme.danger,
          bg: AppTheme.dangerSoft,
        );
      case RiskLevel.medium:
        return (
          title: 'Posible Fuga de Privacidad',
          badge: 'Revisión Manual',
          color: AppTheme.warning,
          bg: AppTheme.warningSoft,
        );
      case RiskLevel.low:
        return (
          title: 'Sistema Limpio',
          badge: 'Verificado Seguro',
          color: AppTheme.secure,
          bg: AppTheme.secureSoft,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    final fmt = DateFormat('dd MMM, HH:mm', 'es');
    final preview = result.contentPreview ??
        (result.type == 'text'
            ? 'Análisis de texto / URL completado.'
            : 'Análisis de imagen completado.');

    return ShieldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: m.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  m.title,
                  style: TextStyle(
                    color: m.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                _safeFormat(fmt, result.createdAt.toLocal()),
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusPill(label: m.badge, color: m.color, background: m.bg, dense: true),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  String _safeFormat(DateFormat fmt, DateTime date) {
    try {
      return fmt.format(date);
    } catch (_) {
      // Si el locale 'es' no está inicializado, cae a un formato neutro.
      return DateFormat('dd/MM HH:mm').format(date);
    }
  }
}

/// Tarjeta promocional "La IA aprende de tu historial".
class _LearningPromo extends StatelessWidget {
  const _LearningPromo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppTheme.accentViolet, size: 28),
          const SizedBox(height: 12),
          Text(
            'La IA aprende continuamente de tu historial para anticipar amenazas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 56, color: AppTheme.textTertiary),
            SizedBox(height: 16),
            Text(
              'Sin análisis recientes',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Analizá un mensaje para verlo aquí.',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
