import 'package:flutter/material.dart';
import '../../core/models/connection_state.dart';

/// Shared reconnect banner used by both mobile and desktop shells.
/// Extracted to eliminate duplication (p003: reduce_duplication).
class ReconnectBanner extends StatelessWidget {
  final SshConnectionState state;
  final VoidCallback onReconnect;
  final bool compact;

  const ReconnectBanner({
    super.key,
    required this.state,
    required this.onReconnect,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isError = state == SshConnectionState.error;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 6 : 8,
      ),
      color: (isError ? Colors.redAccent : Colors.amber)
          .withValues(alpha: compact ? 0.12 : 0.15),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.wifi_off,
            size: compact ? 16 : 18,
            color: isError ? Colors.redAccent : Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isError ? 'Connection error' : 'Disconnected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: onReconnect,
            icon: Icon(Icons.refresh, size: compact ? 14 : 16),
            label: const Text('Reconnect'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size(0, compact ? 28 : 32),
              textStyle: compact ? const TextStyle(fontSize: 12) : null,
            ),
          ),
        ],
      ),
    );
  }
}
