import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/providers.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/models/connection_state.dart';
import '../../core/models/server_profile.dart';
import '../../core/models/session.dart';
import '../../core/models/transfer_item.dart';
import '../../core/utils/session_actions.dart';
import '../files/file_panel.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';
import '../settings/preferences_provider.dart';
import 'smart_toolbar.dart';
import 'command_palette.dart';
import 'session_tab_bar.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    if (isMobile && prefs.wakeLock) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    if (isMobile) WakelockPlus.disable();
    super.dispose();
  }

  void _showCommandPalette() {
    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) return;
    final controller =
        ref.read(sessionTerminalControllerProvider(activeId));
    if (controller == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => CommandPalette(
        onSelect: (cmd) => controller.sendText('$cmd\n'),
      ),
    );
  }

  Future<void> _attachFile() async {
    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) return;

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final sftp = ref.read(sessionSftpProvider(activeId));
    final controller =
        ref.read(sessionTerminalControllerProvider(activeId));
    if (sftp == null || controller == null) return;
    final remotePath = '/tmp/${file.name}';

    final item = TransferItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      localPath: file.path!,
      remotePath: remotePath,
      direction: TransferDirection.upload,
      totalBytes: file.size,
    );

    try {
      await sftp.upload(
        localPath: file.path!,
        remotePath: remotePath,
        item: item,
      );
      controller.sendText(remotePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded: ${file.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }

  }

  void _showConnectionInfo(Session session) {
    final profile = session.profile;
    final uptime = DateTime.now().difference(session.createdAt);
    final uptimeStr = '${uptime.inMinutes}m ${uptime.inSeconds % 60}s';

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection Info',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _InfoRow('Host', '${profile.host}:${profile.port}'),
            _InfoRow('User', profile.username),
            _InfoRow('Auth', profile.authMethod.name),
            _InfoRow('Status', session.state.label),
            _InfoRow('Uptime', uptimeStr),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ref
                          .read(connectionManagerProvider)
                          .reconnectSession(session.id);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reconnect'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _disconnectSession(session.id);
                    },
                    icon: const Icon(Icons.logout, size: 18,
                        color: Colors.redAccent),
                    label: const Text('Disconnect',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionMenu() {
    final sessions = ref.read(sessionsProvider).valueOrNull ?? [];
    final activeId = ref.read(activeSessionIdProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New session'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(activeSessionIdProvider.notifier).state = null;
              },
            ),
            const Divider(height: 1),
            ...sessions.map((session) => ListTile(
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: session.state.isConnected
                          ? Colors.green
                          : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(session.profile.name),
                  subtitle: Text(session.state.label),
                  selected: session.id == activeId,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _disconnectSession(session.id);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(activeSessionIdProvider.notifier).state =
                        session.id;
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _disconnectSession(String sessionId) async {
    await closeSessionWithConfirm(context, ref, sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
    final activeId = ref.watch(activeSessionIdProvider);
    final prefs = ref.watch(preferencesProvider);

    // Toggle wake lock at runtime when the preference changes
    if (isMobile) {
      ref.listen<AppPreferences>(preferencesProvider, (prev, next) {
        if (prev?.wakeLock != next.wakeLock) {
          next.wakeLock ? WakelockPlus.enable() : WakelockPlus.disable();
        }
      });
    }

    final activeSession = sessions.where((s) => s.id == activeId).firstOrNull;

    final controller = activeId != null
        ? ref.watch(sessionTerminalControllerProvider(activeId))
        : null;

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      endDrawer: activeId != null
          ? Drawer(
              width: 320,
              child: FilePanel(sessionId: activeId),
            )
          : null,
      onEndDrawerChanged: (_) {},
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SessionTabBar(
              onNewSession: () {
                ref.read(activeSessionIdProvider.notifier).state = null;
              },
            ),
            if (activeSession != null)
              _ConnectionPill(
                state: activeSession.state,
                profile: activeSession.profile,
                onDisconnect: () => _disconnectSession(activeSession.id),
                onFilePanel: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                ),
                onAbout: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AboutScreen()),
                ),
                onConnectionInfo: () =>
                    _showConnectionInfo(activeSession),
              ),
            if (activeSession != null &&
                (activeSession.state == SshConnectionState.disconnected ||
                    activeSession.state == SshConnectionState.error))
              _ReconnectBanner(
                state: activeSession.state,
                onReconnect: () => ref
                    .read(connectionManagerProvider)
                    .reconnectSession(activeSession.id),
              ),
            Expanded(
              child: controller != null
                  ? TerminalView(
                      controller.terminal,
                      readOnly: isMobile,
                      hardwareKeyboardOnly: isMobile,
                      theme: prefs.theme.terminalTheme,
                      textStyle: TerminalStyle(
                        fontSize: prefs.fontSize,
                        fontFamily: 'JetBrainsMono',
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                    )
                  : const Center(child: Text('No active session')),
            ),
            if (isMobile && controller != null)
              SmartToolbar(
                controller: controller,
                onAttachFile: _attachFile,
                onCommandPalette: _showCommandPalette,
                onSessionMenu: _showSessionMenu,
              ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final SshConnectionState state;
  final ServerProfile profile;
  final VoidCallback onDisconnect;
  final VoidCallback onFilePanel;
  final VoidCallback onSettings;
  final VoidCallback onAbout;
  final VoidCallback onConnectionInfo;

  const _ConnectionPill({
    required this.state,
    required this.profile,
    required this.onDisconnect,
    required this.onFilePanel,
    required this.onSettings,
    required this.onAbout,
    required this.onConnectionInfo,
  });

  Color get _color => state.statusColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(state.label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.folder_outlined, size: 20),
            onPressed: onFilePanel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  onConnectionInfo();
                case 'settings':
                  onSettings();
                case 'about':
                  onAbout();
                case 'disconnect':
                  onDisconnect();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'info',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.info_outline, size: 20),
                  title: Text('Connection Info'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.settings_outlined, size: 20),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.info_outline_rounded, size: 20),
                  title: Text('About'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'disconnect',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.logout, size: 20,
                      color: Colors.redAccent),
                  title: Text('Disconnect',
                      style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReconnectBanner extends StatelessWidget {
  final SshConnectionState state;
  final VoidCallback onReconnect;

  const _ReconnectBanner({
    required this.state,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = state == SshConnectionState.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: (isError ? Colors.redAccent : Colors.amber).withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.wifi_off,
            size: 18,
            color: isError ? Colors.redAccent : Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isError
                  ? 'Connection error'
                  : 'Disconnected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: onReconnect,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reconnect'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
          ),
        ],
      ),
    );
  }
}
