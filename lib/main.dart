import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'api/klipper_api.dart';
import 'screens/home_screen.dart';
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

  runApp(KlipperDirectApp(api: api));
}

// App class that goes directly to the home screen
class KlipperDirectApp extends StatelessWidget {
  final KlipperApi api;

  const KlipperDirectApp({Key? key, required this.api}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klipper Control',
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
      home: HomeScreen(api: api),
    );
  }
}