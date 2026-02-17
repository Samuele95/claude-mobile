import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/server_profile.dart';
import 'models/session.dart';
import 'models/transfer_item.dart';
import 'storage/profile_repository.dart';
import 'storage/key_manager.dart';
import 'storage/host_key_store.dart';
import 'ssh/ssh_service_interface.dart';
import 'ssh/sftp_service_interface.dart';
import 'ssh/connection_manager.dart';
import 'ssh/connection_manager_interface.dart';
import '../features/terminal/terminal_controller.dart';

// --- Singletons ---

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final keyManagerProvider = Provider<KeyManager>(
  (ref) => KeyManager(storage: ref.watch(secureStorageProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(storage: ref.watch(secureStorageProvider)),
);

final hostKeyStoreProvider = Provider<HostKeyStore>(
  (ref) => HostKeyStore(storage: ref.watch(secureStorageProvider)),
);

// --- Connection Manager (replaces singleton ssh/sftp) ---

final connectionManagerProvider = Provider<ConnectionManagerInterface>((ref) {
  final manager = ConnectionManager(
    keyManager: ref.watch(keyManagerProvider),
    hostKeyStore: ref.watch(hostKeyStoreProvider),
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});

// --- Session State ---

final sessionsProvider = StreamProvider<List<Session>>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.sessionsStream;
});

final activeSessionIdProvider = StateProvider<String?>((ref) => null);

// --- Family Providers (per-session) ---

final sessionSshProvider = Provider.family<SshServiceInterface?, String>((ref, id) {
  return ref.watch(connectionManagerProvider).getSsh(id);
});

final sessionSftpProvider = Provider.family<SftpServiceInterface?, String>((ref, id) {
  return ref.watch(connectionManagerProvider).getSftp(id);
});

final sessionTerminalControllerProvider =
    Provider.family<SshTerminalController?, String>((ref, id) {
  final ssh = ref.read(connectionManagerProvider).getSsh(id);
  if (ssh == null) return null;
  final controller = SshTerminalController(ssh: ssh);
  ref.onDispose(() => controller.dispose());
  return controller;
});

// --- Profiles ---

final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<ServerProfile>>(
  ProfilesNotifier.new,
);

class ProfilesNotifier extends AsyncNotifier<List<ServerProfile>> {
  @override
  Future<List<ServerProfile>> build() =>
      ref.read(profileRepositoryProvider).getAll();

  Future<void> add(ServerProfile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = AsyncData(await ref.read(profileRepositoryProvider).getAll());
  }

  Future<void> remove(String id) async {
    await ref.read(profileRepositoryProvider).delete(id);
    // Clean up orphaned password and key entries
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: StorageKeys.password(id));
    await ref.read(keyManagerProvider).deleteProfileKey(id);
    state = AsyncData(await ref.read(profileRepositoryProvider).getAll());
  }
}

// --- SSH Public Key (cached) ---

final appPublicKeyProvider = FutureProvider<String>((ref) {
  return ref.watch(keyManagerProvider).getOrCreateAppKeyPair();
});

// --- Transfer State ---

final transferStreamProvider = StreamProvider.family<TransferItem, String>(
  (ref, sessionId) {
    final sftp = ref.watch(connectionManagerProvider).getSftp(sessionId);
    if (sftp == null) return const Stream.empty();
    return sftp.transferStream;
  },
);
