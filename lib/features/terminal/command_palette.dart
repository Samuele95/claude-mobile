import 'package:flutter/material.dart';

class CommandPalette extends StatelessWidget {
  final void Function(String command) onSelect;

  const CommandPalette({super.key, required this.onSelect});

  static const _commands = [
    _Cmd('/help', 'Show help'),
    _Cmd('/clear', 'Clear conversation'),
    _Cmd('/compact', 'Compact context'),
    _Cmd('/cost', 'Show token usage'),
    _Cmd('/status', 'Show status'),
    _Cmd('/init', 'Initialize CLAUDE.md'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Commands',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _commands.length,
              itemBuilder: (context, index) {
                final cmd = _commands[index];
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
                    Navigator.of(context).pop();
                    onSelect(cmd.command);
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
