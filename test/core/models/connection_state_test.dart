import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/models/connection_state.dart';

void main() {
  group('SshConnectionState', () {
    group('isConnected', () {
      test('returns true only for connected state', () {
        expect(SshConnectionState.connected.isConnected, isTrue);
        expect(SshConnectionState.connecting.isConnected, isFalse);
        expect(SshConnectionState.disconnected.isConnected, isFalse);
        expect(SshConnectionState.error.isConnected, isFalse);
        expect(SshConnectionState.reconnecting.isConnected, isFalse);
      });
    });

    group('isActive', () {
      test('returns true for connected and reconnecting states', () {
        expect(SshConnectionState.connected.isActive, isTrue);
        expect(SshConnectionState.reconnecting.isActive, isTrue);
      });

      test('returns false for all other states', () {
        expect(SshConnectionState.disconnected.isActive, isFalse);
        expect(SshConnectionState.connecting.isActive, isFalse);
        expect(SshConnectionState.authenticating.isActive, isFalse);
        expect(SshConnectionState.error.isActive, isFalse);
      });
    });

    group('label', () {
      test('every state has a non-empty human-readable label', () {
        for (final state in SshConnectionState.values) {
          expect(state.label, isNotEmpty, reason: '$state should have a label');
        }
      });
    });

    group('statusColor', () {
      test('connected state is green', () {
        expect(SshConnectionState.connected.statusColor, Colors.green);
      });

      test('error and disconnected states are red', () {
        expect(SshConnectionState.error.statusColor, Colors.redAccent);
        expect(SshConnectionState.disconnected.statusColor, Colors.redAccent);
      });

      test('transitional states are amber', () {
        expect(SshConnectionState.connecting.statusColor, Colors.amber);
        expect(SshConnectionState.authenticating.statusColor, Colors.amber);
        expect(SshConnectionState.startingShell.statusColor, Colors.amber);
        expect(SshConnectionState.reconnecting.statusColor, Colors.amber);
      });
    });
  });
}
