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

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionId = ref.watch(activeSessionIdProvider);

    // Update window title on desktop when active session changes
    if (isDesktop) {
      final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
      final activeSession =
          sessions.where((s) => s.id == activeSessionId).firstOrNull;
      if (activeSession != null) {
        setWindowTitle('Claude Carry — ${activeSession.profile.name}');
      } else {
        setWindowTitle('Claude Carry');
      }
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
