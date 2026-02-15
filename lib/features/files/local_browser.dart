import 'dart:io';
import 'package:flutter/material.dart';
import 'file_item_tile.dart';

class LocalBrowser extends StatefulWidget {
  const LocalBrowser({super.key});

  @override
  State<LocalBrowser> createState() => _LocalBrowserState();
}

class _LocalBrowserState extends State<LocalBrowser> {
  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _entries = [];
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
      final dir = Directory(_currentPath);
      final entities = await dir.list().toList();
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.split('/').last.compareTo(b.path.split('/').last);
      });
      setState(() {
        _entries = entities;
        _loading = false;
      });
    } catch (e) {
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
    final parent = Directory(_currentPath).parent.path;
    _currentPath = parent;
    _loadDirectory();
  }

  String _fileName(FileSystemEntity entity) => entity.path.split('/').last;

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
                onPressed: _navigateUp,
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
                          return FileItemTile(
                            name: _fileName(entity),
                            isDirectory: isDir,
                            subtitle: isDir
                                ? null
                                : _formatSize((entity as File).lengthSync()),
                            onTap: isDir
                                ? () => _navigate(entity.path)
                                : () {},
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
