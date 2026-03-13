import 'package:flutter/material.dart';

class AppColors {
  // Palette principale - Bleu ciel et bleu marine (Actuelle)
  static const Color navyDark  = Color(0xFF243B42);
  static const Color lightBlue = Color(0xFFC5DEE6);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color offWhite  = Color(0xFFFAFAFA);
  static const Color black     = Color(0xFF0D0D0D);

  // Palette Teal & Orange (Pour doctor_details et autres pages spécifiques)
  static const Color tealDark      = Color(0xFF1B4A4A);
  static const Color tealMedium    = Color(0xFF2C6B6B);
  static const Color orangeAccent  = Color(0xFFF5A623);
  static const Color cream         = Color(0xFFFFF8F0);
  static const Color beigePeach    = Color(0xFFF0E6D3);
  static const Color textBlack     = Color(0xFF1A1A1A);
  static const Color textGray      = Color(0xFF6B6B6B);
  static const Color beigeGray     = Color(0xFFE8DDD0);
  static const Color inactiveGray  = Color(0xFF9B9B9B);

  // Gradients
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, lightBlue],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealDark, tealMedium],
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
