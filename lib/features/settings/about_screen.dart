import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.8.0';
  static const _repoUrl = 'https://github.com/Samuele95/claude-carry';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const SizedBox(height: 16),
          // Logo
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/logo.png',
                  width: 96,
                  height: 96,
                  errorBuilder: (_, e, s) => const Icon(
                    Icons.terminal_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // App name
          Center(
            child: Text(
              'Claude Carry',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          // Version
          Center(
            child: Text(
              'v$_version',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          // Tagline
          Center(
            child: Text(
              'Your AI dev environment, in your pocket.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Info cards
          _InfoCard(
            icon: Icons.code_rounded,
            title: 'Open Source',
            subtitle: 'MIT License — free to use, modify, and distribute.',
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.flutter_dash,
            title: 'Built with Flutter',
            subtitle: 'Cross-platform — Android, iOS, and desktop.',
            color: const Color(0xFF027DFD),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.terminal_rounded,
            title: 'Powered by Claude Code',
            subtitle: 'SSH into your dev server and let Claude work for you.',
            color: const Color(0xFFA6E3A1),
          ),
          const SizedBox(height: 24),
          // Links section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: const Text('GitHub Repository'),
                  subtitle: const Text('Samuele95/claude-carry'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(context, _repoUrl),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Report a Bug'),
                  subtitle: const Text('Open an issue on GitHub'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(
                      context, '$_repoUrl/issues/new'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: const Text('Star on GitHub'),
                  subtitle: const Text('If Claude Carry saved you a trip to your desk'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(context, _repoUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Footer
          Center(
            child: Text(
              'Made with \u{1F916} + \u{2615}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: copy to clipboard
      Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $url'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
