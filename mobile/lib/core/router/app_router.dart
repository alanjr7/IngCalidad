import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../../packages/usuario/views/login_view.dart';
import '../../packages/usuario/views/register_view.dart';
import '../../packages/usuario/controllers/auth_controller.dart';
import '../../packages/analisis/views/text_analysis_view.dart';
import '../../packages/analisis/views/image_analysis_view.dart';
import '../../packages/educativo/views/dashboard_view.dart';
import '../../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const MainShell(initialIndex: 0),
        routes: [
          GoRoute(
            path: 'analysis/text',
            builder: (context, state) => const TextAnalysisView(),
          ),
          GoRoute(
            path: 'analysis/image',
            builder: (context, state) => const ImageAnalysisView(),
          ),
        ],
      ),
      GoRoute(
        path: AppConstants.routeHistory,
        builder: (context, state) => const MainShell(initialIndex: 1),
      ),
      GoRoute(
        path: AppConstants.routeEducation,
        builder: (context, state) => const MainShell(initialIndex: 2),
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (context, state) => const MainShell(initialIndex: 3),
      ),
      GoRoute(
        path: AppConstants.routeDashboard,
        builder: (context, state) => const DashboardView(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Espera mínima por el branding, en paralelo a que el chequeo de sesión
    // (que ahora hace una llamada de red a /auth/me) termine de resolverse.
    final minSplash = Future<void>.delayed(const Duration(seconds: 2));
    await _waitForAuthSettled();
    await minSplash;
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated) {
      context.go(AppConstants.routeHome);
    } else {
      context.go(AppConstants.routeLogin);
    }
  }

  /// Espera hasta que el estado de auth deje de ser inicial/cargando (máx ~5s),
  /// para no decidir la ruta antes de saber si la sesión es válida.
  Future<void> _waitForAuthSettled() async {
    for (var i = 0; i < 50; i++) {
      final s = ref.read(authControllerProvider);
      if (s is! AuthInitial && s is! AuthLoading) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.shield_rounded,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'ShieldAI',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Protección contra estafas digitales',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}
