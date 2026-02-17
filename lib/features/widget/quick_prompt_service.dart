import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/models/server_profile.dart';
import '../../core/ssh/ssh_service.dart';
import '../../core/storage/key_manager.dart';
import '../../core/storage/profile_repository.dart';
import '../../core/utils/command_builder.dart';

class QuickPromptService {
  final KeyManager _keyManager;
  final ProfileRepository _profiles;
  final FlutterSecureStorage _storage;
  final FlutterLocalNotificationsPlugin _notifications;

  QuickPromptService({
    required KeyManager keyManager,
    required ProfileRepository profiles,
    required FlutterSecureStorage storage,
    FlutterLocalNotificationsPlugin? notifications,
  })  : _keyManager = keyManager,
        _profiles = profiles,
        _storage = storage,
        _notifications = notifications ?? FlutterLocalNotificationsPlugin() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  Future<void> handlePrompt(String prompt) async {
    if (Platform.isAndroid) {
      await HomeWidget.saveWidgetData<String>('status', 'running');
      await HomeWidget.updateWidget(name: 'QuickPromptWidgetProvider');
    }

    // Create a dedicated SshService instance for this one-shot command
    final ssh = SshService(keyManager: _keyManager);

    try {
      final defaultId = await _profiles.getDefaultProfileId();
      final profiles = await _profiles.getAll();
      if (profiles.isEmpty) {
        await _showNotification(
            'No server configured', 'Add a server in Claude Carry first.');
        return;
      }

      final profile = defaultId != null
          ? profiles.firstWhere((p) => p.id == defaultId,
              orElse: () => profiles.first)
          : profiles.first;

      // Fetch password from secure storage for password-auth profiles
      String? password;
      if (profile.authMethod == AuthMethod.password) {
        password = await _storage.read(key: 'password_${profile.id}');
      }

      final escapedPrompt = shellEscape(prompt);
      final command =
          'claude -p "$escapedPrompt" --dangerously-skip-permissions 2>&1';
      final result = await ssh.executeCommand(profile, command, password: password);

      await _showNotification('Claude', result.trim());
    } catch (e) {
      await _showNotification('Error', e.toString());
    } finally {
      await ssh.dispose();
      if (Platform.isAndroid) {
        await HomeWidget.saveWidgetData<String>('status', 'idle');
        await HomeWidget.updateWidget(name: 'QuickPromptWidgetProvider');
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const details = AndroidNotificationDetails(
      'claude_quick_prompt',
      'Quick Prompt Results',
      channelDescription: 'Results from Claude Code quick prompts',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    await _notifications.show(
      0,
      title,
      body,
      const NotificationDetails(android: details),
    );
  }
}
