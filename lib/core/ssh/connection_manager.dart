import 'dart:async';
import 'dart:developer' as developer;
import '../models/session.dart';
import '../models/server_profile.dart';
import '../models/connection_state.dart';
import '../storage/key_manager.dart';
import '../storage/host_key_store.dart';
import '../utils/command_builder.dart';
import 'ssh_service.dart';
import 'sftp_service.dart';
import 'ssh_service_interface.dart';
import 'sftp_service_interface.dart';

import 'connection_manager_interface.dart';

/// Factory typedef for creating SSH service instances.
typedef SshServiceFactory = SshServiceInterface Function();

/// Factory typedef for creating SFTP service instances.
typedef SftpServiceFactory = SftpServiceInterface Function();

/// Callback for initializing SFTP from an SSH session.
typedef SftpInitializer = Future<void> Function(
    SshServiceInterface ssh, SftpServiceInterface sftp);

class ConnectionManager implements ConnectionManagerInterface {
  final SshServiceFactory _sshFactory;
  final SftpServiceFactory _sftpFactory;
  final SftpInitializer _sftpInitializer;
  final Map<String, SshServiceInterface> _sshServices = {};
  final Map<String, SftpServiceInterface> _sftpServices = {};
  final Map<String, Session> _sessions = {};
  final Map<String, StreamSubscription> _stateSubscriptions = {};
  bool _creatingSession = false;
  bool _disposed = false;

  final _sessionsController = StreamController<List<Session>>.broadcast();

  @override
  Stream<List<Session>> get sessionsStream => _sessionsController.stream;
  @override
  List<Session> get sessions => _sessions.values.toList();

  ConnectionManager({
    required KeyManager keyManager,
    HostKeyStore? hostKeyStore,
    SshServiceFactory? sshFactory,
    SftpServiceFactory? sftpFactory,
    SftpInitializer? sftpInitializer,
  })  : _sshFactory = sshFactory ??
            (() => SshService(keyManager: keyManager, hostKeyStore: hostKeyStore)),
        _sftpFactory = sftpFactory ?? SftpService.new,
        _sftpInitializer = sftpInitializer ?? _defaultSftpInit {
    // Emit initial empty list so StreamProvider starts with data, not loading state
    _sessionsController.add([]);
  }

  static Future<void> _defaultSftpInit(
      SshServiceInterface ssh, SftpServiceInterface sftp) async {
    final sftpClient = await (ssh as SshService).openSftp();
    sftp.initializeWithClient(sftpClient);
  }

  @override
  SshServiceInterface? getSsh(String sessionId) => _sshServices[sessionId];
  @override
  SftpServiceInterface? getSftp(String sessionId) => _sftpServices[sessionId];

  @override
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
      final ssh = _sshFactory();
      final sftp = _sftpFactory();

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
        await _sftpInitializer(ssh, sftp);
      } catch (e) {
        developer.log('SFTP unavailable: $e', name: 'ConnectionManager');
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

  @override
  Future<void> closeSession(String sessionId) async {
    await _stateSubscriptions.remove(sessionId)?.cancel();
    final ssh = _sshServices.remove(sessionId);
    final sftp = _sftpServices.remove(sessionId);
    _sessions.remove(sessionId);

    await ssh?.dispose();
    sftp?.dispose();
    _emitSessions();
  }

  @override
  Future<void> reconnectSession(String sessionId) async {
    final ssh = _sshServices[sessionId];
    if (ssh == null) return;
    await ssh.reconnect();

    // Re-initialize SFTP after reconnect
    final sftp = _sftpServices[sessionId];
    if (sftp != null) {
      try {
        await _sftpInitializer(ssh, sftp);
      } catch (e) {
        developer.log('SFTP unavailable after reconnect: $e', name: 'ConnectionManager');
      }
    }
  }

  void _emitSessions() {
    if (!_disposed) _sessionsController.add(_sessions.values.toList());
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    // Copy values before iterating to avoid concurrent modification
    // if closeSession is called during dispose cleanup.
    for (final sub in List.of(_stateSubscriptions.values)) {
      await sub.cancel();
    }
    _stateSubscriptions.clear();
    for (final ssh in List.of(_sshServices.values)) {
      await ssh.dispose();
    }
    for (final sftp in List.of(_sftpServices.values)) {
      sftp.dispose();
    }
    _sshServices.clear();
    _sftpServices.clear();
    _sessions.clear();
    _sessionsController.close();
  }
}
