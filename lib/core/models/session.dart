import 'connection_state.dart';
import 'server_profile.dart';

class Session {
  final String id;
  final ServerProfile profile;
  final SshConnectionState state;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.profile,
    this.state = SshConnectionState.disconnected,
    required this.createdAt,
  });

  Session copyWith({SshConnectionState? state}) {
    return Session(
      id: id,
      profile: profile,
      state: state ?? this.state,
      createdAt: createdAt,
    );
  }

  String get displayName => '${profile.name} (${profile.host})';
}
