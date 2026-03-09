import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide color constants matching the provided palette.
class AppColors {
  AppColors._();

  static const Color navyDark  = Color(0xFF243B42);
  static const Color lightBlue = Color(0xFFC5DEE6);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color offWhite  = Color(0xFFFAFAFA);
  static const Color black     = Color(0xFF0D0D0D);

  /// 135° gradient from navy to light-blue.
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, lightBlue],
  );
}

/// Reusable gradient decoration for backgrounds.
const BoxDecoration gradientBackground = BoxDecoration(
  gradient: AppColors.gradient,
);

/// The application [ThemeData].
ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.offWhite,

    // ── Color Scheme ───────────────────────────────────
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navyDark,
      primary: AppColors.navyDark,
      secondary: AppColors.lightBlue,
      surface: AppColors.white,
      onPrimary: AppColors.white,
      onSecondary: AppColors.navyDark,
      onSurface: AppColors.black,
      brightness: Brightness.light,
    ),

    // ── Typography ─────────────────────────────────────
    textTheme: baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: AppColors.navyDark,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: AppColors.navyDark,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: AppColors.navyDark,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.black,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.black,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),

    // ── AppBar ─────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.navyDark,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    ),

    // ── Cards ──────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shadowColor: AppColors.navyDark.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // ── Elevated Buttons ───────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Outlined Buttons ───────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navyDark,
        side: const BorderSide(color: AppColors.navyDark, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // ── Input Fields ───────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.navyDark.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.navyDark.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navyDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.navyDark),
      hintStyle: GoogleFonts.inter(
          color: AppColors.navyDark.withValues(alpha: 0.5)),
    ),

    // ── Floating Action Button ─────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.navyDark,
      foregroundColor: AppColors.white,
      elevation: 4,
    ),

    // ── Chips ──────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightBlue.withValues(alpha: 0.3),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    ),

    // ── Bottom Navigation ──────────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.navyDark,
      unselectedItemColor: AppColors.navyDark.withValues(alpha: 0.4),
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // ── Divider ────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: AppColors.navyDark.withValues(alpha: 0.1),
      thickness: 1,
    ),
  );
}
