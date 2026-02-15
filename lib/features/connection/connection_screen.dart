import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/server_profile.dart';
import '../../core/providers.dart';
import '../settings/settings_screen.dart';
import 'add_server_sheet.dart';
import 'key_display.dart';

class ConnectionScreen extends ConsumerWidget {
  const ConnectionScreen({super.key});

  Future<void> _connect(WidgetRef ref, ServerProfile profile) async {
    final ssh = ref.read(sshServiceProvider);
    final sftp = ref.read(sftpServiceProvider);
    final storage = ref.read(secureStorageProvider);

    try {
      String? password;
      if (profile.authMethod == AuthMethod.password) {
        password = await storage.read(key: 'password_${profile.id}');
      }

      await ssh.connect(profile, password: password);
      ssh.write('claude --dangerously-skip-permissions\n');
      if (ssh.client != null) {
        await sftp.initialize(ssh.client!);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Claude Mobile',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect to your server',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: profiles.when(
                  data: (list) => ListView(
                    children: [
                      ...list.map((profile) => _ProfileCard(
                            profile: profile,
                            onTap: () => _connect(ref, profile),
                            onDelete: () => ref
                                .read(profilesProvider.notifier)
                                .remove(profile.id),
                          )),
                      const SizedBox(height: 12),
                      _AddServerCard(
                          onTap: () => _showAddSheet(context)),
                      const SizedBox(height: 24),
                      const KeyDisplay(),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddServerSheet(),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ServerProfile profile;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dns_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${profile.host}:${profile.port}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddServerCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddServerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Server',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
