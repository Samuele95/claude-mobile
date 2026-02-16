import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initDesktopWindow() async {
  await windowManager.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final width = prefs.getDouble('window_width') ?? 1200;
  final height = prefs.getDouble('window_height') ?? 800;

  final options = WindowOptions(
    size: Size(width, height),
    minimumSize: const Size(900, 600),
    center: true,
    title: 'Claude Carry',
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> setWindowTitle(String title) async {
  await windowManager.setTitle(title);
}

Future<void> saveWindowBounds() async {
  try {
    final size = await windowManager.getSize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('window_width', size.width);
    await prefs.setDouble('window_height', size.height);
  } catch (_) {
    // Window may be closing, ignore errors
  }
}
