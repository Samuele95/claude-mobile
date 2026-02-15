import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'about_screen.dart';
import 'preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(prefs.themeName),
            leading: const Icon(Icons.palette_outlined),
            onTap: () => _showThemePicker(context, ref),
          ),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Text('${prefs.fontSize.round()}pt'),
            leading: const Icon(Icons.format_size),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: prefs.fontSize,
              min: 8,
              max: 24,
              divisions: 16,
              label: '${prefs.fontSize.round()}',
              onChanged: (v) =>
                  ref.read(preferencesProvider.notifier).setFontSize(v),
            ),
          ),
          const Divider(),
          _SectionHeader('Terminal'),
          SwitchListTile(
            title: const Text('Keep screen awake'),
            subtitle: const Text('Prevent sleep during terminal sessions'),
            secondary: const Icon(Icons.visibility_outlined),
            value: prefs.wakeLock,
            onChanged: (v) =>
                ref.read(preferencesProvider.notifier).setWakeLock(v),
          ),
          SwitchListTile(
            title: const Text('Auto-reconnect'),
            subtitle: const Text('Reconnect automatically on disconnect'),
            secondary: const Icon(Icons.sync_outlined),
            value: prefs.autoReconnect,
            onChanged: (v) =>
                ref.read(preferencesProvider.notifier).setAutoReconnect(v),
          ),
          const Divider(),
          _SectionHeader('Feedback'),
          SwitchListTile(
            title: const Text('Haptic feedback'),
            subtitle: const Text('Vibrate on toolbar key press'),
            secondary: const Icon(Icons.vibration),
            value: prefs.haptics,
            onChanged: (v) =>
                ref.read(preferencesProvider.notifier).setHaptics(v),
          ),
          const Divider(),
          _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Task completion'),
            subtitle:
                const Text('Notify when Claude goes idle after activity'),
            secondary: const Icon(Icons.notifications_outlined),
            value: prefs.notifyOnIdle,
            onChanged: (v) =>
                ref.read(preferencesProvider.notifier).setNotifyOnIdle(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Claude Carry'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final theme in ['dark', 'amoled', 'light'])
            ListTile(
              title: Text(theme[0].toUpperCase() + theme.substring(1)),
              onTap: () {
                ref.read(preferencesProvider.notifier).setTheme(theme);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
