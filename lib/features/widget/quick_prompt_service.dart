import 'package:home_widget/home_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/ssh/ssh_service.dart';
import '../../core/storage/profile_repository.dart';

class QuickPromptService {
  final SshService _ssh;
  final ProfileRepository _profiles;
  final FlutterLocalNotificationsPlugin _notifications;

  QuickPromptService({
    required SshService ssh,
    required ProfileRepository profiles,
  })  : _ssh = ssh,
        _profiles = profiles,
        _notifications = FlutterLocalNotificationsPlugin() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  Future<void> handlePrompt(String prompt) async {
    await HomeWidget.saveWidgetData<String>('status', 'running');
    await HomeWidget.updateWidget(name: 'QuickPromptWidgetProvider');

    try {
      final defaultId = await _profiles.getDefaultProfileId();
      final profiles = await _profiles.getAll();
      if (profiles.isEmpty) {
        await _showNotification(
            'No server configured', 'Add a server in Claude Mobile first.');
        return;
      }

      final profile = defaultId != null
          ? profiles.firstWhere((p) => p.id == defaultId,
              orElse: () => profiles.first)
          : profiles.first;

      final escapedPrompt = prompt.replaceAll('"', '\\"');
      final command =
          'claude -p "$escapedPrompt" --dangerously-skip-permissions 2>&1';
      final result = await _ssh.executeCommand(profile, command);

      await _showNotification('Claude', result.trim());
    } catch (e) {
      await _showNotification('Error', e.toString());
    } finally {
      await HomeWidget.saveWidgetData<String>('status', 'idle');
      await HomeWidget.updateWidget(name: 'QuickPromptWidgetProvider');
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
