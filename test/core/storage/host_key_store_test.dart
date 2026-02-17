import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/storage/host_key_store.dart';
import '../../helpers/fake_secure_storage.dart';

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
