import 'package:flutter/material.dart';

abstract final class RoyalColors {
  static const midnight = Color(0xFF0B132B);
  static const surface = Color(0xFF182642);
  static const border = Color(0xFF31435F);
  static const text = Color(0xFFF2F7FF);
  static const muted = Color(0xFF9EACC2);
  static const cyan = Color(0xFF55D6FF);
  static const teal = Color(0xFF62E9C7);
  static const gold = Color(0xFFFFB340);
  static const purple = Color(0xFFDA35F5);
}

ThemeData royalDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: RoyalColors.cyan,
    brightness: Brightness.dark,
    surface: RoyalColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: RoyalColors.midnight,
    appBarTheme: const AppBarTheme(
      backgroundColor: RoyalColors.midnight,
      foregroundColor: RoyalColors.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: RoyalColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: RoyalColors.border),
      ),
    ),
  );
}
