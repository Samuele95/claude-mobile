import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/models/server_profile.dart';

/// Tests for ServerProfile model.
///
/// Functor mapping: naming_reveals_intent → descriptive_test_names (p022)
/// Pattern: test_behavior_not_implementation (p017) — tests WHAT, not HOW.
void main() {
  group('ServerProfile', () {
    // Arrange (shared fixture)
    final profile = ServerProfile(
      id: 'test-id',
      name: 'My Server',
      host: '192.168.1.1',
      port: 22,
      username: 'admin',
      authMethod: AuthMethod.password,
      claudeMode: ClaudeMode.skipPermissions,
      customPrompt: '',
      createdAt: DateTime(2025, 1, 1),
    );

    group('serialization', () {
      test('round-trips through JSON without data loss', () {
        // Act
        final json = profile.toJson();
        final restored = ServerProfile.fromJson(json);

        // Assert
        expect(restored.id, profile.id);
        expect(restored.name, profile.name);
        expect(restored.host, profile.host);
        expect(restored.port, profile.port);
        expect(restored.username, profile.username);
        expect(restored.authMethod, profile.authMethod);
        expect(restored.claudeMode, profile.claudeMode);
        expect(restored.customPrompt, profile.customPrompt);
      });

      test('round-trips through encode/decode string format', () {
        // Act
        final encoded = profile.encode();
        final decoded = ServerProfile.decode(encoded);

        // Assert
        expect(decoded.id, profile.id);
        expect(decoded.host, profile.host);
      });

      test('toJson produces valid JSON string', () {
        // Act
        final jsonStr = jsonEncode(profile.toJson());

        // Assert
        expect(() => jsonDecode(jsonStr), returnsNormally);
      });
    });

    group('backward compatibility', () {
      test('migrates legacy startupCommand "claude" to ClaudeMode.standard', () {
        // Arrange — old JSON with startupCommand field
        final legacyJson = {
          'id': 'old-1',
          'name': 'Legacy',
          'host': 'example.com',
          'username': 'user',
          'startupCommand': 'claude',
          'createdAt': '2024-06-01T00:00:00.000',
        };

        // Act
        final restored = ServerProfile.fromJson(legacyJson);

        // Assert
        expect(restored.claudeMode, ClaudeMode.standard);
      });

      test('migrates legacy startupCommand with -p flag to customPrompt mode', () {
        final legacyJson = {
          'id': 'old-2',
          'name': 'Legacy Custom',
          'host': 'example.com',
          'username': 'user',
          'startupCommand': 'claude -p "fix the bug"',
          'createdAt': '2024-06-01T00:00:00.000',
        };

        final restored = ServerProfile.fromJson(legacyJson);

        expect(restored.claudeMode, ClaudeMode.customPrompt);
        expect(restored.customPrompt, 'fix the bug');
      });

      test('migrates legacy startupCommand with skip-permissions to skipPermissions mode', () {
        final legacyJson = {
          'id': 'old-3',
          'name': 'Legacy Skip',
          'host': 'example.com',
          'username': 'user',
          'startupCommand': 'claude --dangerously-skip-permissions',
          'createdAt': '2024-06-01T00:00:00.000',
        };

        final restored = ServerProfile.fromJson(legacyJson);

        expect(restored.claudeMode, ClaudeMode.skipPermissions);
      });

      test('defaults to port 22 when port is missing from JSON', () {
        final json = {
          'id': 'no-port',
          'name': 'No Port',
          'host': 'example.com',
          'username': 'user',
          'createdAt': '2024-06-01T00:00:00.000',
        };

        final restored = ServerProfile.fromJson(json);

        expect(restored.port, 22);
      });

      test('defaults to password auth when authMethod is missing', () {
        final json = {
          'id': 'no-auth',
          'name': 'No Auth',
          'host': 'example.com',
          'username': 'user',
          'createdAt': '2024-06-01T00:00:00.000',
        };

        final restored = ServerProfile.fromJson(json);

        expect(restored.authMethod, AuthMethod.password);
      });

      test('handles missing createdAt gracefully', () {
        final json = {
          'id': 'no-date',
          'name': 'No Date',
          'host': 'example.com',
          'username': 'user',
        };

        // Should not throw
        final restored = ServerProfile.fromJson(json);
        expect(restored.createdAt, isNotNull);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final updated = profile.copyWith(name: 'New Name');

        expect(updated.name, 'New Name');
        expect(updated.id, profile.id); // unchanged
        expect(updated.host, profile.host); // unchanged
        expect(updated.port, profile.port); // unchanged
        expect(updated.createdAt, profile.createdAt); // always preserved
      });

      test('can update multiple fields simultaneously', () {
        final updated = profile.copyWith(
          host: 'new-host.com',
          port: 2222,
          username: 'newuser',
        );

        expect(updated.host, 'new-host.com');
        expect(updated.port, 2222);
        expect(updated.username, 'newuser');
      });
    });
  });
}
