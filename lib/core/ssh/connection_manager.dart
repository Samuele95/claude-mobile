import 'dart:async';
import '../models/session.dart';
import '../models/server_profile.dart';
import '../models/connection_state.dart';
import '../storage/key_manager.dart';
import 'ssh_service.dart';
import 'sftp_service.dart';

class ConnectionManager {
  final KeyManager _keyManager;
  final Map<String, SshService> _sshServices = {};
  final Map<String, SftpService> _sftpServices = {};
  final Map<String, Session> _sessions = {};

  final _sessionsController = StreamController<List<Session>>.broadcast();

  Stream<List<Session>> get sessionsStream => _sessionsController.stream;
  List<Session> get sessions => _sessions.values.toList();

  ConnectionManager({required KeyManager keyManager})
      : _keyManager = keyManager;

  SshService? getSsh(String sessionId) => _sshServices[sessionId];
  SftpService? getSftp(String sessionId) => _sftpServices[sessionId];

  Future<String> createSession(
    ServerProfile profile, {
    String? password,
  }) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final ssh = SshService(keyManager: _keyManager);
    final sftp = SftpService();

    ssh.autoReconnect = true;
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
    ssh.stateStream.listen((state) {
      final existing = _sessions[sessionId];
      if (existing != null) {
        _sessions[sessionId] = existing.copyWith(state: state);
        _emitSessions();
      }
    });

    await ssh.connect(profile, password: password);

    // Run startup command
    if (profile.startupCommand.isNotEmpty) {
      ssh.write('${profile.startupCommand}\n');
    }

    // Initialize SFTP
    if (ssh.client != null) {
      await sftp.initialize(ssh.client!);
    }

    return sessionId;
  }

  Future<void> closeSession(String sessionId) async {
    final ssh = _sshServices.remove(sessionId);
    final sftp = _sftpServices.remove(sessionId);
    _sessions.remove(sessionId);

    ssh?.dispose();
    sftp?.dispose();
    _emitSessions();
  }

  Future<void> reconnectSession(String sessionId) async {
    final ssh = _sshServices[sessionId];
    if (ssh == null) return;
    await ssh.reconnect();

    // Re-initialize SFTP after reconnect
    final sftp = _sftpServices[sessionId];
    if (sftp != null && ssh.client != null) {
      await sftp.initialize(ssh.client!);
    }
  }

  void _emitSessions() {
    _sessionsController.add(_sessions.values.toList());
  }

  void dispose() {
    for (final ssh in _sshServices.values) {
      ssh.dispose();
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
