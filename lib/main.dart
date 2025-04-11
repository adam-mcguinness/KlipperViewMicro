import 'package:flutter/material.dart';
import 'package:klipper_view_micro/screens/control_screen.dart';
import 'package:klipper_view_micro/screens/file_list_screen.dart';
import 'package:klipper_view_micro/screens/status_screen.dart';
import 'package:klipper_view_micro/screens/system_usage.dart';
import 'package:klipper_view_micro/services/api_services.dart';
import 'package:window_manager/window_manager.dart';
import 'api/klipper_api.dart';
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
  final api = KlipperApi();
  await api.connect();

  // Run the app with MaterialApp directly
  runApp(
    const KlipperViewApp(),
  );

  // Add a shutdown hook to dispose the API when the app is closed
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final binding = WidgetsBinding.instance;
    binding.addObserver(AppLifecycleObserver(api));
  });
}

class KlipperViewApp extends StatelessWidget {
  const KlipperViewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klipper Control',
      routes: {
        '/': (context) => const StatusScreen(),
        '/system_usage': (context) => const SystemUsage(),
        '/control_screen': (context) => const ControlsScreen(),
        '/file_list': (context) => const FileListScreen(),
      },
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final targetDevicePixelRatio = AppConstants.targetPPI / AppConstants.referencePPI;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            devicePixelRatio: targetDevicePixelRatio,
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppTheme.primaryColor,
          secondary: AppTheme.secondaryColor,
          background: AppTheme.backgroundColor,
        ),
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppTheme.textColor),
          titleMedium: TextStyle(color: AppTheme.textColor),
        ),
      ),
    );
  }
}

// Observer to handle app lifecycle events
class AppLifecycleObserver extends WidgetsBindingObserver {
  final KlipperApi api;

  AppLifecycleObserver(this.api);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      api.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Try to reconnect if the app is resumed
      if (!api.isConnected) {
        api.connect().catchError((e) {
          print('Error reconnecting on resume: $e');
        });
      }
    }
  }
}