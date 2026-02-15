import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyManager {
  static const _appKeyPrivate = 'app_ssh_private_key';
  static const _appKeyPublic = 'app_ssh_public_key';
  static const _privateKeyPrefix = 'ssh_private_key_';

  final FlutterSecureStorage _storage;

  KeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Generate the app-wide SSH keypair on first launch.
  /// Returns the public key string.
  Future<String> getOrCreateAppKeyPair() async {
    final existing = await _storage.read(key: _appKeyPublic);
    if (existing != null) return existing;

    final keyPairs = SSHKeyPair.generateEd25519();
    final privateKeyPem = keyPairs.first.toPem();
    final publicKey = keyPairs.first.toOpenSSHString();

    await _storage.write(key: _appKeyPrivate, value: privateKeyPem);
    await _storage.write(key: _appKeyPublic, value: publicKey);
    return publicKey;
  }

  Future<List<SSHKeyPair>> getAppKeyPairs() async {
    final pem = await _storage.read(key: _appKeyPrivate);
    if (pem == null) return [];
    return SSHKeyPair.fromPem(pem);
  }

  /// Store a per-profile key (if the user imports one).
  Future<void> storeProfileKey(String profileId, String privatePem) =>
      _storage.write(key: '$_privateKeyPrefix$profileId', value: privatePem);

  Future<List<SSHKeyPair>> getProfileKeyPairs(String profileId) async {
    final pem = await _storage.read(key: '$_privateKeyPrefix$profileId');
    if (pem == null) return getAppKeyPairs();
    return SSHKeyPair.fromPem(pem);
  }

  Future<void> deleteProfileKey(String profileId) async {
    await _storage.delete(key: '$_privateKeyPrefix$profileId');
  }
}
