import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  HomeWidget.setAppGroupId('com.claudemobile.claude_mobile');
  HomeWidget.registerInteractivityCallback(interactivityCallback);

  runApp(const ProviderScope(child: ClaudeMobileApp()));
}

@pragma('vm:entry-point')
Future<void> interactivityCallback(Uri? uri) async {
  // Handle widget tap — the app opens via the PendingIntent,
  // this callback allows updating widget state if needed.
  if (uri?.host == 'prompt') {
    await HomeWidget.saveWidgetData<String>('status', 'idle');
    await HomeWidget.updateWidget(name: 'QuickPromptWidgetProvider');
  }
}
