import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers.dart';
import '../../core/models/connection_state.dart';
import '../../core/models/transfer_item.dart';
import '../../theme/terminal_theme.dart';
import '../files/file_panel.dart';
import 'terminal_controller.dart';
import 'smart_toolbar.dart';
import 'command_palette.dart';

final terminalControllerProvider = Provider<TerminalController>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  final controller = TerminalController(ssh: ssh);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showCommandPalette() {
    final controller = ref.read(terminalControllerProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => CommandPalette(
        onSelect: (cmd) => controller.sendText('$cmd\n'),
      ),
    );
  }

  Future<void> _attachFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final sftp = ref.read(sftpServiceProvider);
    final controller = ref.read(terminalControllerProvider);
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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(terminalControllerProvider);
    final connectionState = ref.watch(connectionStateProvider);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const Drawer(
        width: 320,
        child: FilePanel(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ConnectionPill(
              state: connectionState.valueOrNull ??
                  SshConnectionState.disconnected,
              onDisconnect: () {
                ref.read(sshServiceProvider).disconnect();
              },
              onFilePanel: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
            Expanded(
              child: TerminalView(
                controller.terminal,
                theme: TerminalThemes.dark,
                textStyle: const TerminalStyle(
                  fontSize: 14,
                  fontFamily: 'JetBrainsMono',
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            SmartToolbar(
              controller: controller,
              onAttachFile: _attachFile,
              onCommandPalette: _showCommandPalette,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final SshConnectionState state;
  final VoidCallback onDisconnect;
  final VoidCallback onFilePanel;

  const _ConnectionPill({
    required this.state,
    required this.onDisconnect,
    required this.onFilePanel,
  });

  Color get _color => switch (state) {
        SshConnectionState.connected => Colors.green,
        SshConnectionState.reconnecting => Colors.amber,
        SshConnectionState.connecting => Colors.amber,
        _ => Colors.redAccent,
      };

  String get _label => switch (state) {
        SshConnectionState.connected => 'Connected',
        SshConnectionState.reconnecting => 'Reconnecting...',
        SshConnectionState.connecting => 'Connecting...',
        SshConnectionState.error => 'Error',
        SshConnectionState.disconnected => 'Disconnected',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(_label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.folder_outlined, size: 20),
            onPressed: onFilePanel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: onDisconnect,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
