import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:claude_mobile/core/storage/key_manager.dart';

/// Minimal fake for the subset of FlutterSecureStorage used by KeyManager.
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  Map<String, String> get rawData => _data;
}

void main() {
  group('KeyManager', () {
    late FakeSecureStorage storage;
    late KeyManager manager;

    setUp(() {
      storage = FakeSecureStorage();
      manager = KeyManager(storage: storage);
    });

    group('getOrCreateAppKeyPair', () {
      test('generates a new key pair on first call', () async {
        final publicKey = await manager.getOrCreateAppKeyPair();

        expect(publicKey, startsWith('ssh-ed25519 '));
        expect(publicKey, contains('claude-carry'));
        // Both keys should be stored
        expect(storage.rawData['app_ssh_public_key'], isNotNull);
        expect(storage.rawData['app_ssh_private_key'], isNotNull);
      });

      test('returns existing key on subsequent calls', () async {
        final first = await manager.getOrCreateAppKeyPair();
        final second = await manager.getOrCreateAppKeyPair();

        expect(first, equals(second));
      });

      test('returns pre-existing key from storage', () async {
        storage.rawData['app_ssh_public_key'] = 'ssh-ed25519 AAAA existing-key';

        final publicKey = await manager.getOrCreateAppKeyPair();
        expect(publicKey, 'ssh-ed25519 AAAA existing-key');
        // Should NOT have written a private key (key already existed)
        expect(storage.rawData['app_ssh_private_key'], isNull);
      });
    });

    group('getAppKeyPairs', () {
      test('returns empty list when no key exists', () async {
        final pairs = await manager.getAppKeyPairs();
        expect(pairs, isEmpty);
      });

      test('returns key pairs after generation', () async {
        await manager.getOrCreateAppKeyPair();
        final pairs = await manager.getAppKeyPairs();
        expect(pairs, isNotEmpty);
      });
    });

    group('profile keys', () {
      test('storeProfileKey writes to storage', () async {
        await manager.storeProfileKey('prof1', '-----BEGIN OPENSSH PRIVATE KEY-----\nfake\n-----END OPENSSH PRIVATE KEY-----');
        expect(storage.rawData['ssh_private_key_prof1'], isNotNull);
      });

      test('deleteProfileKey removes from storage', () async {
        await manager.storeProfileKey('prof1', 'fake-pem');
        await manager.deleteProfileKey('prof1');
        expect(storage.rawData['ssh_private_key_prof1'], isNull);
      });

      test('getProfileKeyPairs falls back to app keys when no profile key', () async {
        // Generate an app key first
        await manager.getOrCreateAppKeyPair();

        // No profile-specific key stored, should fall back to app keys
        final pairs = await manager.getProfileKeyPairs('no-such-profile');
        expect(pairs, isNotEmpty);
      });
    });
  });
}
