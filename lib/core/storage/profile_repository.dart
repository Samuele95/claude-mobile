import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/server_profile.dart';

class ProfileRepository {
  static const _profilesKey = 'server_profiles';
  static const _defaultProfileKey = 'default_profile_id';

  final FlutterSecureStorage _storage;

  ProfileRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<ServerProfile>> getAll() async {
    final raw = await _storage.read(key: _profilesKey);
    if (raw == null) return [];

    final List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (err) {
      developer.log('Corrupted profiles JSON, resetting: $err', name: 'ProfileRepository');
      return [];
    }

    final profiles = <ServerProfile>[];
    for (final e in list) {
      try {
        profiles.add(ServerProfile.fromJson(e as Map<String, dynamic>));
      } catch (err) {
        developer.log('Skipping corrupted profile: $err', name: 'ProfileRepository');
      }
    }
    return profiles;
  }

  Future<void> save(ServerProfile profile) async {
    final profiles = await getAll();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await _storage.write(
      key: _profilesKey,
      value: jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> delete(String profileId) async {
    final profiles = await getAll();
    profiles.removeWhere((p) => p.id == profileId);
    await _storage.write(
      key: _profilesKey,
      value: jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<String?> getDefaultProfileId() =>
      _storage.read(key: _defaultProfileKey);

  Future<void> setDefaultProfileId(String id) =>
      _storage.write(key: _defaultProfileKey, value: id);
}
