import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/utils/platform_utils.dart';
import 'remote_browser.dart';
import 'local_browser.dart';

class FilePanel extends ConsumerWidget {
  final String sessionId;
  final bool isDrawer;

  const FilePanel({super.key, required this.sessionId, this.isDrawer = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(sessionTerminalControllerProvider(sessionId));

    return SafeArea(
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Files',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 28,
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'REMOTE SERVER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: RemoteBrowser(
                    sessionId: sessionId,
                    onSendToTerminal: (path) {
                      controller?.sendText(path);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 28,
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isMobile ? 'LOCAL PHONE' : 'LOCAL FILES',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Expanded(child: LocalBrowser()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
