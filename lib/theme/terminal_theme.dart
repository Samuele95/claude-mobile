import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class AppTerminalThemes {
  static final dark = TerminalTheme(
    cursor: const Color(0xFFA6ADC8),
    selection: const Color(0x407C3AED),
    foreground: const Color(0xFFCDD6F4),
    background: const Color(0xFF1E1E2E),
    black: const Color(0xFF45475A),
    red: const Color(0xFFF38BA8),
    green: const Color(0xFFA6E3A1),
    yellow: const Color(0xFFF9E2AF),
    blue: const Color(0xFF89B4FA),
    magenta: const Color(0xFFF5C2E7),
    cyan: const Color(0xFF94E2D5),
    white: const Color(0xFFBAC2DE),
    brightBlack: const Color(0xFF585B70),
    brightRed: const Color(0xFFF38BA8),
    brightGreen: const Color(0xFFA6E3A1),
    brightYellow: const Color(0xFFF9E2AF),
    brightBlue: const Color(0xFF89B4FA),
    brightMagenta: const Color(0xFFF5C2E7),
    brightCyan: const Color(0xFF94E2D5),
    brightWhite: const Color(0xFFA6ADC8),
    searchHitBackground: const Color(0xFF7C3AED),
    searchHitBackgroundCurrent: const Color(0xFFA855F7),
    searchHitForeground: const Color(0xFFFFFFFF),
  );

  static final amoled = TerminalTheme(
    cursor: dark.cursor,
    selection: dark.selection,
    foreground: dark.foreground,
    background: const Color(0xFF000000),
    black: dark.black,
    red: dark.red,
    green: dark.green,
    yellow: dark.yellow,
    blue: dark.blue,
    magenta: dark.magenta,
    cyan: dark.cyan,
    white: dark.white,
    brightBlack: dark.brightBlack,
    brightRed: dark.brightRed,
    brightGreen: dark.brightGreen,
    brightYellow: dark.brightYellow,
    brightBlue: dark.brightBlue,
    brightMagenta: dark.brightMagenta,
    brightCyan: dark.brightCyan,
    brightWhite: dark.brightWhite,
    searchHitBackground: dark.searchHitBackground,
    searchHitBackgroundCurrent: dark.searchHitBackgroundCurrent,
    searchHitForeground: dark.searchHitForeground,
  );

  // Catppuccin Latte palette
  static final light = TerminalTheme(
    cursor: const Color(0xFF4C4F69),
    selection: const Color(0x407C3AED),
    foreground: const Color(0xFF4C4F69),
    background: const Color(0xFFEFF1F5),
    black: const Color(0xFF5C5F77),
    red: const Color(0xFFD20F39),
    green: const Color(0xFF40A02B),
    yellow: const Color(0xFFDF8E1D),
    blue: const Color(0xFF1E66F5),
    magenta: const Color(0xFFEA76CB),
    cyan: const Color(0xFF179299),
    white: const Color(0xFFACB0BE),
    brightBlack: const Color(0xFF6C6F85),
    brightRed: const Color(0xFFD20F39),
    brightGreen: const Color(0xFF40A02B),
    brightYellow: const Color(0xFFDF8E1D),
    brightBlue: const Color(0xFF1E66F5),
    brightMagenta: const Color(0xFFEA76CB),
    brightCyan: const Color(0xFF179299),
    brightWhite: const Color(0xFF4C4F69),
    searchHitBackground: const Color(0xFF7C3AED),
    searchHitBackgroundCurrent: const Color(0xFFA855F7),
    searchHitForeground: const Color(0xFFFFFFFF),
  );

  static TerminalTheme fromPreferences(String themeName) => switch (themeName) {
        'amoled' => amoled,
        'light' => light,
        _ => dark,
      };
}
