import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../../core/models/connection_state.dart';
import '../../core/providers.dart';
import '../../core/utils/desktop_window.dart';
import '../../core/utils/session_actions.dart';
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
    await closeSessionWithConfirm(context, ref, activeId);
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

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (shortcut, description) in keyboardShortcuts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          shortcut,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
    final activeSession =
        sessions.where((s) => s.id == activeId).firstOrNull;
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
      onShowShortcuts: () => _showShortcutsDialog(context),
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
                  if (activeSession != null &&
                      (activeSession.state == SshConnectionState.disconnected ||
                          activeSession.state == SshConnectionState.error))
                    _DesktopReconnectBanner(
                      state: activeSession.state,
                      onReconnect: () => ref
                          .read(connectionManagerProvider)
                          .reconnectSession(activeSession.id),
                    ),
                  Expanded(
                    child: controller != null
                        ? TerminalView(
                            controller.terminal,
                            readOnly: false,
                            hardwareKeyboardOnly: false,
                            theme: prefs.theme.terminalTheme,
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

class _DesktopReconnectBanner extends StatelessWidget {
  final SshConnectionState state;
  final VoidCallback onReconnect;

  const _DesktopReconnectBanner({
    required this.state,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isError = state == SshConnectionState.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: (isError ? Colors.redAccent : Colors.amber).withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.wifi_off,
            size: 16,
            color: isError ? Colors.redAccent : Colors.amber,
          ),
          const SizedBox(width: 8),
          Text(
            isError ? 'Connection error' : 'Disconnected',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onReconnect,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Reconnect'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 28),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
