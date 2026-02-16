import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/utils/dialogs.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/platform_utils.dart';
import 'file_item_tile.dart';

class RemoteBrowser extends ConsumerStatefulWidget {
  final String sessionId;
  final void Function(String path) onSendToTerminal;

  const RemoteBrowser({
    super.key,
    required this.sessionId,
    required this.onSendToTerminal,
  });

  @override
  ConsumerState<RemoteBrowser> createState() => _RemoteBrowserState();
}

class _RemoteBrowserState extends ConsumerState<RemoteBrowser> {
  String _currentPath = '/home';
  List<_FileEntry> _entries = [];
  bool _loading = true;
  String? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _resolveHomeDirectory();
  }

  Future<void> _resolveHomeDirectory() async {
    try {
      final sftp = ref.read(sessionSftpProvider(widget.sessionId));
      if (sftp != null) {
        final home = await sftp.realpath('.');
        if (mounted) {
          _currentPath = home;
        }
      }
    } catch (_) {
      // Fall back to /home if realpath fails
    }
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sftp = ref.read(sessionSftpProvider(widget.sessionId));
      if (sftp == null) {
        if (generation != _loadGeneration) return;
        setState(() {
          _error = 'SFTP not available';
          _loading = false;
        });
        return;
      }
      final items = await sftp.listDirectory(_currentPath);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _entries = items
            .map((i) => _FileEntry(
                  name: i.filename,
                  isDirectory: i.attr.isDirectory,
                  size: i.attr.size ?? 0,
                ))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navigate(String name) {
    if (_currentPath == '/') {
      _currentPath = '/$name';
    } else {
      _currentPath = '$_currentPath/$name';
    }
    _loadDirectory();
  }

  void _navigateUp() {
    final parts = _currentPath.split('/');
    if (parts.length <= 2) {
      _currentPath = '/';
    } else {
      parts.removeLast();
      _currentPath = parts.join('/');
    }
    _loadDirectory();
  }

  void _showContextMenu(BuildContext parentContext, _FileEntry entry) {
    final fullPath = '$_currentPath/${entry.name}';
    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy path'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: fullPath));
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.terminal),
            title: const Text('Send path to Claude'),
            onTap: () {
              widget.onSendToTerminal(fullPath);
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(sheetContext);
              _confirmDelete(entry, fullPath);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(_FileEntry entry, String fullPath) async {
    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${entry.isDirectory ? 'folder' : 'file'}',
      message: 'Delete "${entry.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final sftp = ref.read(sessionSftpProvider(widget.sessionId));
    if (sftp == null) return;
    try {
      if (entry.isDirectory) {
        await sftp.rmdir(fullPath);
      } else {
        await sftp.remove(fullPath);
      }
      _loadDirectory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _showDesktopContextMenu(
      BuildContext context, _FileEntry entry, TapDownDetails details) {
    final fullPath = '$_currentPath/${entry.name}';
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy path')),
        const PopupMenuItem(value: 'send', child: Text('Send to terminal')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'copy':
          Clipboard.setData(ClipboardData(text: fullPath));
        case 'send':
          widget.onSendToTerminal(fullPath);
        case 'delete':
          _confirmDelete(entry, fullPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: _currentPath == '/' ? null : _navigateUp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentPath,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'JetBrainsMono'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loadDirectory,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child:
                          Text(_error!, style: const TextStyle(fontSize: 12)))
                  : RefreshIndicator(
                      onRefresh: _loadDirectory,
                      child: ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return FileItemTile(
                            name: entry.name,
                            isDirectory: entry.isDirectory,
                            subtitle: entry.isDirectory
                                ? null
                                : formatFileSize(entry.size),
                            onTap: entry.isDirectory
                                ? () => _navigate(entry.name)
                                : () {},
                            onLongPress: () =>
                                _showContextMenu(context, entry),
                            onSecondaryTapDown: isDesktop
                                ? (details) => _showDesktopContextMenu(
                                    context, entry, details)
                                : null,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _FileEntry {
  final String name;
  final bool isDirectory;
  final int size;

  const _FileEntry({
    required this.name,
    required this.isDirectory,
    required this.size,
  });
}
