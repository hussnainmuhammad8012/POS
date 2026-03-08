import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ========== STAR ADMIN THEME (MATCHING DESKTOP) ==========
  static const Color STAR_PRIMARY = Color(0xFFF29F67); // Coral/Orange
  static const Color STAR_SIDEBAR = Color(0xFF1E1E2C); // Deep Navy
  static const Color STAR_BACKGROUND = Color(0xFFF3F3F9);
  static const Color STAR_CARD = Color(0xFFFFFFFF);
  
  static const Color STAR_BLUE = Color(0xFF3B8FF3);
  static const Color STAR_TEAL = Color(0xFF34B1AA);
  static const Color STAR_YELLOW = Color(0xFFE0B50F);
  
  static const Color STAR_TEXT_PRIMARY = Color(0xFF212529);
  static const Color STAR_TEXT_SECONDARY = Color(0xFF878A99);
  static const Color STAR_BORDER = Color(0xFFE9EBEC);

  static const Color DANGER = Color(0xFFDC2626);
  static const Color SUCCESS = Color(0xFF10B981);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
}

class AppTheme {
  static ThemeData get starAdminTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.STAR_PRIMARY,
    scaffoldBackgroundColor: AppColors.STAR_BACKGROUND,
    colorScheme: ColorScheme.light(
      primary: AppColors.STAR_PRIMARY,
      secondary: AppColors.STAR_TEXT_SECONDARY,
      surface: AppColors.STAR_CARD,
      background: AppColors.STAR_BACKGROUND,
      error: AppColors.DANGER,
      onPrimary: Colors.white,
      onSurface: AppColors.STAR_TEXT_PRIMARY,
      onBackground: AppColors.STAR_TEXT_PRIMARY,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.STAR_BACKGROUND,
      foregroundColor: AppColors.STAR_TEXT_PRIMARY,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.STAR_TEXT_PRIMARY,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.STAR_TEXT_PRIMARY),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.STAR_TEXT_PRIMARY),
      bodyLarge: GoogleFonts.inter(color: AppColors.STAR_TEXT_PRIMARY),
      bodyMedium: GoogleFonts.inter(color: AppColors.STAR_TEXT_PRIMARY),
      bodySmall: GoogleFonts.inter(color: AppColors.STAR_TEXT_SECONDARY),
    ),
    cardTheme: CardThemeData(
      color: AppColors.STAR_CARD,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.STAR_BORDER),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.STAR_CARD,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.STAR_BORDER),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.STAR_BORDER),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.STAR_PRIMARY, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.STAR_TEXT_SECONDARY),
      hintStyle: GoogleFonts.inter(color: AppColors.STAR_TEXT_SECONDARY.withOpacity(0.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.STAR_PRIMARY,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
