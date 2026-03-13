import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Palette principale - Teal & Orange
  static const Color tealDark      = Color(0xFF1B4A4A); // Header, dark cards
  static const Color tealMedium    = Color(0xFF2C6B6B); // Secondary dark
  static const Color orangeAccent  = Color(0xFFF5A623); // Buttons, markers, "+"
  static const Color cream         = Color(0xFFFFF8F0); // Backgrounds
  static const Color white         = Color(0xFFFFFFFF); // Cards, pure backgrounds
  
  // Couleurs secondaires
  static const Color beigePeach    = Color(0xFFF0E6D3); // Secondary cards
  static const Color textBlack     = Color(0xFF1A1A1A); // Main text
  static const Color textGray      = Color(0xFF6B6B6B); // Secondary text
  static const Color beigeGray     = Color(0xFFE8DDD0); // Small cards/tags
  static const Color inactiveGray  = Color(0xFF9B9B9B); // Inactive icons
  
  static const Color errorRed      = Color(0xFFD32F2F);

  // Legacy Aliases (to fix compilation in other screens)
  static const Color navyDark     = tealDark;
  static const Color lightBlue    = beigeGray;
  static const Color offWhite     = cream;
  static const Color black        = textBlack;

  static const LinearGradient gradient = tealGradient; // Legacy gradient alias
  
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealDark, tealMedium],
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.tealDark,
      primary: AppColors.tealDark,
      secondary: AppColors.orangeAccent,
      surface: AppColors.white,
      onSurface: AppColors.textBlack,
    ),
    
    // Config AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.tealDark,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    ),
    
    // Config Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orangeAccent,
        foregroundColor: AppColors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    
    // Config Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.beigeGray.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.orangeAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textGray),
      hintStyle: const TextStyle(color: AppColors.inactiveGray),
    ),
    
    // Typographie
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.playfairDisplay(
        color: AppColors.textBlack,
        fontWeight: FontWeight.w900,
        fontSize: 32,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        color: AppColors.tealDark,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.inter(
        color: AppColors.textBlack,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      bodyLarge: GoogleFonts.inter(color: AppColors.textBlack, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: AppColors.textGray, fontSize: 14),
      labelSmall: GoogleFonts.inter(color: AppColors.inactiveGray, fontSize: 12),
    ),
    
    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.orangeAccent,
      unselectedItemColor: AppColors.inactiveGray,
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
  );
}
