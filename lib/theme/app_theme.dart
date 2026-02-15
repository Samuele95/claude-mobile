import 'package:flutter/material.dart';

class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF7C3AED),
    fontFamily: 'JetBrainsMono',
    scaffoldBackgroundColor: const Color(0xFF1E1E2E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E2E),
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF2A2A3C),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A3C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static final amoled = dark.copyWith(
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF121212),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF7C3AED),
    fontFamily: 'JetBrainsMono',
  );
}
