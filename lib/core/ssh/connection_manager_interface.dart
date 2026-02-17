import '../models/session.dart';
import '../models/server_profile.dart';
import 'ssh_service_interface.dart';
import 'sftp_service_interface.dart';

/// Abstract interface for managing multiple SSH sessions.
///
/// Enables dependency inversion (p008) and testability via mock injection.
/// Concrete implementation: [ConnectionManager].
abstract class ConnectionManagerInterface {
  Stream<List<Session>> get sessionsStream;
  List<Session> get sessions;

  SshServiceInterface? getSsh(String sessionId);
  SftpServiceInterface? getSftp(String sessionId);

  Future<String> createSession(
    ServerProfile profile, {
    String? password,
    PasswordProvider? passwordProvider,
    bool autoReconnect,
  });

  Future<void> closeSession(String sessionId);
  Future<void> reconnectSession(String sessionId);
  Future<void> dispose();
}
