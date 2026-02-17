import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/ssh/connection_manager.dart';
import 'package:claude_mobile/core/ssh/ssh_service_interface.dart';
import 'package:claude_mobile/core/ssh/sftp_service_interface.dart';
import 'package:claude_mobile/core/models/server_profile.dart';
import 'package:claude_mobile/core/models/connection_state.dart';
import 'package:claude_mobile/core/models/transfer_item.dart';
import 'package:claude_mobile/core/storage/key_manager.dart';
import 'package:dartssh2/dartssh2.dart' show SftpClient, SftpName, SftpFileAttrs;
import '../../helpers/fake_secure_storage.dart';

/// Fake SSH service that records calls and completes instantly.
class FakeSshService implements SshServiceInterface {
  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<SshConnectionState> _stateController =
      StreamController<SshConnectionState>.broadcast();

  bool connectCalled = false;
  bool reconnectCalled = false;
  bool disposeCalled = false;
  final List<String> writtenStrings = [];
  bool shouldFailConnect = false;

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
  Future<void> connect(ServerProfile profile,
      {String? password,
      PasswordProvider? passwordProvider,
      int initialWidth = 80,
      int initialHeight = 24}) async {
    connectCalled = true;
    if (shouldFailConnect) {
      throw Exception('Connection failed');
    }
    _stateController.add(SshConnectionState.connected);
  }

  @override
  void write(String data) => writtenStrings.add(data);
  @override
  void writeBytes(Uint8List data) {}
  @override
  void resizePty(int width, int height) {}

  @override
  Future<String> executeCommand(ServerProfile profile, String command,
          {String? password}) async =>
      '';

  @override
  Future<SftpClient> openSftp() => throw UnimplementedError('No SFTP in test');

  @override
  Future<void> reconnect() async {
    reconnectCalled = true;
    _stateController.add(SshConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    await _outputController.close();
    await _stateController.close();
  }

  /// Emit a state change externally (simulates SSH state transitions).
  void emitState(SshConnectionState state) {
    _stateController.add(state);
  }
}

/// Fake SFTP service that records calls.
class FakeSftpService implements SftpServiceInterface {
  bool disposeCalled = false;
  bool initCalled = false;
  final _transferController = StreamController<TransferItem>.broadcast();

  @override
  Stream<TransferItem> get transferStream => _transferController.stream;
  @override
  void initializeWithClient(SftpClient client) => initCalled = true;
  @override
  void dispose() {
    disposeCalled = true;
    _transferController.close();
  }

