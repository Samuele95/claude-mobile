import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/utils/platform_utils.dart';
import 'core/utils/desktop_window.dart';
import 'features/connection/connection_screen.dart';
import 'features/desktop/desktop_shell.dart';
import 'features/settings/preferences_provider.dart';
import 'features/terminal/terminal_screen.dart';

class ClaudeMobileApp extends ConsumerWidget {
  const ClaudeMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp(
      title: 'Claude Carry',
      theme: prefs.themeData,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    if (isDesktop) {
      // Set initial window title after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateWindowTitle();
      });
    }
  }

  void _updateWindowTitle() {
    final activeId = ref.read(activeSessionIdProvider);
    final sessions = ref.read(sessionsProvider).valueOrNull ?? [];
    final session = sessions.where((s) => s.id == activeId).firstOrNull;
    setWindowTitle(session != null
        ? 'Claude Carry — ${session.profile.name}'
        : 'Claude Carry');
  }

  @override
  Widget build(BuildContext context) {
    final activeSessionId = ref.watch(activeSessionIdProvider);

    // Update window title via listener (not in build)
    if (isDesktop) {
      ref.listen(activeSessionIdProvider, (_, _) => _updateWindowTitle());
      ref.listen(sessionsProvider, (_, _) => _updateWindowTitle());
    }

    if (isWideScreen(context)) {
      return const DesktopShell(key: ValueKey('desktop'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: activeSessionId != null
          ? const TerminalScreen(key: ValueKey('terminal'))
          : const ConnectionScreen(key: ValueKey('connection')),
    );
  }
}
