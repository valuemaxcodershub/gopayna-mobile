import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  bool _isDarkMode = false;
  bool _showWalletBalance = true;

  bool get isDarkMode => _isDarkMode;
  bool get showWalletBalance => _showWalletBalance;

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleWalletBalance(bool value) {
    _showWalletBalance = value;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.green,
    primaryColor: const Color(0xFF00B82E),
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00B82E),
      secondary: Color(0xFF00A525),
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFF8F9FA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onSurfaceVariant: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black12,
      elevation: 2,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    primarySwatch: Colors.green,
    primaryColor: const Color(0xFF00B82E),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00B82E),
      secondary: Color(0xFF00A525),
      surface: Color(0xFF1E1E1E),
      surfaceContainerHighest: Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      shadowColor: Colors.black54,
      elevation: 2,
    ),
  );
}