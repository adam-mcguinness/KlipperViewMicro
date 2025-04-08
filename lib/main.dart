import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'api/klipper_api.dart';
// Import app.dart instead of directly using HomeScreen
import 'app.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(AppConstants.windowWidth, AppConstants.windowHeight),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Create API instance with default IP and port
  final api = KlipperApi(
      ipAddress: AppConstants.defaultIpAddress,
      port: AppConstants.defaultPort
  );

  // Use KlipperApp from app.dart instead of KlipperDirectApp
  runApp(KlipperApp(api: api));
}