import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DesktopKeyboardHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback onNewSession;
  final VoidCallback onCloseSession;
  final VoidCallback onNextSession;
  final VoidCallback onPreviousSession;
  final VoidCallback onToggleFilePanel;
  final VoidCallback onCommandPalette;
  final VoidCallback? onShowShortcuts;

  const DesktopKeyboardHandler({
    super.key,
    required this.child,
    required this.onNewSession,
    required this.onCloseSession,
    required this.onNextSession,
    required this.onPreviousSession,
    required this.onToggleFilePanel,
    required this.onCommandPalette,
    this.onShowShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyT,
            control: true, shift: true): const _NewSessionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyW,
            control: true, shift: true): const _CloseSessionIntent(),
        const SingleActivator(LogicalKeyboardKey.tab,
            control: true): const _NextSessionIntent(),
        const SingleActivator(LogicalKeyboardKey.tab,
            control: true, shift: true): const _PreviousSessionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB,
            control: true, shift: true): const _ToggleFilePanelIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK,
            control: true, shift: true): const _CommandPaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.slash,
            control: true, shift: true): const _ShowShortcutsIntent(),
      },
      child: Actions(
        actions: {
          _NewSessionIntent: CallbackAction<_NewSessionIntent>(
            onInvoke: (_) {
              onNewSession();
              return null;
            },
          ),
          _CloseSessionIntent: CallbackAction<_CloseSessionIntent>(
            onInvoke: (_) {
              onCloseSession();
              return null;
            },
          ),
          _NextSessionIntent: CallbackAction<_NextSessionIntent>(
            onInvoke: (_) {
              onNextSession();
              return null;
            },
          ),
          _PreviousSessionIntent: CallbackAction<_PreviousSessionIntent>(
            onInvoke: (_) {
              onPreviousSession();
              return null;
            },
          ),
          _ToggleFilePanelIntent: CallbackAction<_ToggleFilePanelIntent>(
            onInvoke: (_) {
              onToggleFilePanel();
              return null;
            },
          ),
          _CommandPaletteIntent: CallbackAction<_CommandPaletteIntent>(
            onInvoke: (_) {
              onCommandPalette();
              return null;
            },
          ),
          _ShowShortcutsIntent: CallbackAction<_ShowShortcutsIntent>(
            onInvoke: (_) {
              onShowShortcuts?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _NewSessionIntent extends Intent {
  const _NewSessionIntent();
}

class _CloseSessionIntent extends Intent {
  const _CloseSessionIntent();
}

class _NextSessionIntent extends Intent {
  const _NextSessionIntent();
}

class _PreviousSessionIntent extends Intent {
  const _PreviousSessionIntent();
}

class _ToggleFilePanelIntent extends Intent {
  const _ToggleFilePanelIntent();
}

class _CommandPaletteIntent extends Intent {
  const _CommandPaletteIntent();
}

class _ShowShortcutsIntent extends Intent {
  const _ShowShortcutsIntent();
}

/// Static list of keyboard shortcuts for display in help dialogs.
const keyboardShortcuts = [
  ('Ctrl+Shift+T', 'New session'),
  ('Ctrl+Shift+W', 'Close session'),
  ('Ctrl+Tab', 'Next session'),
  ('Ctrl+Shift+Tab', 'Previous session'),
  ('Ctrl+Shift+B', 'Toggle file panel'),
  ('Ctrl+Shift+K', 'Command palette'),
  ('Ctrl+Shift+/', 'Keyboard shortcuts'),
];
