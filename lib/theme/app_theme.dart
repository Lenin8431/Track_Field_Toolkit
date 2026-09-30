import 'package:flutter/material.dart';

/// 高对比度配色，适合户外阳光下查看。
const Color kPrimaryColor = Color(0xFF0B5FFF);
const Color kSecondaryColor = Color(0xFFE45A00);
const Color kSuccessColor = Color(0xFF0F8A4D);
const Color kDangerColor = Color(0xFFC62828);
const Color kPageBackground = Color(0xFFF3F6FA);
const Color kPrimaryContainer = Color(0xFFD9E6FF);
const Color kOnPrimaryContainer = Color(0xFF001A44);
const Color kTextColor = Color(0xFF10151C);
const Color kMutedTextColor = Color(0xFF3C4553);

ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: kPrimaryColor,
    onPrimary: Colors.white,
    primaryContainer: kPrimaryContainer,
    onPrimaryContainer: kOnPrimaryContainer,
    secondary: kSecondaryColor,
    onSecondary: Colors.white,
    tertiary: kSuccessColor,
    onTertiary: Colors.white,
    error: kDangerColor,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: kTextColor,
    onSurfaceVariant: kMutedTextColor,
  );

  final ThemeData base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kPageBackground,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 58,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: kTextColor,
      ),
      displayMedium: const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: kTextColor,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: kTextColor,
      ),
      headlineSmall: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: kTextColor,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kTextColor,
      ),
      titleMedium: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: kTextColor,
      ),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.35),
      bodyMedium: const TextStyle(fontSize: 14.5, height: 1.35),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kTextColor,
      elevation: 0,
    ),
  );
}
