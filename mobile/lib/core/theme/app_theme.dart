import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño ShieldAI — derivado de los mockups de Stitch.
///
/// Paleta: índigo profundo (confianza/seguridad), rojo (alto riesgo),
/// verde (seguro/premium), fondo lavanda claro y tarjetas redondeadas
/// con sombras suaves.
///
/// Las pantallas consumen estos estilos vía `Theme.of(context)`. Para
/// contenedores a medida (banners, badges) usá los tokens públicos de
/// color, [cardDecoration], [softShadow] y [brandGradient].
abstract class AppTheme {
  // ── Tokens de color ─────────────────────────────────────────
  static const Color primary = Color(0xFF232C72); // índigo profundo (marca)
  static const Color primaryDark = Color(0xFF161E54); // banners / gradientes
  static const Color primarySoft = Color(0xFFEAECF7); // pills, chips, fondos tonales
  static const Color accentViolet = Color(0xFF6D5BD0); // secundario (análisis de imagen)

  static const Color danger = Color(0xFFDC2626); // alto riesgo / destructivo
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color secure = Color(0xFF16A34A); // seguro / premium
  static const Color secureSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B); // riesgo medio
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color background = Color(0xFFF4F4FB); // lavanda claro
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F2FA); // inputs / fondos sutiles
  static const Color border = Color(0xFFE6E8F2);

  static const Color textPrimary = Color(0xFF111A3A); // navy casi negro
  static const Color textSecondary = Color(0xFF5B6478); // gris azulado
  static const Color textTertiary = Color(0xFF9AA1B4);

  // ── Radios ──────────────────────────────────────────────────
  static const double radius = 18;
  static const double radiusSm = 12;

  // ── Gradiente de marca (banner "Protección Activa") ─────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // ── Sombra suave reutilizable para tarjetas ─────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF1E2A78).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Decoración lista para `Container` que imita las tarjetas de los mockups.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: softShadow,
      );

  // ── Tema claro (principal) ──────────────────────────────────
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accentViolet,
      error: danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: surface,
      surfaceContainerHighest: surfaceMuted,
      outline: border,
      outlineVariant: border,
    );

    final textTheme = _buildTextTheme(
      GoogleFonts.plusJakartaSansTextTheme(),
      textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.white : textTertiary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? primary : textTertiary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primarySoft,
        labelStyle: textTheme.labelMedium
            ?.copyWith(color: primary, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primary,
        textColor: textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primarySoft,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Tema oscuro (mismo seed; los mockups son claros) ────────
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      error: danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark(useMaterial3: true).textTheme,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    return base
        .copyWith(
          displayLarge: base.displayLarge
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          displayMedium: base.displayMedium
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          headlineLarge:
              base.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          headlineMedium:
              base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          headlineSmall:
              base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: color, displayColor: color);
  }
}
