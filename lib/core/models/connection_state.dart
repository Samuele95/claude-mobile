enum SshConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error;

  bool get isConnected => this == SshConnectionState.connected;
  bool get isActive =>
      this == SshConnectionState.connected ||
      this == SshConnectionState.reconnecting;
}
