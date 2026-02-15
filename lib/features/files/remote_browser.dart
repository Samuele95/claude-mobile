import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'file_item_tile.dart';

class RemoteBrowser extends ConsumerStatefulWidget {
  final void Function(String path) onSendToTerminal;

  const RemoteBrowser({super.key, required this.onSendToTerminal});

  @override
  ConsumerState<RemoteBrowser> createState() => _RemoteBrowserState();
}

class _RemoteBrowserState extends ConsumerState<RemoteBrowser> {
  String _currentPath = '/home';
  List<_FileEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sftp = ref.read(sftpServiceProvider);
      final items = await sftp.listDirectory(_currentPath);
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

  void _showContextMenu(BuildContext context, _FileEntry entry) {
    final fullPath = '$_currentPath/${entry.name}';
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy path'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: fullPath));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.terminal),
            title: const Text('Send path to Claude'),
            onTap: () {
              widget.onSendToTerminal(fullPath);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete'),
            onTap: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final sftp = ref.read(sftpServiceProvider);
              try {
                if (entry.isDirectory) {
                  await sftp.rmdir(fullPath);
                } else {
                  await sftp.remove(fullPath);
                }
                _loadDirectory();
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return FileItemTile(
                          name: entry.name,
                          isDirectory: entry.isDirectory,
                          subtitle: entry.isDirectory
                              ? null
                              : _formatSize(entry.size),
                          onTap: entry.isDirectory
                              ? () => _navigate(entry.name)
                              : () {},
                          onLongPress: () =>
                              _showContextMenu(context, entry),
                        );
                      },
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
