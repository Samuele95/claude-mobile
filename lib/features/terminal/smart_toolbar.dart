import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../settings/preferences_provider.dart';
import 'terminal_controller.dart';

class SmartToolbar extends ConsumerStatefulWidget {
  final SshTerminalController controller;
  final VoidCallback onAttachFile;
  final VoidCallback onCommandPalette;
  final VoidCallback onSessionMenu;

  const SmartToolbar({
    super.key,
    required this.controller,
    required this.onAttachFile,
    required this.onCommandPalette,
    required this.onSessionMenu,
  });

  @override
  ConsumerState<SmartToolbar> createState() => _SmartToolbarState();
}

class _SmartToolbarState extends ConsumerState<SmartToolbar> {
  bool _ctrlActive = false;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  String _prevText = '';

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onKey(TerminalKey key) {
    if (ref.read(preferencesProvider).haptics) {
      HapticFeedback.lightImpact();
    }
    widget.controller.sendKey(key);
  }

  void _toggleCtrl() {
    if (ref.read(preferencesProvider).haptics) {
      HapticFeedback.mediumImpact();
    }
    setState(() => _ctrlActive = !_ctrlActive);
  }

  Future<void> _onPaste() async {
    if (ref.read(preferencesProvider).haptics) {
      HapticFeedback.lightImpact();
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      widget.controller.sendText(data.text!);
    }
  }

  void _onInputChanged(String text) {
    if (text.length > _prevText.length) {
      // Characters were added — send the new characters
      final added = text.substring(_prevText.length);
      if (_ctrlActive) {
        for (final c in added.runes) {
          widget.controller.sendCtrl(String.fromCharCode(c));
        }
        setState(() => _ctrlActive = false);
      } else {
        widget.controller.sendText(added);
      }
    } else if (text.length < _prevText.length) {
      // Backspace — send delete character
      final deleted = _prevText.length - text.length;
      for (var i = 0; i < deleted; i++) {
        widget.controller.sendText('\x7f'); // DEL
      }
    }
    _prevText = text;
  }

  void _onInputSubmitted(String _) {
    widget.controller.sendText('\n');
    _inputController.clear();
    _prevText = '';
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input row
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
              Text(
                _ctrlActive ? 'C-' : '\$',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ctrlActive
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  autofocus: true,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type here...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                  ),
                  textInputAction: TextInputAction.send,
                  onChanged: _onInputChanged,
                  onSubmitted: _onInputSubmitted,
                ),
              ),
            ],
          ),
        ),
        // Toolbar buttons
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              _ToolbarButton(
                icon: Icons.tab,
                onTap: widget.onSessionMenu,
                tooltip: 'Sessions',
              ),
              _ToolbarDivider(),
              _ToolbarButton(
                icon: Icons.keyboard_arrow_left,
                onTap: () => _onKey(TerminalKey.arrowLeft),
                tooltip: 'Left',
              ),
              _ToolbarButton(
                icon: Icons.keyboard_arrow_right,
                onTap: () => _onKey(TerminalKey.arrowRight),
                tooltip: 'Right',
              ),
              _ToolbarButton(
                icon: Icons.keyboard_arrow_up,
                onTap: () => _onKey(TerminalKey.arrowUp),
                tooltip: 'Up',
              ),
              _ToolbarButton(
                icon: Icons.keyboard_arrow_down,
                onTap: () => _onKey(TerminalKey.arrowDown),
                tooltip: 'Down',
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
                icon: Icons.content_paste,
                onTap: _onPaste,
                tooltip: 'Paste',
              ),
              _ToolbarButton(
                icon: Icons.terminal,
                onTap: widget.onCommandPalette,
                tooltip: 'Commands',
              ),
              _ToolbarButton(
                icon: Icons.attach_file,
                onTap: widget.onAttachFile,
                tooltip: 'Attach file',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _ToolbarButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    Widget child = Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }
    return child;
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
