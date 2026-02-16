import '../models/server_profile.dart';
import '../storage/key_manager.dart';
import '../storage/host_key_store.dart';
import 'ssh_service.dart';

/// Tests SSH connectivity to a server profile without affecting global state.
/// Creates a temporary SshService, connects, disconnects, and disposes it.
class ConnectionTester {
  final KeyManager _keyManager;
  final HostKeyStore? _hostKeyStore;

  ConnectionTester({required KeyManager keyManager, HostKeyStore? hostKeyStore})
      : _keyManager = keyManager,
        _hostKeyStore = hostKeyStore;

  /// Tests connection to [profile]. Returns normally on success, throws on failure.
  Future<void> test(ServerProfile profile, {String? password}) async {
    final ssh = SshService(keyManager: _keyManager, hostKeyStore: _hostKeyStore);
    try {
      await ssh.connect(profile, password: password);
      await ssh.disconnect();
    } finally {
      await ssh.dispose();
    }
  }
}
