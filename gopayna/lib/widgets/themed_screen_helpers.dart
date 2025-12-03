import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

mixin ThemedScreenHelpers<T extends StatefulWidget> on State<T> {
  ColorScheme get colorScheme => Theme.of(context).colorScheme;
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get cardColor => colorScheme.surface;
  Color get borderColor => colorScheme.outlineVariant;
  Color get mutedTextColor =>
      colorScheme.onSurface.withValues(alpha: isDarkMode ? 0.65 : 0.6);
  Color get shadowColor => isDarkMode
      ? Colors.black.withValues(alpha: 0.4)
      : const Color.fromARGB(255, 42, 224, 5).withValues(alpha: 0.08);
  SystemUiOverlayStyle get statusBarStyle =>
      isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}

