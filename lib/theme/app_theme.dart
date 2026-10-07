import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF121510);
  static const surface = Color(0xFF1C2218);
  static const team = Color(0xFF262D21);
  static const text = Color(0xFFE7EEDF);
  static const muted = Color(0xFF8F9A86);
  static const line = Color(0xFF343B2E);
  static const accent = Color(0xFFD6F25C);
  static const onAccent = Color(0xFF1A2208);
  static const win = Color(0xFF1F7A45);
  static const loss = Color(0xFF9D341F);
}

const String kDisplayFont = 'BarlowCondensed';
const String kBodyFont = 'SourceSans3';

ThemeData buildAppTheme() {
  const textTheme = TextTheme(
    bodyLarge: TextStyle(
      fontFamily: kBodyFont,
      fontSize: 16,
      height: 1.35,
      color: AppColors.text,
    ),
    bodyMedium: TextStyle(
      fontFamily: kBodyFont,
      fontSize: 15,
      height: 1.35,
      color: AppColors.text,
    ),
    bodySmall: TextStyle(
      fontFamily: kBodyFont,
      fontSize: 13,
      height: 1.3,
      color: AppColors.muted,
    ),
    labelSmall: TextStyle(
      fontFamily: kBodyFont,
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.4,
      color: AppColors.muted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: kBodyFont,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      onSurface: AppColors.text,
    ),
    textTheme: textTheme,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      titleTextStyle: TextStyle(
        fontFamily: kDisplayFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      contentTextStyle: TextStyle(
        fontFamily: kBodyFont,
        fontSize: 16,
        height: 1.35,
        color: AppColors.text,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(
        fontFamily: kBodyFont,
        fontSize: 15,
        color: AppColors.text,
      ),
    ),
  );
}

TextStyle displayStyle({
  double size = 20,
  FontWeight weight = FontWeight.w600,
  Color color = AppColors.text,
  double height = 1,
}) {
  return TextStyle(
    fontFamily: kDisplayFont,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

TextStyle labelStyle({Color color = AppColors.muted, double size = 11}) {
  return TextStyle(
    fontFamily: kBodyFont,
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: color,
    height: 1.2,
  );
}
