import 'package:flutter/material.dart';

class AppColors {
  // Palette principale
  static const Color navyDark  = Color(0xFF243B42);
  static const Color lightBlue = Color(0xFFC5DEE6);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color offWhite  = Color(0xFFFAFAFA);
  static const Color black     = Color(0xFF0D0D0D);

  // Gradient
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, lightBlue],
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.offWhite,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navyDark,
      primary: AppColors.navyDark,
      secondary: AppColors.lightBlue,
      surface: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navyDark,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.navyDark, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.navyDark,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: AppColors.black),
    ),
  );
}
