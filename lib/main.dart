import 'package:flutter/material.dart';
import 'package:klipper_view_micro/providers/printer_state_provider.dart';
import 'package:klipper_view_micro/screens/control_screen.dart';
import 'package:klipper_view_micro/screens/file_list_screen.dart';
import 'package:klipper_view_micro/screens/status_screen.dart';
import 'package:klipper_view_micro/screens/system_usage.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
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

  // Run the app with MaterialApp directly
  runApp(
    const KlipperViewApp(),
  );
}

class KlipperViewApp extends StatelessWidget {
  const KlipperViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PrinterStateProvider(),
      child: MaterialApp(
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
            surface: AppTheme.backgroundColor,
          ),
          scaffoldBackgroundColor: AppTheme.backgroundColor,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: AppTheme.textColor),
            titleMedium: TextStyle(color: AppTheme.textColor),
          ),
        ),
      ),
    );
  }
}