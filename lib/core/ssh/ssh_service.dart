import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/server_profile.dart';
import '../models/connection_state.dart';
import '../storage/key_manager.dart';
import '../storage/host_key_store.dart';

import 'ssh_service_interface.dart';

export 'ssh_service_interface.dart' show PasswordProvider;

/// Exception thrown when a host key mismatch is detected (possible MITM).
class HostKeyMismatchException implements Exception {
  final String host;
  final int port;
  HostKeyMismatchException(this.host, this.port);

  @override
  String toString() =>
      'Host key for $host:$port has changed! This could indicate a '
      'man-in-the-middle attack. If you trust this change, delete the server '
      'and re-add it.';
}

class SshService implements SshServiceInterface {
  final KeyManager _keyManager;
  final HostKeyStore? _hostKeyStore;

  SSHClient? _client;
  SSHSession? _shell;
  SshConnectionState _state = SshConnectionState.disconnected;
  ServerProfile? _activeProfile;
  PasswordProvider? _passwordProvider;
  int _lastWidth = 80;
  int _lastHeight = 24;

  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  bool _disposed = false;
  bool _autoReconnect = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const _maxReconnectAttempts = 5;

  final _stateController = StreamController<SshConnectionState>.broadcast();
  final _outputController = StreamController<Uint8List>.broadcast();

  @override
  Stream<SshConnectionState> get stateStream => _stateController.stream;
  @override
  Stream<Uint8List> get outputStream => _outputController.stream;
  @override
  SshConnectionState get state => _state;
  @override
  bool get autoReconnect => _autoReconnect;
  @override
  ServerProfile? get activeProfile => _activeProfile;

  @override
  set autoReconnect(bool value) {
    _autoReconnect = value;
    if (!value) _reconnectAttempts = 0;
  }

  SshService({required KeyManager keyManager, HostKeyStore? hostKeyStore})
      : _keyManager = keyManager,
        _hostKeyStore = hostKeyStore;

  void _setState(SshConnectionState newState) {
    if (_disposed) return;
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> connect(
    ServerProfile profile, {
    String? password,
    PasswordProvider? passwordProvider,
    int initialWidth = 80,
    int initialHeight = 24,
  }) async {
    if (_state.isActive) await disconnect();

    // Clean up any lingering subscriptions from a previous connect attempt
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;

    _activeProfile = profile;
    if (passwordProvider != null) _passwordProvider = passwordProvider;
    _lastWidth = initialWidth;
    _lastHeight = initialHeight;
    _reconnectAttempts = 0;
    _setState(SshConnectionState.connecting);

    try {
      _setState(SshConnectionState.authenticating);
      _client = await _createClient(profile, password: password);

      _setState(SshConnectionState.startingShell);
      _shell = await _client!.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: initialWidth,
          height: initialHeight,
        ),
      );

      _stdoutSub = _shell!.stdout.listen(
        (data) => _outputController.add(data),
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );

      _stderrSub = _shell!.stderr.listen(
        (data) => _outputController.add(data),
      );

      _setState(SshConnectionState.connected);
    } catch (e) {
      _setState(SshConnectionState.error);
      rethrow;
    }
  }

  Future<SSHClient> _createClient(
    ServerProfile profile, {
    String? password,
  }) async {
    final socket = await SSHSocket.connect(
      profile.host,
      profile.port,
      timeout: const Duration(seconds: 10),
    );

    Future<bool> verifyHostKey(String type, Uint8List fingerprint) async {
      if (_hostKeyStore == null) return true;
      final result = await _hostKeyStore.verify(
        profile.host,
        profile.port,
        type,
        fingerprint,
      );
      if (result == HostKeyVerifyResult.mismatch) {
        throw HostKeyMismatchException(profile.host, profile.port);
      }
      return true; // trusted (first time) or matched
    }

    if (profile.authMethod == AuthMethod.password && password != null) {
      return SSHClient(
        socket,
        username: profile.username,
        onPasswordRequest: () => password,
        onVerifyHostKey: verifyHostKey,
        keepAliveInterval: const Duration(seconds: 30),
      );
    }

    final keyPairs = await _keyManager.getProfileKeyPairs(profile.id);
    return SSHClient(
      socket,
      username: profile.username,
      identities: keyPairs,
      onVerifyHostKey: verifyHostKey,
      keepAliveInterval: const Duration(seconds: 30),
    );
  }

  @override
  void write(String data) {
    _shell?.write(Uint8List.fromList(utf8.encode(data)));
  }

  @override
  void writeBytes(Uint8List data) {
    _shell?.write(data);
  }

  @override
  void resizePty(int width, int height) {
    _lastWidth = width;
    _lastHeight = height;
    _shell?.resizeTerminal(width, height);
  }

  /// Execute a one-shot command (used by quick-prompt widget).
  @override
  Future<String> executeCommand(
    ServerProfile profile,
    String command, {
    String? password,
  }) async {
    final client = await _createClient(profile, password: password);

    try {
      final result = await client.run(command);
      return utf8.decode(result);
    } finally {
      client.close();
    }
  }

  /// Opens an SFTP session on the current SSH connection.
  /// Throws StateError if not connected.
  @override
  Future<SftpClient> openSftp() async {
    if (_client == null) throw StateError('Not connected');
    return _client!.sftp();
  }

  @override
  Future<void> reconnect() async {
    if (_disposed || _activeProfile == null) return;
    final wasAutoReconnect = _autoReconnect;
    _setState(SshConnectionState.reconnecting);
    try {
      // Fetch password on-demand from secure storage via callback
      final password = await _passwordProvider?.call();
      await connect(
        _activeProfile!,
        password: password,
        initialWidth: _lastWidth,
        initialHeight: _lastHeight,
      );
      _autoReconnect = wasAutoReconnect;
    } catch (e) {
      developer.log('Reconnect failed: $e', name: 'SshService');
      _autoReconnect = wasAutoReconnect;
      _setState(SshConnectionState.error);
    }
  }

  void _handleDisconnect() {
    if (_state == SshConnectionState.disconnected) return;
    _setState(SshConnectionState.disconnected);

    if (_autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      final delay = Duration(
          seconds: 1 << _reconnectAttempts); // 1s, 2s, 4s, 8s, 16s
      _reconnectAttempts++;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () async {
        if (!_disposed && _autoReconnect) {
          await reconnect();
        }
      });
    }
  }

  @override
  Future<void> disconnect() async {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _shell?.close();
    _client?.close();
    _shell = null;
    _client = null;
    _setState(SshConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await disconnect();
    _stateController.close();
    _outputController.close();
  }
}
