import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:xterm/xterm.dart';
import '../../core/ssh/ssh_service_interface.dart';

class SshTerminalController {
  static final _ansiArrowUp    = Uint8List.fromList([27, 91, 65]);
  static final _ansiArrowDown  = Uint8List.fromList([27, 91, 66]);
  static final _ansiArrowRight = Uint8List.fromList([27, 91, 67]);
  static final _ansiArrowLeft  = Uint8List.fromList([27, 91, 68]);
  static final _ansiTab        = Uint8List.fromList([9]);
  static final _ansiEscape     = Uint8List.fromList([27]);

  final Terminal terminal;
  final SshServiceInterface _ssh;
  final Utf8Decoder _utf8Decoder = const Utf8Decoder(allowMalformed: true);
  StreamSubscription<Uint8List>? _outputSub;

  SshTerminalController({required SshServiceInterface ssh})
      : _ssh = ssh,
        terminal = Terminal(maxLines: 10000) {
    terminal.onOutput = (data) {
      _ssh.write(data);
    };

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      _ssh.resizePty(width, height);
    };

    _outputSub = _ssh.outputStream.listen((data) {
      terminal.write(_utf8Decoder.convert(data));
    });
  }

  void sendKey(TerminalKey key) {
    switch (key) {
      case TerminalKey.arrowUp:
        _ssh.writeBytes(_ansiArrowUp);
      case TerminalKey.arrowDown:
        _ssh.writeBytes(_ansiArrowDown);
      case TerminalKey.arrowRight:
        _ssh.writeBytes(_ansiArrowRight);
      case TerminalKey.arrowLeft:
        _ssh.writeBytes(_ansiArrowLeft);
      case TerminalKey.tab:
        _ssh.writeBytes(_ansiTab);
      case TerminalKey.escape:
        _ssh.writeBytes(_ansiEscape);
      default:
        break;
    }
  }

  void sendCtrl(String char) {
    final code = char.toUpperCase().codeUnitAt(0) - 64;
    if (code > 0 && code < 32) {
      _ssh.writeBytes(Uint8List.fromList([code]));
    }
  }

  void sendText(String text) {
    _ssh.write(text);
  }

  void dispose() {
    _outputSub?.cancel();
  }
}
