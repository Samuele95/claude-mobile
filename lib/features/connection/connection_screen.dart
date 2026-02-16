import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/server_profile.dart';
import '../../core/models/session.dart';
import '../../core/providers.dart';
import '../../core/utils/dialogs.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';
import '../settings/preferences_provider.dart';
import 'add_server_sheet.dart';
import 'key_display.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  bool _connecting = false;

  Future<void> _connect(ServerProfile profile) async {
    if (_connecting) return;
    setState(() => _connecting = true);

    try {
      final manager = ref.read(connectionManagerProvider);
      final storage = ref.read(secureStorageProvider);
      final prefs = ref.read(preferencesProvider);

      if (prefs.haptics) HapticFeedback.lightImpact();

      String? password;
      if (profile.authMethod == AuthMethod.password) {
        password = await storage.read(key: 'password_${profile.id}');
      }

      final sessionId =
          await manager.createSession(profile, password: password);
      ref.read(activeSessionIdProvider.notifier).state = sessionId;
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          title: 'Connection Failed',
          error: e,
          onRetry: () => _connect(profile),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AboutScreen()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Claude Carry',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI dev environment, in your pocket.',
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
                      // Active Sessions section
                      if (sessions.isNotEmpty) ...[
                        Text(
                          'ACTIVE SESSIONS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sessions.map((session) => _ActiveSessionCard(
                              session: session,
                              onTap: () {
                                ref
                                    .read(activeSessionIdProvider.notifier)
                                    .state = session.id;
                              },
                            )),
                        const SizedBox(height: 24),
                        Text(
                          'SERVERS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Empty state
                      if (list.isEmpty)
                        _EmptyState(
                          onAddServer: () => _showAddSheet(context),
                        )
                      else
                        ...list.map((profile) => Dismissible(
                              key: ValueKey(profile.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => showConfirmDialog(
                                context,
                                title: 'Delete Server',
                                message:
                                    'Delete "${profile.name}"? This cannot be undone.',
                                confirmLabel: 'Delete',
                                destructive: true,
                              ),
                              onDismissed: (_) => ref
                                  .read(profilesProvider.notifier)
                                  .remove(profile.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: _ProfileCard(
                                profile: profile,
                                connecting: _connecting,
                                onTap: () =>
                                    _connect(profile),
                                onEdit: () =>
                                    _showEditSheet(context, profile),
                              ),
                            )),
                      if (list.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _AddServerCard(
                            onTap: () => _showAddSheet(context)),
                      ],
                      const SizedBox(height: 24),
                      const KeyDisplay(),
                      SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 24),
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

  void _showEditSheet(BuildContext context, ServerProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddServerSheet(existing: profile),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const _ActiveSessionCard({required this.session, required this.onTap});

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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: session.state.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.profile.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      session.state.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddServer;

  const _EmptyState({required this.onAddServer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.dns_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No servers yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a server to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddServer,
              icon: const Icon(Icons.add),
              label: const Text('Add Server'),
            ),
            const SizedBox(height: 24),
            const KeyDisplay(),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ServerProfile profile;
  final bool connecting;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.profile,
    required this.connecting,
    required this.onTap,
    required this.onEdit,
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
                child: connecting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
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
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
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
