import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class KeyDisplay extends ConsumerWidget {
  const KeyDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyAsync = ref.watch(appPublicKeyProvider);

    return keyAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load SSH key: $e',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ),
      ),
      data: (publicKey) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SSH Public Key',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                publicKey,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: publicKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Public key copied')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
