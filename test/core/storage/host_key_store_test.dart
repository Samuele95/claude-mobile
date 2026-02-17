import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:claude_mobile/core/storage/host_key_store.dart';

/// Minimal fake for the subset of FlutterSecureStorage used by HostKeyStore.
/// Uses noSuchMethod to handle unimplemented interface members.
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
}

void main() {
  group('HostKeyStore', () {
    late FakeSecureStorage storage;
    late HostKeyStore store;

    setUp(() {
      storage = FakeSecureStorage();
      store = HostKeyStore(storage: storage);
    });

    final fingerprint = Uint8List.fromList([1, 2, 3, 4, 5]);

    test('trusts first-time host key (TOFU)', () async {
      final result = await store.verify(
        'example.com',
        22,
        'ssh-ed25519',
        fingerprint,
      );

      expect(result, HostKeyVerifyResult.trusted);
    });

    test('matches previously trusted host key', () async {
      await store.verify('example.com', 22, 'ssh-ed25519', fingerprint);

      final result = await store.verify(
        'example.com',
        22,
        'ssh-ed25519',
        fingerprint,
      );

      expect(result, HostKeyVerifyResult.matched);
    });

    test('detects host key mismatch (potential MITM)', () async {
      await store.verify('example.com', 22, 'ssh-ed25519', fingerprint);

      final differentKey = Uint8List.fromList([9, 8, 7, 6, 5]);
      final result = await store.verify(
        'example.com',
        22,
        'ssh-ed25519',
        differentKey,
      );

      expect(result, HostKeyVerifyResult.mismatch);
    });

    test('different ports are treated as different hosts', () async {
      await store.verify('example.com', 22, 'ssh-ed25519', fingerprint);

      final differentPort = Uint8List.fromList([9, 9, 9]);
      final result = await store.verify(
        'example.com',
        2222,
        'ssh-ed25519',
        differentPort,
      );

      expect(result, HostKeyVerifyResult.trusted);
    });

    test('removeHostKey allows re-trusting', () async {
      await store.verify('example.com', 22, 'ssh-ed25519', fingerprint);
      await store.removeHostKey('example.com', 22);

      final newKey = Uint8List.fromList([99, 99, 99]);
      final result = await store.verify('example.com', 22, 'ssh-ed25519', newKey);

      expect(result, HostKeyVerifyResult.trusted);
    });

    test('detects key type change as mismatch', () async {
      await store.verify('example.com', 22, 'ssh-ed25519', fingerprint);

      final result = await store.verify(
        'example.com',
        22,
        'ssh-rsa',
        fingerprint,
      );

      expect(result, HostKeyVerifyResult.mismatch);
    });
  });
}
