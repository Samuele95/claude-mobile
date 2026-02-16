import '../models/server_profile.dart';

String _shellEscape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll(r'$', r'\$')
    .replaceAll('`', r'\`')
    .replaceAll('"', r'\"');

String buildStartupCommand(ServerProfile profile) => switch (profile.claudeMode) {
      ClaudeMode.standard => 'claude',
      ClaudeMode.skipPermissions => 'claude --dangerously-skip-permissions',
      ClaudeMode.customPrompt =>
        'claude -p "${_shellEscape(profile.customPrompt)}" --dangerously-skip-permissions',
    };
