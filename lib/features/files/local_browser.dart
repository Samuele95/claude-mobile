import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/format_utils.dart';
import '../../core/utils/platform_utils.dart';
import 'file_item_tile.dart';

class LocalBrowser extends StatefulWidget {
  final void Function(String path)? onSendToTerminal;

  const LocalBrowser({super.key, this.onSendToTerminal});

  @override
  State<LocalBrowser> createState() => _LocalBrowserState();
}

class _LocalBrowserState extends State<LocalBrowser> {
  String _currentPath = defaultLocalPath;
  List<FileSystemEntity> _entries = [];
  Map<String, int> _fileSizes = {};
  bool _loading = true;
  String? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dir = Directory(_currentPath);
      final entities = await dir.list().toList();
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return p.basename(a.path).compareTo(p.basename(b.path));
      });

      // Collect file sizes in parallel to avoid sequential I/O delays
      final sizes = <String, int>{};
      final files = entities.whereType<File>().toList();
      final results = await Future.wait(
        files.map((f) => f.stat().then((s) => MapEntry(f.path, s.size))
            .catchError((_) => MapEntry(f.path, -1))),
      );
      for (final entry in results) {
        sizes[entry.key] = entry.value;
      }

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _entries = entities;
        _fileSizes = sizes;
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

  void _navigate(String path) {
    _currentPath = path;
    _loadDirectory();
  }

  void _navigateUp() {
    if (_currentPath == '/') return;
    final parent = Directory(_currentPath).parent.path;
    _currentPath = parent;
    _loadDirectory();
  }

  void _showContextMenu(BuildContext context, FileSystemEntity entity) {
    final path = entity.path;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy path'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: path));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied: $path')),
                );
              },
            ),
            if (widget.onSendToTerminal != null)
              ListTile(
                leading: const Icon(Icons.terminal),
                title: const Text('Send path to terminal'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSendToTerminal!(path);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDesktopContextMenu(
      FileSystemEntity entity, TapDownDetails details) async {
    final path = entity.path;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy path')),
        if (widget.onSendToTerminal != null)
          const PopupMenuItem(
              value: 'send', child: Text('Send path to terminal')),
      ],
    );
    if (!mounted || value == null) return;
    if (value == 'copy') {
      Clipboard.setData(ClipboardData(text: path));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied: $path')),
      );
    } else if (value == 'send') {
      widget.onSendToTerminal?.call(path);
    }
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
                          final entity = _entries[index];
                          final isDir = entity is Directory;
                          final size = _fileSizes[entity.path];
                          return FileItemTile(
                            name: p.basename(entity.path),
                            isDirectory: isDir,
                            subtitle: isDir
                                ? null
                                : (size != null && size >= 0)
                                    ? formatFileSize(size)
                                    : null,
                            onTap: isDir
                                ? () => _navigate(entity.path)
                                : () => _showContextMenu(context, entity),
                            onLongPress: () =>
                                _showContextMenu(context, entity),
                            onSecondaryTapDown: isDesktop
                                ? (details) => _showDesktopContextMenu(
                                    entity, details)
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
