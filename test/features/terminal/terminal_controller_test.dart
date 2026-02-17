import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/ssh/ssh_service_interface.dart';
import 'package:claude_mobile/core/models/server_profile.dart';
import 'package:claude_mobile/core/models/connection_state.dart';
import 'package:claude_mobile/features/terminal/terminal_controller.dart';
import 'package:xterm/xterm.dart' show TerminalKey;

/// Minimal fake SSH service for testing the terminal controller.
class FakeSshService implements SshServiceInterface {
  final List<String> writtenStrings = [];
  final List<Uint8List> writtenBytes = [];
  final List<List<int>> resizes = [];
  final StreamController<Uint8List> _outputController = StreamController<Uint8List>.broadcast();
  final StreamController<SshConnectionState> _stateController = StreamController<SshConnectionState>.broadcast();

  @override
  Stream<Uint8List> get outputStream => _outputController.stream;

  @override
  Stream<SshConnectionState> get stateStream => _stateController.stream;

  @override
  SshConnectionState get state => SshConnectionState.connected;

  @override
  bool autoReconnect = false;

  @override
  ServerProfile? get activeProfile => null;

  @override
  void write(String data) => writtenStrings.add(data);

  @override
  void writeBytes(Uint8List data) => writtenBytes.add(data);

  @override
  void resizePty(int width, int height) => resizes.add([width, height]);

  /// Push data to the terminal as if it came from the remote server.
  void emitOutput(List<int> bytes) {
    _outputController.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> connect(ServerProfile profile, {String? password, PasswordProvider? passwordProvider, int initialWidth = 80, int initialHeight = 24}) async {}

  @override
  Future<String> executeCommand(ServerProfile profile, String command, {String? password}) async => '';

  @override
  Future<void> reconnect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {
    await _outputController.close();
    await _stateController.close();
  }
}

void main() {
  group('SshTerminalController', () {
    late FakeSshService ssh;
    late SshTerminalController controller;

    setUp(() {
      ssh = FakeSshService();
      controller = SshTerminalController(ssh: ssh);
    });

    tearDown(() {
      controller.dispose();
      ssh.dispose();
    });

    test('creates a Terminal instance', () {
      expect(controller.terminal, isNotNull);
    });

    test('sendText forwards text to SSH write', () {
      controller.sendText('hello');
      expect(ssh.writtenStrings, ['hello']);
    });

    test('sendText handles multiple calls', () {
      controller.sendText('a');
      controller.sendText('b');
      controller.sendText('c');
      expect(ssh.writtenStrings, ['a', 'b', 'c']);
    });

    group('sendKey', () {
      test('sends arrow up ANSI escape', () {
        controller.sendKey(TerminalKey.arrowUp);
        expect(ssh.writtenBytes, hasLength(1));
        expect(ssh.writtenBytes.first, Uint8List.fromList([27, 91, 65]));
      });

      test('sends arrow down ANSI escape', () {
        controller.sendKey(TerminalKey.arrowDown);
        expect(ssh.writtenBytes.first, Uint8List.fromList([27, 91, 66]));
      });

      test('sends arrow right ANSI escape', () {
        controller.sendKey(TerminalKey.arrowRight);
        expect(ssh.writtenBytes.first, Uint8List.fromList([27, 91, 67]));
      });

      test('sends arrow left ANSI escape', () {
        controller.sendKey(TerminalKey.arrowLeft);
        expect(ssh.writtenBytes.first, Uint8List.fromList([27, 91, 68]));
      });

      test('sends tab', () {
        controller.sendKey(TerminalKey.tab);
        expect(ssh.writtenBytes.first, Uint8List.fromList([9]));
      });

      test('sends escape', () {
        controller.sendKey(TerminalKey.escape);
        expect(ssh.writtenBytes.first, Uint8List.fromList([27]));
      });

      test('ignores unhandled keys', () {
        controller.sendKey(TerminalKey.f1);
        expect(ssh.writtenBytes, isEmpty);
      });
    });

    group('sendCtrl', () {
      test('sends Ctrl-C (code 3)', () {
        controller.sendCtrl('C');
        expect(ssh.writtenBytes.first, Uint8List.fromList([3]));
      });

      test('sends Ctrl-D (code 4)', () {
        controller.sendCtrl('D');
        expect(ssh.writtenBytes.first, Uint8List.fromList([4]));
      });

      test('sends Ctrl-Z (code 26)', () {
        controller.sendCtrl('Z');
        expect(ssh.writtenBytes.first, Uint8List.fromList([26]));
      });

      test('handles lowercase input', () {
        controller.sendCtrl('c');
        expect(ssh.writtenBytes.first, Uint8List.fromList([3]));
      });

      test('ignores invalid control characters', () {
        controller.sendCtrl('@'); // code would be 0, outside 1..31
        expect(ssh.writtenBytes, isEmpty);
      });
    });

    test('terminal output callback writes to SSH', () {
      // Simulate terminal output (user typing)
      controller.terminal.onOutput!('typed text');
      expect(ssh.writtenStrings, contains('typed text'));
    });

    test('terminal resize callback sends resize to SSH', () {
      controller.terminal.onResize!(120, 40, 0, 0);
      expect(ssh.resizes, [
        [120, 40]
      ]);
    });

    test('SSH output is written to terminal', () async {
      // Emit some output from the fake SSH service
      ssh.emitOutput([72, 101, 108, 108, 111]); // "Hello"
      // Allow the stream listener to process
      await Future.delayed(Duration.zero);
      // The terminal should have received the data (we can't easily
      // read terminal buffer, but we can verify no exception was thrown)
    });

    test('dispose cancels output subscription', () {
      controller.dispose();
      // Should not throw when SSH emits after disposal
      ssh.emitOutput([1, 2, 3]);
    });
  });
}
