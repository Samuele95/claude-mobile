import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../../core/providers.dart';
import '../../core/utils/desktop_window.dart';
import '../../core/utils/dialogs.dart';
import '../../theme/terminal_theme.dart';
import '../files/file_panel.dart';
import '../settings/preferences_provider.dart';
import '../terminal/command_palette.dart';
import '../terminal/session_tab_bar.dart';
import 'connection_sidebar.dart';
import 'desktop_keyboard_handler.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell>
    with WidgetsBindingObserver {
  bool _showFilePanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      saveWindowBounds();
    }
  }

  void _closeCurrentSession() async {
    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Disconnect',
      message: 'Are you sure you want to disconnect this session?',
      confirmLabel: 'Disconnect',
      destructive: true,
    );
    if (!confirmed) return;

    await ref.read(connectionManagerProvider).closeSession(activeId);
    final remaining = ref.read(sessionsProvider).valueOrNull ?? [];
    if (remaining.isEmpty) {
      ref.read(activeSessionIdProvider.notifier).state = null;
    } else {
      ref.read(activeSessionIdProvider.notifier).state = remaining.first.id;
    }
  }

  void _nextSession() {
    final sessions = ref.read(sessionsProvider).valueOrNull ?? [];
    final activeId = ref.read(activeSessionIdProvider);
    if (sessions.length < 2) return;

    final idx = sessions.indexWhere((s) => s.id == activeId);
    final next = (idx + 1) % sessions.length;
    ref.read(activeSessionIdProvider.notifier).state = sessions[next].id;
  }

  void _previousSession() {
    final sessions = ref.read(sessionsProvider).valueOrNull ?? [];
    final activeId = ref.read(activeSessionIdProvider);
    if (sessions.length < 2) return;

    final idx = sessions.indexWhere((s) => s.id == activeId);
    final prev = (idx - 1 + sessions.length) % sessions.length;
    ref.read(activeSessionIdProvider.notifier).state = sessions[prev].id;
  }

  void _showCommandPalette() {
    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) return;
    final controller =
        ref.read(sessionTerminalControllerProvider(activeId));
    if (controller == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: CommandPalette(
            onSelect: (cmd) => controller.sendText('$cmd\n'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeSessionIdProvider);
    final prefs = ref.watch(preferencesProvider);
    final controller = activeId != null
        ? ref.watch(sessionTerminalControllerProvider(activeId))
        : null;
    final colorScheme = Theme.of(context).colorScheme;

    return DesktopKeyboardHandler(
      onNewSession: () {
        ref.read(activeSessionIdProvider.notifier).state = null;
      },
      onCloseSession: _closeCurrentSession,
      onNextSession: _nextSession,
      onPreviousSession: _previousSession,
      onToggleFilePanel: () {
        setState(() => _showFilePanel = !_showFilePanel);
      },
      onCommandPalette: _showCommandPalette,
      child: Scaffold(
        body: Row(
          children: [
            // Left sidebar: connections
            const ConnectionSidebar(),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),

            // Center: terminal
            Expanded(
              child: Column(
                children: [
                  SessionTabBar(
                    onNewSession: () {
                      ref.read(activeSessionIdProvider.notifier).state = null;
                    },
                  ),
                  Expanded(
                    child: controller != null
                        ? TerminalView(
                            controller.terminal,
                            readOnly: false,
                            hardwareKeyboardOnly: false,
                            theme: AppTerminalThemes.fromPreferences(
                                prefs.themeName),
                            textStyle: TerminalStyle(
                              fontSize: prefs.fontSize,
                              fontFamily: 'JetBrainsMono',
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.terminal_rounded,
                                  size: 64,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No active session',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Select a server from the sidebar to connect',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Right: file panel (toggleable)
            if (_showFilePanel && activeId != null) ...[
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              SizedBox(
                width: 320,
                child: FilePanel(sessionId: activeId, isDrawer: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
