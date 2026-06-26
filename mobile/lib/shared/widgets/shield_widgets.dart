import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Kit de widgets de marca ShieldAI, derivado de los mockups.
///
/// Centraliza la barra de marca, las píldoras de estado, las tarjetas
/// redondeadas y los encabezados de sección para que todas las pantallas
/// compartan exactamente el mismo lenguaje visual.

// ── Barra superior de marca ("🛡 ShieldAI" + campana) ──────────────
AppBar shieldBrandBar(
  BuildContext context, {
  bool showBell = true,
  VoidCallback? onBellTap,
  List<Widget> actions = const [],
}) {
  return AppBar(
    titleSpacing: 20,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ShieldGlyph(size: 26),
        const SizedBox(width: 10),
        Text(
          'ShieldAI',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.2,
              ),
        ),
      ],
    ),
    actions: [
      ...actions,
      if (showBell)
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppTheme.textSecondary,
          onPressed: onBellTap ?? () {},
          tooltip: 'Notificaciones',
        ),
      const SizedBox(width: 8),
    ],
  );
}

/// Escudo de marca con relleno índigo (como el ícono de los mockups).
class _ShieldGlyph extends StatelessWidget {
  final double size;
  const _ShieldGlyph({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.shield_rounded, size: size, color: AppTheme.primary);
  }
}

// ── Píldora de estado (Threat Blocked / Verified Safe / Premium…) ──
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool dense;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
    this.dense = false,
  });

  /// Variante "marca": fondo índigo suave, texto índigo (PRIORIDAD ALTA…).
  factory StatusPill.brand(String label, {IconData? icon}) => StatusPill(
        label: label,
        color: AppTheme.primary,
        background: AppTheme.primarySoft,
        icon: icon,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 13 : 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta blanca redondeada con sombra suave y borde de acento ───
class ShieldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accentColor;
  final Color? color;

  const ShieldCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accentColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radius);
    return Material(
      color: color ?? AppTheme.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: color ?? AppTheme.surface,
            borderRadius: radius,
            border: accentColor == null
                ? Border.all(color: AppTheme.border)
                : Border(left: BorderSide(color: accentColor!, width: 4)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Chip cuadrado con ícono (icono de las tarjetas de Tips / Perfil).
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.background,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

// ── Encabezado de pantalla (título grande + subtítulo) ─────────────
class ScreenHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  const ScreenHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 0),
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: t.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Etiqueta de sección secundaria ("Más temas de interés").
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
    );
  }
}
