import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/connection/connection_screen.dart';
import 'features/terminal/terminal_screen.dart';
import 'features/settings/preferences_provider.dart';
import 'core/providers.dart';

class ClaudeMobileApp extends ConsumerWidget {
  const ClaudeMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp(
      title: 'Claude Mobile',
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
    final connectionState = ref.watch(connectionStateProvider);

    return connectionState.when(
      data: (state) {
        if (state.isConnected) {
          return const TerminalScreen();
        }
        return const ConnectionScreen();
      },
      loading: () => const ConnectionScreen(),
      error: (_, __) => const ConnectionScreen(),
    );
  }
}
