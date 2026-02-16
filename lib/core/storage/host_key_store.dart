import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Trust On First Use (TOFU) host key store.
///
/// On first connection to a host, the fingerprint is stored.
/// On subsequent connections, the stored fingerprint is compared.
enum HostKeyVerifyResult {
  /// First time seeing this host — fingerprint was stored and accepted.
  trusted,

  /// Fingerprint matches the stored value.
  matched,

  /// Fingerprint does NOT match the stored value (possible MITM).
  mismatch,
}

class HostKeyStore {
  static const _prefix = 'hostkey_';

  final FlutterSecureStorage _storage;

  HostKeyStore({required FlutterSecureStorage storage}) : _storage = storage;

  String _key(String host, int port) => '$_prefix${host}_$port';

  /// Verify a host key fingerprint using TOFU policy.
  ///
  /// [type] is the key type (e.g. 'ssh-ed25519', 'ssh-rsa').
  /// [fingerprint] is the raw fingerprint bytes from dartssh2.
  /// Returns the verification result.
  Future<HostKeyVerifyResult> verify(
    String host,
    int port,
    String type,
    Uint8List fingerprint,
  ) async {
    final key = _key(host, port);
    final encoded = '$type:${base64.encode(fingerprint)}';

    final stored = await _storage.read(key: key);
    if (stored == null) {
      // First time — trust and store
      await _storage.write(key: key, value: encoded);
      return HostKeyVerifyResult.trusted;
    }

    if (stored == encoded) {
      return HostKeyVerifyResult.matched;
    }

    return HostKeyVerifyResult.mismatch;
  }

  /// Remove a stored host key (e.g. when user explicitly re-trusts).
  Future<void> removeHostKey(String host, int port) async {
    await _storage.delete(key: _key(host, port));
  }
}
