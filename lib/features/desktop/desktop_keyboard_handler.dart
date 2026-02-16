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

  const DesktopKeyboardHandler({
    super.key,
    required this.child,
    required this.onNewSession,
    required this.onCloseSession,
    required this.onNextSession,
    required this.onPreviousSession,
    required this.onToggleFilePanel,
    required this.onCommandPalette,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyT,
        ): const _NewSessionIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyW,
        ): const _CloseSessionIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.tab,
        ): const _NextSessionIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.tab,
        ): const _PreviousSessionIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyB,
        ): const _ToggleFilePanelIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyK,
        ): const _CommandPaletteIntent(),
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
