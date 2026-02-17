import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/models/session.dart';
import 'package:claude_mobile/core/models/server_profile.dart';
import 'package:claude_mobile/core/models/connection_state.dart';

void main() {
  group('Session', () {
    final profile = ServerProfile(
      id: 'profile-1',
      name: 'Test Server',
      host: 'example.com',
      port: 22,
      username: 'admin',
      createdAt: DateTime(2025, 1, 1),
    );

    final session = Session(
      id: 'session-1',
      profile: profile,
      state: SshConnectionState.connected,
      createdAt: DateTime(2025, 6, 1),
    );

    test('displayName combines profile name and host', () {
      expect(session.displayName, 'Test Server (example.com)');
    });

    test('defaults to disconnected state', () {
      final defaultSession = Session(
        id: 'session-2',
        profile: profile,
        createdAt: DateTime.now(),
      );
      expect(defaultSession.state, SshConnectionState.disconnected);
    });

    group('copyWith', () {
      test('updates state while preserving identity and profile', () {
        final updated = session.copyWith(state: SshConnectionState.error);

        expect(updated.state, SshConnectionState.error);
        expect(updated.id, session.id);
        expect(updated.profile.name, session.profile.name);
        expect(updated.createdAt, session.createdAt);
      });
    });
  });
}
