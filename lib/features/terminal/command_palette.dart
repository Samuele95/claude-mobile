import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommandPalette extends StatefulWidget {
  final void Function(String command) onSelect;

  const CommandPalette({super.key, required this.onSelect});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _searchController = TextEditingController();
  final _customController = TextEditingController();
  String _filter = '';

  static const _commands = [
    _Cmd('/help', 'Show help'),
    _Cmd('/clear', 'Clear conversation'),
    _Cmd('/compact', 'Compact context'),
    _Cmd('/cost', 'Show token usage'),
    _Cmd('/status', 'Show status'),
    _Cmd('/init', 'Initialize CLAUDE.md'),
    _Cmd('/review', 'Review changes'),
    _Cmd('/model', 'Switch model'),
    _Cmd('/logout', 'Log out of Claude'),
    _Cmd('/doctor', 'Check installation'),
  ];

  List<_Cmd> get _filtered => _filter.isEmpty
      ? _commands
      : _commands
          .where((c) =>
              c.command.contains(_filter) || c.description.contains(_filter))
          .toList();

  @override
  void dispose() {
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _runCustomCommand() {
    final cmd = _customController.text.trim();
    if (cmd.isEmpty) return;
    Navigator.of(context).pop();
    widget.onSelect(cmd);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Commands',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search commands...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) => setState(() => _filter = value),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length + 1, // +1 for custom command
              itemBuilder: (context, index) {
                if (index == filtered.length) {
                  // Custom command entry
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customController,
                            decoration: InputDecoration(
                              hintText: 'Run custom command...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                            ),
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13,
                            ),
                            onSubmitted: (_) => _runCustomCommand(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, size: 20),
                          onPressed: _runCustomCommand,
                        ),
                      ],
                    ),
                  );
                }

                final cmd = filtered[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    cmd.command,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(cmd.description),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    widget.onSelect(cmd.command);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Cmd {
  final String command;
  final String description;
  const _Cmd(this.command, this.description);
}
