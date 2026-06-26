import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../packages/analisis/views/chatbot_view.dart';
import '../../packages/historial/views/history_view.dart';
import '../../packages/educativo/views/tips_view.dart';
import '../../packages/usuario/views/profile_view.dart';

/// Contenedor principal con barra de navegación inferior (4 pestañas)
/// reproduciendo la estructura de los mockups: Analizar · Historial ·
/// Consejos · Perfil. Cada pestaña conserva su estado mediante [IndexedStack].
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index = widget.initialIndex;

  static const _tabs = <Widget>[
    ChatbotView(),
    HistoryView(),
    TipsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(Icons.smart_toy),
                label: 'Asistente',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                label: 'Historial',
              ),
              NavigationDestination(
                icon: Icon(Icons.lightbulb_outline_rounded),
                label: 'Consejos',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
