import 'package:flutter/material.dart';

enum SshConnectionState {
  disconnected,
  connecting,
  authenticating,
  startingShell,
  connected,
  reconnecting,
  error;

  bool get isConnected => this == SshConnectionState.connected;
  bool get isActive =>
      this == SshConnectionState.connected ||
      this == SshConnectionState.reconnecting;

  String get label => switch (this) {
        SshConnectionState.disconnected => 'Disconnected',
        SshConnectionState.connecting => 'Connecting...',
        SshConnectionState.authenticating => 'Authenticating...',
        SshConnectionState.startingShell => 'Starting shell...',
        SshConnectionState.connected => 'Connected',
        SshConnectionState.reconnecting => 'Reconnecting...',
        SshConnectionState.error => 'Error',
      };

  Color get statusColor => switch (this) {
        SshConnectionState.connected => Colors.green,
        SshConnectionState.reconnecting ||
        SshConnectionState.connecting ||
        SshConnectionState.authenticating ||
        SshConnectionState.startingShell =>
          Colors.amber,
        _ => Colors.redAccent,
      };
}
