import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/utils/command_builder.dart';
import 'package:claude_mobile/core/models/server_profile.dart';

/// Tests for command building and shell escaping.
///
/// Critical path: these commands are sent to remote servers via SSH.
/// Incorrect escaping could cause command injection (security concern).
void main() {
  ServerProfile makeProfile({
    ClaudeMode mode = ClaudeMode.standard,
    String customPrompt = '',
  }) {
    return ServerProfile(
      id: 'test',
      name: 'Test',
      host: 'example.com',
      username: 'user',
      claudeMode: mode,
      customPrompt: customPrompt,
      createdAt: DateTime.now(),
    );
  }

  group('buildStartupCommand', () {
    test('standard mode produces plain claude command', () {
      final cmd = buildStartupCommand(makeProfile(mode: ClaudeMode.standard));
      expect(cmd, 'claude');
    });

    test('skipPermissions mode includes --dangerously-skip-permissions flag', () {
      final cmd = buildStartupCommand(makeProfile(mode: ClaudeMode.skipPermissions));
      expect(cmd, 'claude --dangerously-skip-permissions');
    });

    test('customPrompt mode wraps prompt in -p flag with skip-permissions', () {
      final cmd = buildStartupCommand(
        makeProfile(mode: ClaudeMode.customPrompt, customPrompt: 'fix the bug'),
      );
      expect(cmd, 'claude -p "fix the bug" --dangerously-skip-permissions');
    });

    test('customPrompt escapes double quotes in user input', () {
      final cmd = buildStartupCommand(
        makeProfile(
          mode: ClaudeMode.customPrompt,
          customPrompt: 'say "hello"',
        ),
      );
      expect(cmd, contains(r'say \"hello\"'));
    });

    test('customPrompt escapes dollar signs to prevent variable expansion', () {
      final cmd = buildStartupCommand(
        makeProfile(
          mode: ClaudeMode.customPrompt,
          customPrompt: r'echo $HOME',
        ),
      );
      expect(cmd, contains(r'echo \$HOME'));
    });

    test('customPrompt escapes backticks to prevent command substitution', () {
      final cmd = buildStartupCommand(
        makeProfile(
          mode: ClaudeMode.customPrompt,
          customPrompt: 'run `whoami`',
        ),
      );
      expect(cmd, contains(r'run \`whoami\`'));
    });

    test('customPrompt escapes backslashes', () {
      final cmd = buildStartupCommand(
        makeProfile(
          mode: ClaudeMode.customPrompt,
          customPrompt: r'path\to\file',
        ),
      );
      expect(cmd, contains(r'path\\to\\file'));
    });

    test('customPrompt escapes newlines', () {
      final cmd = buildStartupCommand(
        makeProfile(
          mode: ClaudeMode.customPrompt,
          customPrompt: 'line1\nline2',
        ),
      );
      expect(cmd, contains(r'line1\nline2'));
    });
  });

  group('shellEscape', () {
    test('escapes all dangerous shell characters', () {
      final result = shellEscape(r'$`"\!');
      expect(result, r'\$\`\"\\\!');
    });

    test('leaves safe characters untouched', () {
      const safe = 'hello world 123 abc';
      expect(shellEscape(safe), safe);
    });

    test('handles empty string', () {
      expect(shellEscape(''), '');
    });
  });
}
