import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/network_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resuelve a qué backend apunta la app según cómo se ejecuta
  // (web/escritorio→localhost, emulador→10.0.2.2, dispositivo físico→Render).
  await NetworkConfig.init();
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: ScamShieldApp()));
}

class ScamShieldApp extends ConsumerWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ShieldAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light, // los mockups son light; forzamos claro
      routerConfig: router,
    );
  }
}
