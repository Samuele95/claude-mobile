import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:xterm/xterm.dart';
import '../../core/ssh/ssh_service.dart';

class SshTerminalController {
  final Terminal terminal;
  final SshService _ssh;
  final Utf8Decoder _utf8Decoder = const Utf8Decoder(allowMalformed: true);
  StreamSubscription<Uint8List>? _outputSub;

  SshTerminalController({required SshService ssh})
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
        _ssh.writeBytes(Uint8List.fromList([27, 91, 65]));
      case TerminalKey.arrowDown:
        _ssh.writeBytes(Uint8List.fromList([27, 91, 66]));
      case TerminalKey.arrowRight:
        _ssh.writeBytes(Uint8List.fromList([27, 91, 67]));
      case TerminalKey.arrowLeft:
        _ssh.writeBytes(Uint8List.fromList([27, 91, 68]));
      case TerminalKey.tab:
        _ssh.writeBytes(Uint8List.fromList([9]));
      case TerminalKey.escape:
        _ssh.writeBytes(Uint8List.fromList([27]));
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
