import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';

class AppPreferences {
  final String themeName;
  final double fontSize;
  final bool haptics;
  final bool notifyOnIdle;
  final int idleThresholdSeconds;

  const AppPreferences({
    this.themeName = 'dark',
    this.fontSize = 14,
    this.haptics = true,
    this.notifyOnIdle = true,
    this.idleThresholdSeconds = 10,
  });

  AppPreferences copyWith({
    String? themeName,
    double? fontSize,
    bool? haptics,
    bool? notifyOnIdle,
    int? idleThresholdSeconds,
  }) {
    return AppPreferences(
      themeName: themeName ?? this.themeName,
      fontSize: fontSize ?? this.fontSize,
      haptics: haptics ?? this.haptics,
      notifyOnIdle: notifyOnIdle ?? this.notifyOnIdle,
      idleThresholdSeconds: idleThresholdSeconds ?? this.idleThresholdSeconds,
    );
  }

  ThemeData get themeData => switch (themeName) {
        'amoled' => AppTheme.amoled,
        'light' => AppTheme.light,
        _ => AppTheme.dark,
      };
}

class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => const AppPreferences();

  void setTheme(String name) => state = state.copyWith(themeName: name);
  void setFontSize(double size) => state = state.copyWith(fontSize: size);
  void setHaptics(bool enabled) => state = state.copyWith(haptics: enabled);
  void setNotifyOnIdle(bool enabled) =>
      state = state.copyWith(notifyOnIdle: enabled);
  void setIdleThreshold(int seconds) =>
      state = state.copyWith(idleThresholdSeconds: seconds);
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
  PreferencesNotifier.new,
);
