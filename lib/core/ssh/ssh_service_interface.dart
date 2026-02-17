import 'dart:typed_data';
import '../models/server_profile.dart';
import '../models/connection_state.dart';

/// Callback that retrieves the password on-demand from secure storage.
typedef PasswordProvider = Future<String?> Function();

/// Abstract interface for SSH operations.
///
/// Enables dependency inversion (p008) and testability via mock injection.
/// Concrete implementation: [SshService].
abstract class SshServiceInterface {
  Stream<SshConnectionState> get stateStream;
  Stream<Uint8List> get outputStream;
  SshConnectionState get state;
  bool get autoReconnect;
  set autoReconnect(bool value);
  ServerProfile? get activeProfile;

  Future<void> connect(
    ServerProfile profile, {
    String? password,
    PasswordProvider? passwordProvider,
    int initialWidth,
    int initialHeight,
  });

  void write(String data);
  void writeBytes(Uint8List data);
  void resizePty(int width, int height);
  Future<String> executeCommand(
    ServerProfile profile,
    String command, {
    String? password,
  });
  Future<void> reconnect();
  Future<void> disconnect();
  Future<void> dispose();
}
