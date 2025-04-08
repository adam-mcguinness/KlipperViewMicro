import 'package:flutter/material.dart';
import 'package:klipper_view_micro/screens/test_screen.dart';
import 'api/klipper_api.dart';
import 'utils/constants.dart';

class KlipperApp extends StatefulWidget {
  final KlipperApi api;

  const KlipperApp({Key? key, required this.api}) : super(key: key);

  @override
  _KlipperAppState createState() => _KlipperAppState();
}

class _KlipperAppState extends State<KlipperApp> {
  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  Future<void> _connectToWebSocket() async {
    try {
      await widget.api.connect();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  @override
  void dispose() {
    widget.api.dispose();
    super.dispose();
  }

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
      // Pass the api to the first screen
      home: TestScreen(api: widget.api),
    );
  }
}