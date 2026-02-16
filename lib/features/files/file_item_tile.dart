import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FileItemTile extends StatelessWidget {
  final String name;
  final bool isDirectory;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onSecondaryTapDown;

  const FileItemTile({
    super.key,
    required this.name,
    required this.isDirectory,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
  });

  IconData get _icon {
    if (isDirectory) return Icons.folder_rounded;
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' || 'py' || 'js' || 'ts' || 'rs' || 'go' || 'java' ||
      'kt' || 'c' || 'cpp' || 'h' =>
        Icons.code_rounded,
      'md' || 'txt' || 'log' => Icons.description_rounded,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' =>
        Icons.image_rounded,
      'pdf' => Icons.picture_as_pdf_rounded,
      'zip' || 'tar' || 'gz' => Icons.archive_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  Color _iconColor(BuildContext context) {
    if (isDirectory) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: onSecondaryTapDown,
      child: ListTile(
      dense: true,
      leading: Icon(_icon, color: _iconColor(context), size: 22),
      title: Text(
        name,
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 11))
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress,
      ),
    );
  }
}
