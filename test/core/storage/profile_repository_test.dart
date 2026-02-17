import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:claude_mobile/core/storage/profile_repository.dart';
import 'package:claude_mobile/core/models/server_profile.dart';

/// Minimal fake for the subset of FlutterSecureStorage used by ProfileRepository.
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

  /// Expose raw data for test assertions.
  Map<String, String> get rawData => _data;
}

ServerProfile _makeProfile({
  String id = 'p1',
  String name = 'Test Server',
  String host = 'example.com',
  String username = 'user',
  int port = 22,
}) {
  return ServerProfile(
    id: id,
    name: name,
    host: host,
    username: username,
    port: port,
    createdAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('ProfileRepository', () {
    late FakeSecureStorage storage;
    late ProfileRepository repo;

    setUp(() {
      storage = FakeSecureStorage();
      repo = ProfileRepository(storage: storage);
    });

    group('getAll', () {
      test('returns empty list when no profiles stored', () async {
        final profiles = await repo.getAll();
        expect(profiles, isEmpty);
      });

      test('returns profiles after save', () async {
        await repo.save(_makeProfile(id: 'a', name: 'Server A'));
        await repo.save(_makeProfile(id: 'b', name: 'Server B'));

        final profiles = await repo.getAll();
        expect(profiles, hasLength(2));
        expect(profiles[0].id, 'a');
        expect(profiles[1].id, 'b');
      });

      test('handles corrupted JSON gracefully (returns empty list)', () async {
        storage.rawData['server_profiles'] = 'not valid json!!!';

        final profiles = await repo.getAll();
        expect(profiles, isEmpty);
      });

      test('skips individual corrupted entries', () async {
        // Manually write JSON with one valid and one invalid entry.
        final validProfile = _makeProfile(id: 'good', name: 'Good');
        storage.rawData['server_profiles'] = jsonEncode([
          validProfile.toJson(),
          {'bad': 'entry'}, // missing required fields
        ]);

        final profiles = await repo.getAll();
        expect(profiles, hasLength(1));
        expect(profiles[0].id, 'good');
      });
    });

    group('save', () {
      test('inserts new profile', () async {
        await repo.save(_makeProfile(id: 'new'));

        final profiles = await repo.getAll();
        expect(profiles, hasLength(1));
        expect(profiles[0].id, 'new');
      });

      test('upserts existing profile by id', () async {
        await repo.save(_makeProfile(id: 'x', name: 'Original'));
        await repo.save(_makeProfile(id: 'x', name: 'Updated'));

        final profiles = await repo.getAll();
        expect(profiles, hasLength(1));
        expect(profiles[0].name, 'Updated');
      });

      test('preserves order on upsert', () async {
        await repo.save(_makeProfile(id: 'a', name: 'First'));
        await repo.save(_makeProfile(id: 'b', name: 'Second'));
        await repo.save(_makeProfile(id: 'a', name: 'First Updated'));

        final profiles = await repo.getAll();
        expect(profiles[0].id, 'a');
        expect(profiles[0].name, 'First Updated');
        expect(profiles[1].id, 'b');
      });
    });

    group('delete', () {
      test('removes profile by id', () async {
        await repo.save(_makeProfile(id: 'del'));
        await repo.delete('del');

        final profiles = await repo.getAll();
        expect(profiles, isEmpty);
      });

      test('is a no-op for non-existent id', () async {
        await repo.save(_makeProfile(id: 'keep'));
        await repo.delete('nonexistent');

        final profiles = await repo.getAll();
        expect(profiles, hasLength(1));
      });
    });

    group('defaultProfileId', () {
      test('returns null when not set', () async {
        final id = await repo.getDefaultProfileId();
        expect(id, isNull);
      });

      test('round-trips set and get', () async {
        await repo.setDefaultProfileId('my-default');
        final id = await repo.getDefaultProfileId();
        expect(id, 'my-default');
      });
    });
  });
}
