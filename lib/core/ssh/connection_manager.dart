import 'dart:async';
import '../models/session.dart';
import '../models/server_profile.dart';
import '../models/connection_state.dart';
import '../storage/key_manager.dart';
import '../storage/host_key_store.dart';
import '../utils/command_builder.dart';
import 'ssh_service.dart';
import 'sftp_service.dart';

class ConnectionManager {
  final KeyManager _keyManager;
  final HostKeyStore? _hostKeyStore;
  final Map<String, SshService> _sshServices = {};
  final Map<String, SftpService> _sftpServices = {};
  final Map<String, Session> _sessions = {};
  final Map<String, StreamSubscription> _stateSubscriptions = {};
  bool _creatingSession = false;
  bool _disposed = false;

  final _sessionsController = StreamController<List<Session>>.broadcast();

  Stream<List<Session>> get sessionsStream => _sessionsController.stream;
  List<Session> get sessions => _sessions.values.toList();

  ConnectionManager({required KeyManager keyManager, HostKeyStore? hostKeyStore})
      : _keyManager = keyManager,
        _hostKeyStore = hostKeyStore {
    // Emit initial empty list so StreamProvider starts with data, not loading state
    _sessionsController.add([]);
  }

  SshService? getSsh(String sessionId) => _sshServices[sessionId];
  SftpService? getSftp(String sessionId) => _sftpServices[sessionId];

  Future<String> createSession(
    ServerProfile profile, {
    String? password,
    PasswordProvider? passwordProvider,
    bool autoReconnect = true,
  }) async {
    // Guard against concurrent session creation (e.g. double-tap)
    if (_creatingSession) {
      throw StateError('Session creation already in progress');
    }
    _creatingSession = true;

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final ssh = SshService(keyManager: _keyManager, hostKeyStore: _hostKeyStore);
      final sftp = SftpService();

      ssh.autoReconnect = autoReconnect;
      _sshServices[sessionId] = ssh;
      _sftpServices[sessionId] = sftp;

      final session = Session(
        id: sessionId,
        profile: profile,
        state: SshConnectionState.connecting,
        createdAt: DateTime.now(),
      );
      _sessions[sessionId] = session;
      _emitSessions();

      // Listen to state changes from SshService
      _stateSubscriptions[sessionId] = ssh.stateStream.listen((state) {
        final existing = _sessions[sessionId];
        if (existing != null) {
          _sessions[sessionId] = existing.copyWith(state: state);
          _emitSessions();
        }
      });

      await ssh.connect(
        profile,
        password: password,
        passwordProvider: passwordProvider,
      );

      // Run startup command — longer delay ensures shell fully initializes
      // (login profile, MOTD, etc.) before we send the claude command.
      final startupCmd = buildStartupCommand(profile);
      if (startupCmd.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));
        ssh.write('$startupCmd\n');
      }

      // Initialize SFTP — allow session to survive even if SFTP fails
      try {
        final sftpClient = await ssh.openSftp();
        sftp.initializeWithClient(sftpClient);
      } catch (_) {
        // SFTP unavailable; session continues without file management
      }

      return sessionId;
    } catch (_) {
      // Clean up on failure so we don't leak a half-initialized session
      await closeSession(sessionId);
      rethrow;
    } finally {
      _creatingSession = false;
    }
  }

  Future<void> closeSession(String sessionId) async {
    await _stateSubscriptions.remove(sessionId)?.cancel();
    final ssh = _sshServices.remove(sessionId);
    final sftp = _sftpServices.remove(sessionId);
    _sessions.remove(sessionId);

    await ssh?.dispose();
    sftp?.dispose();
    _emitSessions();
  }

  Future<void> reconnectSession(String sessionId) async {
    final ssh = _sshServices[sessionId];
    if (ssh == null) return;
    await ssh.reconnect();

    // Re-initialize SFTP after reconnect
    final sftp = _sftpServices[sessionId];
    if (sftp != null) {
      try {
        final sftpClient = await ssh.openSftp();
        sftp.initializeWithClient(sftpClient);
      } catch (_) {
        // SFTP unavailable after reconnect; file panel will show error
      }
    }
  }

  void _emitSessions() {
    if (!_disposed) _sessionsController.add(_sessions.values.toList());
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final sub in _stateSubscriptions.values) {
      await sub.cancel();
    }
    _stateSubscriptions.clear();
    for (final ssh in _sshServices.values) {
      await ssh.dispose();
    }
    for (final sftp in _sftpServices.values) {
      sftp.dispose();
    }
    _sshServices.clear();
    _sftpServices.clear();
    _sessions.clear();
    _sessionsController.close();
  }
}
