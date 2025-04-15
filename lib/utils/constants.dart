import 'package:flutter/material.dart';

// App-wide constants
class AppConstants {
  // Default Klipper connection settings
  static const String defaultIpAddress = '192.168.0.215'; // Change this to your printer's IP
  static const int defaultPort = 7125;

  // Display constants (from original code)
  static const double targetPPI = 332.0;
  static const double referencePPI = 254.0;

  // Window dimensions
  static const double windowWidth = 410;
  static const double windowHeight = 502;

  // UI refresh rate
  static const Duration refreshInterval = Duration(seconds: 5);
}

// Theme and colors
class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF0559C9);
  static const Color secondaryColor = Color(0xFF00A0D2);
  static const Color backgroundColor = Colors.black;
  static const Color textColor = Colors.white;
  static const Color textColorSecondary = Colors.white70;
  static const Color borderColor = Colors.white24;

  // Text styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textColor,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: textColorSecondary,
  );

  // ThemeData
  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textColor),
      titleMedium: TextStyle(color: textColor),
    ),
  );

  // Input decoration theme
  static InputDecorationTheme inputDecorationTheme = const InputDecorationTheme(
    labelStyle: TextStyle(color: textColorSecondary),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white30),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: secondaryColor),
    ),
  );
}