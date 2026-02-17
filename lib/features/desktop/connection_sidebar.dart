import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/server_profile.dart';
import '../../core/models/session.dart';
import '../../core/providers.dart';
import '../../core/utils/connect_action.dart';
import '../../core/utils/dialogs.dart';
import '../connection/add_server_sheet.dart';
import '../connection/key_display.dart';
import '../settings/settings_screen.dart';
import '../settings/about_screen.dart';

class ConnectionSidebar extends ConsumerStatefulWidget {
  const ConnectionSidebar({super.key});

  @override
  ConsumerState<ConnectionSidebar> createState() => _ConnectionSidebarState();
}

class _ConnectionSidebarState extends ConsumerState<ConnectionSidebar> {
  String? _connectingProfileId;

  Future<void> _connect(ServerProfile profile) async {
    await connectWithErrorHandling(
      context: context,
      ref: ref,
      profile: profile,
      isBusy: () => _connectingProfileId != null,
      onBusyStart: () => setState(() => _connectingProfileId = profile.id),
      onBusyEnd: () {
        if (mounted) setState(() => _connectingProfileId = null);
      },
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: const AddServerSheet(),
        ),
      ),
    );
  }

  void _showEditDialog(ServerProfile profile) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: AddServerSheet(existing: profile),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
    final activeId = ref.watch(activeSessionIdProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      color: colorScheme.surface,
      child: Column(
        children: [
          // Header with settings/about icons
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Claude Carry',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 480, maxHeight: 520),
                        child: const AboutScreen(),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 480, maxHeight: 600),
                        child: const SettingsScreen(),
                      ),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable content
          Expanded(
            child: profiles.when(
              data: (list) => ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Active sessions
                  if (sessions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: Text(
                        'ACTIVE SESSIONS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    ...sessions.map((session) => _CompactSessionTile(
                          session: session,
                          isActive: session.id == activeId,
                          onTap: () {
                            ref.read(activeSessionIdProvider.notifier).state =
                                session.id;
                          },
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Servers
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Text(
                      'SERVERS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No servers yet',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ...list.map((profile) => _CompactProfileTile(
                          profile: profile,
                          connecting: _connectingProfileId == profile.id,
                          onTap: () => _connect(profile),
                          onEdit: () => _showEditDialog(profile),
                          onDelete: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: 'Delete Server',
                              message:
                                  'Delete "${profile.name}"? This cannot be undone.',
                              confirmLabel: 'Delete',
                              destructive: true,
                            );
                            if (confirmed) {
                              ref
                                  .read(profilesProvider.notifier)
                                  .remove(profile.id);
                            }
                          },
                        )),

                  // Add server button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: OutlinedButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Server'),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: KeyDisplay(),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSessionTile extends StatelessWidget {
  final Session session;
  final bool isActive;
  final VoidCallback onTap;

  const _CompactSessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      selected: isActive,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: session.state.statusColor,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        session.profile.name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        session.state.label,
        style: const TextStyle(fontSize: 11),
      ),
      onTap: onTap,
    );
  }
}

class _CompactProfileTile extends StatelessWidget {
  final ServerProfile profile;
  final bool connecting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompactProfileTile({
    required this.profile,
    required this.connecting,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: connecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.dns_rounded, size: 20),
      title: Text(profile.name, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        '${profile.host}:${profile.port}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
