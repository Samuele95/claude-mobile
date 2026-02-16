import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/session.dart';
import '../../core/providers.dart';
import '../../core/utils/platform_utils.dart';

class SessionTabBar extends ConsumerWidget {
  final VoidCallback onNewSession;

  const SessionTabBar({super.key, required this.onNewSession});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
    final activeId = ref.watch(activeSessionIdProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isActive = session.id == activeId;
                return _SessionTab(
                  session: session,
                  isActive: isActive,
                  stateColor: session.state.statusColor,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(activeSessionIdProvider.notifier).state =
                        session.id;
                  },
                  onClose: () async {
                    await ref
                        .read(connectionManagerProvider)
                        .closeSession(session.id);
                    final remaining =
                        ref.read(sessionsProvider).valueOrNull ?? [];
                    if (remaining.isEmpty) {
                      ref.read(activeSessionIdProvider.notifier).state = null;
                    } else if (activeId == session.id) {
                      ref.read(activeSessionIdProvider.notifier).state =
                          remaining.first.id;
                    }
                  },
                  onReconnect: () {
                    ref
                        .read(connectionManagerProvider)
                        .reconnectSession(session.id);
                  },
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 20, color: colorScheme.primary),
            onPressed: onNewSession,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
          ),
        ],
      ),
    );
  }
}

class _SessionTab extends StatelessWidget {
  final Session session;
  final bool isActive;
  final Color stateColor;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onReconnect;

  const _SessionTab({
    required this.session,
    required this.isActive,
    required this.stateColor,
    required this.onTap,
    required this.onClose,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        if (isMobile) HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reconnect'),
                onTap: () {
                  Navigator.pop(context);
                  onReconnect();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.redAccent),
                title: const Text('Close session',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  onClose();
                },
              ),
            ],
          ),
        );
      },
      onSecondaryTapDown: isDesktop
          ? (details) {
              final overlay = Overlay.of(context)
                  .context
                  .findRenderObject() as RenderBox;
              showMenu<String>(
                context: context,
                position: RelativeRect.fromRect(
                  details.globalPosition & const Size(1, 1),
                  Offset.zero & overlay.size,
                ),
                items: const [
                  PopupMenuItem(value: 'reconnect', child: Text('Reconnect')),
                  PopupMenuItem(
                    value: 'close',
                    child: Text('Close session',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ).then((value) {
                if (value == 'reconnect') onReconnect();
                if (value == 'close') onClose();
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? null
              : Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: stateColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              session.profile.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
