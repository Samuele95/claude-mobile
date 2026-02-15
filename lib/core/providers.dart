import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/server_profile.dart';
import 'models/connection_state.dart';
import 'models/transfer_item.dart';
import 'storage/profile_repository.dart';
import 'storage/key_manager.dart';
import 'ssh/ssh_service.dart';
import 'ssh/sftp_service.dart';

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

final sshServiceProvider = Provider<SshService>((ref) {
  final service = SshService(keyManager: ref.watch(keyManagerProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

final sftpServiceProvider = Provider<SftpService>((ref) {
  final service = SftpService();
  ref.onDispose(() => service.dispose());
  return service;
});

// --- Async State ---

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
    state = AsyncData(await ref.read(profileRepositoryProvider).getAll());
  }
}

// --- Connection State ---

final connectionStateProvider = StreamProvider<SshConnectionState>((ref) {
  return ref.watch(sshServiceProvider).stateStream;
});

// --- Transfer State ---

final transferStreamProvider = StreamProvider<TransferItem>((ref) {
  return ref.watch(sftpServiceProvider).transferStream;
});
