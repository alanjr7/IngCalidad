import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shield_widgets.dart';

/// Pestaña "Consejos" — Centro de Consejos según los mockups.
///
/// Contenido curado para que la pantalla luzca consistente sin depender
/// del backend. Cada tarjeta abre el detalle en una hoja inferior.
class TipsView extends StatefulWidget {
  const TipsView({super.key});

  @override
  State<TipsView> createState() => _TipsViewState();
}

class _TipsViewState extends State<TipsView> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shieldBrandBar(context),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const ScreenHeading(
              title: 'Centro de Consejos',
              subtitle:
                  'Tu escudo digital se fortalece con el conocimiento. '
                  'Aprendé a protegerte de las amenazas modernas.',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),

            // ── Destacado (prioridad alta) ──────────────────────
            _FeaturedTip(
              title: 'Qué hacer si caíste en una estafa',
              description:
                  'Guía paso a paso para recuperar el control de tus '
                  'cuentas y mitigar daños financieros.',
              onTap: () => _openDetail(
                context,
                'Qué hacer si caíste en una estafa',
                'Actuá rápido: cambiá tus contraseñas, comunicate con tu banco '
                    'para bloquear tarjetas, revisá los movimientos recientes y '
                    'denunciá el fraude. Activá la verificación en dos pasos antes '
                    'de volver a usar tus cuentas.',
              ),
            ),
            const SizedBox(height: 16),

            // ── Tarjetas con acento + duración ──────────────────
            const _GuideCard(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppTheme.primary,
              accent: AppTheme.primary,
              minutes: '5 min',
              title: 'Cómo identificar smishing',
              description:
                  'Detección de mensajes de texto fraudulentos y enlaces sospechosos.',
            ),
            const SizedBox(height: 16),
            const _GuideCard(
              icon: Icons.lock_outline_rounded,
              iconColor: AppTheme.secure,
              accent: AppTheme.secure,
              minutes: '8 min',
              title: 'Protección de datos personales',
              description:
                  'Configuraciones esenciales de privacidad para tus redes sociales y apps.',
            ),
            const SizedBox(height: 28),

            const SectionLabel('Más temas de interés'),
            const SizedBox(height: 14),
            _TopicRow(
              icon: Icons.password_rounded,
              color: AppTheme.primary,
              title: 'Gestión de contraseñas',
              subtitle: 'Uso de gestores y autenticación de dos factores.',
              onTap: () => _openDetail(context, 'Gestión de contraseñas',
                  'Usá un gestor de contraseñas y activá la verificación en dos pasos en todas tus cuentas críticas.'),
            ),
            const _RowDivider(),
            _TopicRow(
              icon: Icons.wifi_rounded,
              color: AppTheme.secure,
              title: 'Wi-Fi Públicas',
              subtitle: 'Riesgos y mejores prácticas al navegar fuera.',
              onTap: () => _openDetail(context, 'Wi-Fi Públicas',
                  'Evitá operaciones bancarias en redes abiertas. Usá una VPN y verificá que los sitios usen HTTPS.'),
            ),
            const _RowDivider(),
            _TopicRow(
              icon: Icons.pest_control_rounded,
              color: AppTheme.danger,
              title: 'Anatomía de un Phishing',
              subtitle: 'Aprendé a diseccionar correos maliciosos.',
              onTap: () => _openDetail(context, 'Anatomía de un Phishing',
                  'Revisá el remitente real, desconfiá de la urgencia y nunca ingreses credenciales desde un enlace de correo.'),
            ),
            const SizedBox(height: 28),

            _NewsletterCard(controller: _emailCtrl, onSubmit: _subscribe),
          ],
        ),
      ),
    );
  }

  void _subscribe() {
    final email = _emailCtrl.text.trim();
    final valid = email.contains('@') && email.contains('.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(valid
            ? '¡Listo! Te suscribiste a las alertas semanales.'
            : 'Ingresá un correo válido.'),
      ),
    );
    if (valid) _emailCtrl.clear();
  }

  void _openDetail(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedTip extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeaturedTip({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ShieldCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill.brand('PRIORIDAD ALTA'),
              const Spacer(),
              const Icon(Icons.gpp_maybe_rounded, color: AppTheme.primary),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Text(
                'Leer guía',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.primary, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color accent;
  final String minutes;
  final String title;
  final String description;

  const _GuideCard({
    required this.icon,
    required this.iconColor,
    required this.accent,
    required this.minutes,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ShieldCard(
      accentColor: accent,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconChip(icon: icon, color: iconColor, size: 40),
              const Spacer(),
              Text(
                minutes,
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TopicRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconChip(icon: icon, color: color, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppTheme.border);
  }
}

class _NewsletterCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _NewsletterCard({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recibí alertas semanales',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mantenete al día con las últimas amenazas detectadas '
            'por ShieldAI en tiempo real.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tu email',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size(64, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
