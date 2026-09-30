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
    // 注意：这里必须用 base 里已有样式 copyWith，保留 ColorScheme 提供的文字颜色，
    // 否则 color 会变成 null，未显式指定颜色的文字（输入框内容、表格数据行等）会显示为空白。
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge!.copyWith(
        fontSize: 58,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      displayMedium: base.textTheme.displayMedium!.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.textTheme.headlineMedium!.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall!.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium!.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge!.copyWith(
        fontSize: 16,
        height: 1.35,
      ),
      bodyMedium: base.textTheme.bodyMedium!.copyWith(
        fontSize: 14.5,
        height: 1.35,
      ),
      bodySmall: base.textTheme.bodySmall!.copyWith(
        fontSize: 13,
        color: kMutedTextColor,
      ),
      labelLarge: base.textTheme.labelLarge!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.textTheme.labelMedium!.copyWith(fontSize: 14),
    ),
    // 输入框统一使用深色文字，避免在任何主题下出现白字白底。
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: base.textTheme.bodyLarge!.copyWith(color: kMutedTextColor),
      floatingLabelStyle: base.textTheme.bodyLarge!.copyWith(
        color: kPrimaryColor,
      ),
      hintStyle: base.textTheme.bodyLarge!.copyWith(color: kMutedTextColor),
      helperStyle: base.textTheme.bodySmall!.copyWith(color: kMutedTextColor),
      errorStyle: base.textTheme.bodySmall!.copyWith(color: kDangerColor),
      border: const OutlineInputBorder(),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kTextColor,
      elevation: 0,
    ),
  );
}
