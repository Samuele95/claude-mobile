import 'dart:io';
import 'package:flutter/widgets.dart';

bool get isMobile => Platform.isAndroid || Platform.isIOS;
bool get isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 800;

String get defaultLocalPath {
  if (Platform.isAndroid) return '/storage/emulated/0';
  return Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '/';
}
