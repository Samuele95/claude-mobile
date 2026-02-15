import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinenacl/ed25519.dart' as ed25519;

class KeyManager {
  static const _appKeyPrivate = 'app_ssh_private_key';
  static const _appKeyPublic = 'app_ssh_public_key';
  static const _privateKeyPrefix = 'ssh_private_key_';

  final FlutterSecureStorage _storage;

  KeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Generate the app-wide SSH keypair on first launch.
  /// Returns the public key string in OpenSSH format.
  Future<String> getOrCreateAppKeyPair() async {
    final existing = await _storage.read(key: _appKeyPublic);
    if (existing != null) return existing;

    // Generate Ed25519 key pair using pinenacl (transitive dep of dartssh2).
    final signingKey = ed25519.SigningKey.generate();
    final publicKeyBytes = Uint8List.fromList(signingKey.verifyKey.asTypedList);
    // dartssh2 expects the 64-byte "expanded" private key (seed ++ public).
    final privateKeyBytes = Uint8List.fromList(signingKey.asTypedList);

    final keyPair = OpenSSHEd25519KeyPair(
      publicKeyBytes,
      privateKeyBytes,
      'claude-carry',
    );

    final privateKeyPem = keyPair.toPem();
    final publicKeyEncoded = base64.encode(keyPair.toPublicKey().encode());
    final publicKey = 'ssh-ed25519 $publicKeyEncoded claude-carry';

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
