import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_profile.dart';
import 'dialogs.dart';
import 'session_actions.dart';

/// Shared connection logic with error handling and guard against double-tap.
/// Extracted to eliminate duplication between ConnectionScreen and
/// ConnectionSidebar (p003: reduce_duplication).
///
/// Returns [true] if connection attempt started (regardless of outcome),
/// or [false] if another connection is already in progress.
Future<bool> connectWithErrorHandling({
  required BuildContext context,
  required WidgetRef ref,
  required ServerProfile profile,
  required bool Function() isBusy,
  required VoidCallback onBusyStart,
  required VoidCallback onBusyEnd,
}) async {
  if (isBusy()) return false;
  onBusyStart();

  try {
    await connectToProfile(ref, profile);
    return true;
  } catch (e) {
    if (context.mounted) {
      showErrorDialog(
        context,
        title: 'Connection Failed',
        error: e,
        onRetry: () => connectWithErrorHandling(
          context: context,
          ref: ref,
          profile: profile,
          isBusy: isBusy,
          onBusyStart: onBusyStart,
          onBusyEnd: onBusyEnd,
        ),
      );
    }
    return false;
  } finally {
    onBusyEnd();
  }
}
