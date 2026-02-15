import 'dart:io';
import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: Colors.redAccent)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required Object error,
  VoidCallback? onRetry,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(_friendlyError(error)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('Retry'),
          ),
      ],
    ),
  );
}

String _friendlyError(Object error) {
  final msg = error.toString();
  if (error is SocketException || msg.contains('SocketException')) {
    return 'Could not reach server. Check the host address and your network connection.';
  }
  if (msg.contains('Authentication') || msg.contains('auth')) {
    return 'Authentication failed. Check your username and password or SSH key.';
  }
  if (msg.contains('Connection refused')) {
    return 'Connection refused. Make sure SSH is running on the server.';
  }
  if (msg.contains('timed out') || msg.contains('TimeoutException')) {
    return 'Connection timed out. The server may be unreachable.';
  }
  return msg;
}
