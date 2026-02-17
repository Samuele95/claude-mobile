import 'package:flutter_test/flutter_test.dart';
import 'package:dartssh2/dartssh2.dart' show SftpClient;
import 'package:claude_mobile/core/ssh/sftp_service.dart';

/// Minimal fake SftpClient that tracks close() calls.
/// Uses noSuchMethod to satisfy the interface without implementing everything.
class FakeSftpClient extends Fake implements SftpClient {
  bool closed = false;

  @override
  void close() => closed = true;
}

void main() {
  group('SftpService', () {
    late SftpService service;

    setUp(() {
      service = SftpService();
    });

    tearDown(() {
      service.dispose();
    });

    group('before initialization', () {
      test('listDirectory throws StateError', () {
        expect(() => service.listDirectory('/'), throwsStateError);
      });

      test('stat throws StateError', () {
        expect(() => service.stat('/'), throwsStateError);
      });

      test('mkdir throws StateError', () {
        expect(() => service.mkdir('/tmp'), throwsStateError);
      });

      test('rename throws StateError', () {
        expect(() => service.rename('/a', '/b'), throwsStateError);
      });

      test('remove throws StateError', () {
        expect(() => service.remove('/tmp/f'), throwsStateError);
      });

      test('rmdir throws StateError', () {
        expect(() => service.rmdir('/tmp/d'), throwsStateError);
      });

      test('realpath throws StateError', () {
        expect(() => service.realpath('.'), throwsStateError);
      });

      test('readFileBytes throws StateError', () {
        expect(() => service.readFileBytes('/f'), throwsStateError);
      });
    });

    test('transferStream is accessible', () {
      expect(service.transferStream, isNotNull);
    });

    group('initializeWithClient', () {
      test('accepts a client without error', () {
        final client = FakeSftpClient();
        service.initializeWithClient(client);
        // No exception means success
      });

      test('closes previous client on re-initialization', () {
        final first = FakeSftpClient();
        final second = FakeSftpClient();

        service.initializeWithClient(first);
        expect(first.closed, isFalse);

        service.initializeWithClient(second);
        expect(first.closed, isTrue);
        expect(second.closed, isFalse);
      });
    });

    group('dispose', () {
      test('closes active client', () {
        final client = FakeSftpClient();
        service.initializeWithClient(client);

        service.dispose();
        expect(client.closed, isTrue);
      });

      test('is safe to call without initialization', () {
        // Should not throw
        service.dispose();
      });

      test('operations throw StateError after dispose', () {
        final client = FakeSftpClient();
        service.initializeWithClient(client);
        service.dispose();

        expect(() => service.listDirectory('/'), throwsStateError);
        expect(() => service.stat('/'), throwsStateError);
        expect(() => service.mkdir('/tmp'), throwsStateError);
      });
    });
  });
}