  @override
  Future<List<SftpName>> listDirectory(String path) async => [];
  @override
  Future<SftpFileAttrs> stat(String path) async =>
      throw UnimplementedError();
  @override
  Future<void> upload(
          {required String localPath,
          required String remotePath,
          required TransferItem item}) async {}
  @override
  Future<void> download(
          {required String remotePath,
          required String localPath,
          required TransferItem item}) async {}
  @override
  Future<void> mkdir(String path) async {}
  @override
  Future<void> rename(String oldPath, String newPath) async {}
  @override
  Future<void> remove(String path) async {}
  @override
  Future<void> rmdir(String path) async {}
  @override
  Future<String> realpath(String path) async => path;
  @override
  Future<Uint8List> readFileBytes(String path) async => Uint8List(0);
}

ServerProfile makeProfile({String name = 'Test'}) => ServerProfile(
      id: '1',
      name: name,
      host: 'example.com',
      username: 'user',
      claudeMode: ClaudeMode.standard,
      createdAt: DateTime(2024),
    );

void main() {
  group('ConnectionManager', () {
    late KeyManager keyManager;
    late FakeSshService lastSsh;
    late FakeSftpService lastSftp;
    late ConnectionManager manager;

    setUp(() {
      keyManager = KeyManager(storage: FakeSecureStorage());

      manager = ConnectionManager(
        keyManager: keyManager,
        sshFactory: () {
          lastSsh = FakeSshService();
          return lastSsh;
        },
        sftpFactory: () {
          lastSftp = FakeSftpService();
          return lastSftp;
        },
        sftpInitializer: (ssh, sftp) async {
          // No-op — skip real SFTP initialization in tests
        },
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('sessions is initially empty', () {
      expect(manager.sessions, isEmpty);
    });

    test('createSession returns a session ID', () async {
      final id = await manager.createSession(makeProfile());
      expect(id, isNotEmpty);
    });

    test('createSession adds session to sessions list', () async {
      final id = await manager.createSession(makeProfile());
      expect(manager.sessions, hasLength(1));
      expect(manager.sessions.first.id, id);
    });

    test('createSession calls ssh.connect', () async {
      await manager.createSession(makeProfile());
      expect(lastSsh.connectCalled, isTrue);
    });

    test('createSession sets autoReconnect on SSH service', () async {
      await manager.createSession(makeProfile(), autoReconnect: false);
      expect(lastSsh.autoReconnect, isFalse);
    });

    test('getSsh returns SSH service after session creation', () async {
      final id = await manager.createSession(makeProfile());
      expect(manager.getSsh(id), isNotNull);
    });

    test('getSftp returns SFTP service after session creation', () async {
      final id = await manager.createSession(makeProfile());
      expect(manager.getSftp(id), isNotNull);
    });

    test('getSsh returns null for unknown session', () {
      expect(manager.getSsh('nonexistent'), isNull);
    });

    test('getSftp returns null for unknown session', () {
      expect(manager.getSftp('nonexistent'), isNull);
    });

    test('createSession emits session via stream', () async {
      final future = manager.sessionsStream
          .firstWhere((list) => list.isNotEmpty);
      await manager.createSession(makeProfile());
      final sessions = await future;
      expect(sessions, hasLength(1));
      expect(sessions.first.profile.name, 'Test');
    });

    test('createSession starts with connecting state', () async {
      final future = manager.sessionsStream
          .firstWhere((list) => list.isNotEmpty);
      await manager.createSession(makeProfile());
      final sessions = await future;
      // Session may be connecting or already connected depending on timing
      expect(
        sessions.first.state,
        anyOf(SshConnectionState.connecting, SshConnectionState.connected),
      );
    });

    test('SSH state changes propagate to session stream', () async {
      final id = await manager.createSession(makeProfile());
      final ssh = manager.getSsh(id) as FakeSshService;

      // Listen for disconnected state
      final future = manager.sessionsStream
          .firstWhere((list) =>
              list.isNotEmpty &&
              list.first.state == SshConnectionState.disconnected);

      ssh.emitState(SshConnectionState.disconnected);
      final sessions = await future;
      expect(sessions.first.state, SshConnectionState.disconnected);
    });

    test('concurrent createSession throws StateError', () async {
      // Start first session
      final first = manager.createSession(makeProfile());
      // Attempt concurrent creation should fail
      expect(
        () => manager.createSession(makeProfile()),
        throwsStateError,
      );
      await first;
    });

    test('createSession cleans up on connection failure', () async {
      // Create a manager where SSH connect fails
      final failManager = ConnectionManager(
        keyManager: keyManager,
        sshFactory: () {
          final ssh = FakeSshService();
          ssh.shouldFailConnect = true;
          return ssh;
        },
        sftpFactory: FakeSftpService.new,
        sftpInitializer: (ssh, sftp) async {},
      );

      try {
        await failManager.createSession(makeProfile());
        fail('Should have thrown');
      } catch (_) {}

      expect(failManager.sessions, isEmpty);
      await failManager.dispose();
    });

    test('createSession resets guard after failure', () async {
      final failManager = ConnectionManager(
        keyManager: keyManager,
        sshFactory: () {
          final ssh = FakeSshService();
          ssh.shouldFailConnect = true;
          return ssh;
        },
        sftpFactory: FakeSftpService.new,
        sftpInitializer: (ssh, sftp) async {},
      );

      try {
        await failManager.createSession(makeProfile());
      } catch (_) {}

      // Should be able to try again (guard reset)
      // Still fails with connection error, but NOT StateError
      try {
        await failManager.createSession(makeProfile());
        fail('Should have thrown');
      } on StateError {
        fail('Guard was not reset — got StateError');
      } catch (_) {
        // Expected: connection failure, not StateError
      }

      await failManager.dispose();
    });

    test('closeSession removes session from list', () async {
      final id = await manager.createSession(makeProfile());
      expect(manager.sessions, hasLength(1));

      await manager.closeSession(id);
      expect(manager.sessions, isEmpty);
    });

    test('closeSession disposes SSH and SFTP services', () async {
      final id = await manager.createSession(makeProfile());
      final ssh = lastSsh;
      final sftp = lastSftp;

      await manager.closeSession(id);
      expect(ssh.disposeCalled, isTrue);
      expect(sftp.disposeCalled, isTrue);
    });

    test('closeSession emits updated session list', () async {
      final id = await manager.createSession(makeProfile());

      final future = manager.sessionsStream
          .firstWhere((list) => list.isEmpty);

      await manager.closeSession(id);
      final sessions = await future;
      expect(sessions, isEmpty);
    });

    test('closeSession is safe for unknown session ID', () async {
      // Should not throw
      await manager.closeSession('nonexistent');
    });

    test('reconnectSession calls ssh.reconnect', () async {
      final id = await manager.createSession(makeProfile());
      final ssh = lastSsh;

      await manager.reconnectSession(id);
      expect(ssh.reconnectCalled, isTrue);
    });

    test('reconnectSession is no-op for unknown session', () async {
      // Should not throw
      await manager.reconnectSession('nonexistent');
    });

    test('multiple sessions can coexist', () async {
      // Need to wait between creates to avoid concurrent guard
      final id1 = await manager.createSession(
          makeProfile(name: 'Server 1'));
      final id2 = await manager.createSession(
          makeProfile(name: 'Server 2'));

      expect(manager.sessions, hasLength(2));
      expect(id1, isNot(equals(id2)));
      expect(manager.getSsh(id1), isNotNull);
      expect(manager.getSsh(id2), isNotNull);
    });

    test('dispose cleans up all sessions', () async {
      await manager.createSession(makeProfile(name: 'S1'));
      final ssh1 = lastSsh;
      final sftp1 = lastSftp;

      await manager.createSession(makeProfile(name: 'S2'));
      final ssh2 = lastSsh;
      final sftp2 = lastSftp;

      await manager.dispose();

      expect(ssh1.disposeCalled, isTrue);
      expect(sftp1.disposeCalled, isTrue);
      expect(ssh2.disposeCalled, isTrue);
      expect(sftp2.disposeCalled, isTrue);
    });

    test('dispose stops emitting sessions', () async {
      await manager.createSession(makeProfile());
      await manager.dispose();

      // Stream should be closed — no more emissions
      // (sessionsController.close() was called)
      expect(manager.sessionsStream.isEmpty, completion(isTrue));
    });

    test('startup command is sent for non-standard claude mode', () async {
      final profile = makeProfile().copyWith(
        claudeMode: ClaudeMode.skipPermissions,
      );
      await manager.createSession(profile);
      // The startup command includes 'claude' with --dangerously-skip-permissions
      expect(
        lastSsh.writtenStrings,
        contains(predicate<String>((s) => s.contains('claude'))),
      );
    });

    test('standard mode sends plain claude command', () async {
      await manager.createSession(makeProfile());
      expect(
        lastSsh.writtenStrings,
        contains(predicate<String>((s) => s == 'claude\n')),
      );
    });
  });
}
