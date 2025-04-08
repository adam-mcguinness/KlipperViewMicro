import 'package:flutter/material.dart';
import 'api/klipper_api.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

class KlipperApp extends StatelessWidget {
  final KlipperApi api;

  const KlipperApp({Key? key, required this.api}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klipper Control',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Calculate the device pixel ratio for accurate rendering
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