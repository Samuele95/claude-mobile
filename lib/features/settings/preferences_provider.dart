import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class AppPreferences {
  final String themeName;
  final double fontSize;
  final bool haptics;
  final bool notifyOnIdle;
  final int idleThresholdSeconds;
  final bool wakeLock;
  final bool autoReconnect;

  const AppPreferences({
    this.themeName = 'dark',
    this.fontSize = 14,
    this.haptics = true,
    this.notifyOnIdle = true,
    this.idleThresholdSeconds = 10,
    this.wakeLock = true,
    this.autoReconnect = true,
  });

  AppPreferences copyWith({
    String? themeName,
    double? fontSize,
    bool? haptics,
    bool? notifyOnIdle,
    int? idleThresholdSeconds,
    bool? wakeLock,
    bool? autoReconnect,
  }) {
    return AppPreferences(
      themeName: themeName ?? this.themeName,
      fontSize: fontSize ?? this.fontSize,
      haptics: haptics ?? this.haptics,
      notifyOnIdle: notifyOnIdle ?? this.notifyOnIdle,
      idleThresholdSeconds: idleThresholdSeconds ?? this.idleThresholdSeconds,
      wakeLock: wakeLock ?? this.wakeLock,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }

  ThemeData get themeData => switch (themeName) {
        'amoled' => AppTheme.amoled,
        'light' => AppTheme.light,
        _ => AppTheme.dark,
      };

  static Future<AppPreferences> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      themeName: prefs.getString('themeName') ?? 'dark',
      fontSize: prefs.getDouble('fontSize') ?? 14,
      haptics: prefs.getBool('haptics') ?? true,
      notifyOnIdle: prefs.getBool('notifyOnIdle') ?? true,
      idleThresholdSeconds: prefs.getInt('idleThresholdSeconds') ?? 10,
      wakeLock: prefs.getBool('wakeLock') ?? true,
      autoReconnect: prefs.getBool('autoReconnect') ?? true,
    );
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeName', themeName);
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setBool('haptics', haptics);
    await prefs.setBool('notifyOnIdle', notifyOnIdle);
    await prefs.setInt('idleThresholdSeconds', idleThresholdSeconds);
    await prefs.setBool('wakeLock', wakeLock);
    await prefs.setBool('autoReconnect', autoReconnect);
  }
}

final initialPreferencesProvider = Provider<AppPreferences?>((_) => null);

class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() =>
      ref.read(initialPreferencesProvider) ?? const AppPreferences();

  void setTheme(String name) {
    state = state.copyWith(themeName: name);
    state.saveToDisk();
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
    state.saveToDisk();
  }

  void setHaptics(bool enabled) {
    state = state.copyWith(haptics: enabled);
    state.saveToDisk();
  }

  void setNotifyOnIdle(bool enabled) {
    state = state.copyWith(notifyOnIdle: enabled);
    state.saveToDisk();
  }

  void setIdleThreshold(int seconds) {
    state = state.copyWith(idleThresholdSeconds: seconds);
    state.saveToDisk();
  }

  void setWakeLock(bool enabled) {
    state = state.copyWith(wakeLock: enabled);
    state.saveToDisk();
  }

  void setAutoReconnect(bool enabled) {
    state = state.copyWith(autoReconnect: enabled);
    state.saveToDisk();
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
  PreferencesNotifier.new,
);
