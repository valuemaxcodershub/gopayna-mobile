import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._internal();
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;

  static const Color _brandColorLight = Color(0xFF00CA44); // updated vibrant light-mode brand green
  static const Color _brandColorDark = Color(0xFF00CA44);
  static const Color _accentColor = Color(0xFF0ACF83);

  static const Color brandColorLight = _brandColorLight;
  static const Color brandColorDark = _brandColorDark;
  static const Color accentColor = _accentColor;

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

  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandColorLight,
      brightness: Brightness.light,
      surface: Colors.white,
      secondary: const Color.fromARGB(255, 3, 204, 53),
    ).copyWith(
      primary: _brandColorLight,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      appBarTheme: const AppBarTheme(
        backgroundColor: _brandColorLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color.fromARGB(255, 5, 211, 67),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: const Color.fromARGB(255, 4, 221, 51),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 6, 231, 81),
          foregroundColor: const Color.fromARGB(255, 6, 230, 62),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandColorLight,
          side: const BorderSide(color: _brandColorLight),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _brandColorLight : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _brandColorLight.withValues(alpha: 0.35)
              : Colors.grey.shade300,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _brandColorLight,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brandColorLight, width: 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
    );
  }

  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandColorDark,
      brightness: Brightness.dark,
      surface: const Color(0xFF161B22),
      secondary: _accentColor,
    ).copyWith(
      primary: _brandColorDark,
      onPrimary: Colors.white,
      surfaceContainerHighest: const Color(0xFF1F242C),
      surfaceContainerLow: const Color(0xFF1B2129),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      canvasColor: const Color(0xFF0D1117),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F242C),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: Colors.white.withValues(alpha: 0.04),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandColorDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _brandColorDark : Colors.grey.shade500,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _brandColorDark.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111722),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentColor, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF161B22),
        surfaceTintColor: Colors.white.withValues(alpha: 0.05),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        contentTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
        bodyColor: Colors.white.withValues(alpha: 0.9),
        displayColor: Colors.white,
          ),
    );
  }
}
