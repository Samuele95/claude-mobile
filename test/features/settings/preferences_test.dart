import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/features/settings/preferences_provider.dart';

void main() {
  group('AppPreferences', () {
    test('defaults are sensible', () {
      const prefs = AppPreferences();

      expect(prefs.theme, AppThemeName.dark);
      expect(prefs.fontSize, 14);
      expect(prefs.haptics, isTrue);
      expect(prefs.wakeLock, isTrue);
      expect(prefs.autoReconnect, isTrue);
    });

    group('copyWith', () {
      test('updates theme while preserving other fields', () {
        const original = AppPreferences();
        final updated = original.copyWith(theme: AppThemeName.amoled);

        expect(updated.theme, AppThemeName.amoled);
        expect(updated.fontSize, original.fontSize);
        expect(updated.haptics, original.haptics);
      });

      test('updates multiple fields simultaneously', () {
        const original = AppPreferences();
        final updated = original.copyWith(
          fontSize: 18,
          haptics: false,
          autoReconnect: false,
        );

        expect(updated.fontSize, 18);
        expect(updated.haptics, isFalse);
        expect(updated.autoReconnect, isFalse);
        expect(updated.theme, original.theme); // unchanged
      });
    });

    test('themeData returns a valid ThemeData', () {
      const prefs = AppPreferences();
      expect(prefs.themeData, isA<ThemeData>());
    });
  });

  group('AppThemeName', () {
    test('every theme has a non-empty displayName', () {
      for (final theme in AppThemeName.values) {
        expect(theme.displayName, isNotEmpty);
      }
    });

    test('every theme produces a valid ThemeData', () {
      for (final theme in AppThemeName.values) {
        expect(theme.materialTheme, isA<ThemeData>());
      }
    });

    test('every theme produces a valid TerminalTheme', () {
      for (final theme in AppThemeName.values) {
        expect(theme.terminalTheme, isNotNull);
      }
    });

    test('fromString maps known names correctly', () {
      expect(AppThemeName.fromString('dark'), AppThemeName.dark);
      expect(AppThemeName.fromString('amoled'), AppThemeName.amoled);
      expect(AppThemeName.fromString('light'), AppThemeName.light);
    });

    test('fromString defaults to dark for unknown names', () {
      expect(AppThemeName.fromString('unknown'), AppThemeName.dark);
      expect(AppThemeName.fromString(''), AppThemeName.dark);
    });
  });
}
