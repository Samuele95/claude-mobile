import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import 'terminal_controller.dart';

class SmartToolbar extends StatefulWidget {
  final SshTerminalController controller;
  final VoidCallback onAttachFile;
  final VoidCallback onCommandPalette;

  const SmartToolbar({
    super.key,
    required this.controller,
    required this.onAttachFile,
    required this.onCommandPalette,
  });

  @override
  State<SmartToolbar> createState() => _SmartToolbarState();
}

class _SmartToolbarState extends State<SmartToolbar> {
  bool _ctrlActive = false;

  void _onKey(TerminalKey key) {
    HapticFeedback.lightImpact();
    widget.controller.sendKey(key);
  }

  void _toggleCtrl() {
    HapticFeedback.mediumImpact();
    setState(() => _ctrlActive = !_ctrlActive);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.keyboard_arrow_left,
            onTap: () => _onKey(TerminalKey.arrowLeft),
          ),
          _ToolbarButton(
            icon: Icons.keyboard_arrow_right,
            onTap: () => _onKey(TerminalKey.arrowRight),
          ),
          _ToolbarButton(
            icon: Icons.keyboard_arrow_up,
            onTap: () => _onKey(TerminalKey.arrowUp),
          ),
          _ToolbarButton(
            icon: Icons.keyboard_arrow_down,
            onTap: () => _onKey(TerminalKey.arrowDown),
          ),
          _ToolbarDivider(),
          _ToolbarTextButton(
            label: 'Tab',
            onTap: () => _onKey(TerminalKey.tab),
          ),
          _ToolbarTextButton(
            label: 'Esc',
            onTap: () => _onKey(TerminalKey.escape),
          ),
          _ToolbarTextButton(
            label: 'Ctrl',
            active: _ctrlActive,
            onTap: _toggleCtrl,
          ),
          _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.terminal,
            onTap: widget.onCommandPalette,
          ),
          _ToolbarButton(
            icon: Icons.attach_file,
            onTap: widget.onAttachFile,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _ToolbarTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ToolbarTextButton({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
