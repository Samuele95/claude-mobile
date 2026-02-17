import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../theme/terminal_theme.dart';
import 'package:xterm/xterm.dart';

enum AppThemeName {
  dark,
  amoled,
  light;

  String get displayName => switch (this) {
        AppThemeName.dark => 'Dark',
        AppThemeName.amoled => 'AMOLED',
        AppThemeName.light => 'Light',
      };

  ThemeData get materialTheme => switch (this) {
        AppThemeName.dark => AppTheme.dark,
        AppThemeName.amoled => AppTheme.amoled,
        AppThemeName.light => AppTheme.light,
      };

  TerminalTheme get terminalTheme => switch (this) {
        AppThemeName.dark => AppTerminalThemes.dark,
        AppThemeName.amoled => AppTerminalThemes.amoled,
        AppThemeName.light => AppTerminalThemes.light,
      };

  static AppThemeName fromString(String name) => switch (name) {
        'amoled' => AppThemeName.amoled,
        'light' => AppThemeName.light,
        _ => AppThemeName.dark,
      };
}

class AppPreferences {
  final AppThemeName theme;
  final double fontSize;
  final bool haptics;
  final bool wakeLock;
  final bool autoReconnect;

  const AppPreferences({
    this.theme = AppThemeName.dark,
    this.fontSize = 14,
    this.haptics = true,
    this.wakeLock = true,
    this.autoReconnect = true,
  });

  AppPreferences copyWith({
    AppThemeName? theme,
    double? fontSize,
    bool? haptics,
    bool? wakeLock,
    bool? autoReconnect,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      haptics: haptics ?? this.haptics,
      wakeLock: wakeLock ?? this.wakeLock,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }

  ThemeData get themeData => theme.materialTheme;

  static Future<AppPreferences> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      theme: AppThemeName.fromString(prefs.getString('themeName') ?? 'dark'),
      fontSize: prefs.getDouble('fontSize') ?? 14,
      haptics: prefs.getBool('haptics') ?? true,
      wakeLock: prefs.getBool('wakeLock') ?? true,
      autoReconnect: prefs.getBool('autoReconnect') ?? true,
    );
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeName', theme.name);
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setBool('haptics', haptics);
    await prefs.setBool('wakeLock', wakeLock);
    await prefs.setBool('autoReconnect', autoReconnect);
  }
}

final initialPreferencesProvider = Provider<AppPreferences?>((_) => null);

class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() =>
      ref.read(initialPreferencesProvider) ?? const AppPreferences();

  void _updateAndPersist(AppPreferences newState) {
    state = newState;
    newState.saveToDisk().catchError((e) {
      developer.log('Failed to persist preferences: $e', name: 'Preferences');
    });
  }

  void setTheme(AppThemeName theme) =>
      _updateAndPersist(state.copyWith(theme: theme));

  void setFontSize(double size) =>
      _updateAndPersist(state.copyWith(fontSize: size));

  void setHaptics(bool enabled) =>
      _updateAndPersist(state.copyWith(haptics: enabled));

  void setWakeLock(bool enabled) =>
      _updateAndPersist(state.copyWith(wakeLock: enabled));

  void setAutoReconnect(bool enabled) =>
      _updateAndPersist(state.copyWith(autoReconnect: enabled));
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
  PreferencesNotifier.new,
);
