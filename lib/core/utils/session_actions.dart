import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/server_profile.dart';
import '../storage/profile_repository.dart';
import '../../features/settings/preferences_provider.dart';
import 'dialogs.dart';

/// Shared session lifecycle actions used by mobile, desktop, and tab bar.
/// Eliminates duplication of close-and-switch and connect logic.

Future<void> closeAndSwitchSession(WidgetRef ref, String sessionId) async {
  await ref.read(connectionManagerProvider).closeSession(sessionId);
  final remaining = ref.read(sessionsProvider).valueOrNull ?? [];
  ref.read(activeSessionIdProvider.notifier).state =
      remaining.isEmpty ? null : remaining.first.id;
}

Future<void> closeSessionWithConfirm(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Disconnect',
    message: 'Are you sure you want to disconnect this session?',
    confirmLabel: 'Disconnect',
    destructive: true,
  );
  if (!confirmed) return;
  await closeAndSwitchSession(ref, sessionId);
}

/// Connect to a server profile. Returns the session ID on success.
/// Handles password retrieval from secure storage and auto-reconnect preference.
/// Uses a password callback so the password is fetched on-demand for reconnects
/// instead of being cached in memory.
Future<String> connectToProfile(WidgetRef ref, ServerProfile profile) async {
  final manager = ref.read(connectionManagerProvider);
  final storage = ref.read(secureStorageProvider);
  final prefs = ref.read(preferencesProvider);

  // Password callback — reads from secure storage on-demand
  Future<String?> passwordProvider() async {
    if (profile.authMethod != AuthMethod.password) return null;
    return storage.read(key: StorageKeys.password(profile.id));
  }

  // Fetch password for initial connection
  final password = await passwordProvider();

  final sessionId = await manager.createSession(
    profile,
    password: password,
    passwordProvider: passwordProvider,
    autoReconnect: prefs.autoReconnect,
  );
  ref.read(activeSessionIdProvider.notifier).state = sessionId;
  return sessionId;
}
