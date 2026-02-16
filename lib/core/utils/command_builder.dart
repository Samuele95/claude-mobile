import '../models/server_profile.dart';

/// Escapes a string for use inside double-quoted shell strings.
/// Handles backslash, dollar, backtick, double-quote, bang, and newlines.
String shellEscape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll(r'$', r'\$')
    .replaceAll('`', r'\`')
    .replaceAll('"', r'\"')
    .replaceAll('!', r'\!')
    .replaceAll('\n', r'\n');

String buildStartupCommand(ServerProfile profile) => switch (profile.claudeMode) {
      ClaudeMode.standard => 'claude',
      ClaudeMode.skipPermissions => 'claude --dangerously-skip-permissions',
      ClaudeMode.customPrompt =>
        'claude -p "${shellEscape(profile.customPrompt)}" --dangerously-skip-permissions',
    };
