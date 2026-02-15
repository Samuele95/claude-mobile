import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/server_profile.dart';
import '../models/connection_state.dart';
import '../storage/key_manager.dart';

class SshService {
  final KeyManager _keyManager;

  SSHClient? _client;
  SSHSession? _shell;
  SshConnectionState _state = SshConnectionState.disconnected;
  ServerProfile? _activeProfile;

  final _stateController = StreamController<SshConnectionState>.broadcast();
  final _outputController = StreamController<Uint8List>.broadcast();

  Stream<SshConnectionState> get stateStream => _stateController.stream;
  Stream<Uint8List> get outputStream => _outputController.stream;
  SshConnectionState get state => _state;
  SSHClient? get client => _client;
  ServerProfile? get activeProfile => _activeProfile;

  SshService({required KeyManager keyManager}) : _keyManager = keyManager;

  void _setState(SshConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> connect(ServerProfile profile) async {
    if (_state.isActive) await disconnect();

    _activeProfile = profile;
    _setState(SshConnectionState.connecting);

    try {
      final keyPairs = await _keyManager.getProfileKeyPairs(profile.id);

      final socket = await SSHSocket.connect(
        profile.host,
        profile.port,
        timeout: const Duration(seconds: 10),
      );

      _client = SSHClient(
        socket,
        username: profile.username,
        identities: keyPairs,
        keepAliveInterval: const Duration(seconds: 30),
      );

      _shell = await _client!.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: 80,
          height: 24,
        ),
      );

      _shell!.stdout.listen(
        (data) => _outputController.add(data),
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );

      _shell!.stderr.listen(
        (data) => _outputController.add(data),
      );

      _setState(SshConnectionState.connected);
    } catch (e) {
      _setState(SshConnectionState.error);
      rethrow;
    }
  }

  void write(String data) {
    _shell?.write(Uint8List.fromList(utf8.encode(data)));
  }

  void writeBytes(Uint8List data) {
    _shell?.write(data);
  }

  void resizePty(int width, int height) {
    _shell?.resizeTerminal(width, height);
  }

  /// Execute a one-shot command (used by quick-prompt widget).
  Future<String> executeCommand(ServerProfile profile, String command) async {
    final keyPairs = await _keyManager.getProfileKeyPairs(profile.id);
    final socket = await SSHSocket.connect(
      profile.host,
      profile.port,
      timeout: const Duration(seconds: 10),
    );

    final client = SSHClient(
      socket,
      username: profile.username,
      identities: keyPairs,
    );

    try {
      final result = await client.run(command);
      return utf8.decode(result);
    } finally {
      client.close();
    }
  }

  Future<void> reconnect() async {
    if (_activeProfile == null) return;
    _setState(SshConnectionState.reconnecting);
    try {
      await connect(_activeProfile!);
    } catch (_) {
      _setState(SshConnectionState.error);
    }
  }

  void _handleDisconnect() {
    if (_state == SshConnectionState.disconnected) return;
    _setState(SshConnectionState.disconnected);
  }

  Future<void> disconnect() async {
    _shell?.close();
    _client?.close();
    _shell = null;
    _client = null;
    _setState(SshConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _outputController.close();
  }
}
