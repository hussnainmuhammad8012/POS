import 'package:flutter/material.dart';

class AppColors {
  // ========== LIGHT MODE ==========
  static const Color LIGHT_BACKGROUND = Color(0xFFFFFFFF);
  static const Color LIGHT_SIDEBAR = Color(0xFFF8FAFC);
  static const Color LIGHT_SURFACE = Color(0xFFF8FAFC);
  static const Color LIGHT_CARD = Color(0xFFFFFFFF);
  static const Color LIGHT_PANEL = Color(0xFFF9FAFB);
  
  static const Color LIGHT_TEXT_PRIMARY = Color(0xFF1E293B);
  static const Color LIGHT_TEXT_SECONDARY = Color(0xFF64748B);
  static const Color LIGHT_TEXT_TERTIARY = Color(0xFF94A3B8);
  
  static const Color LIGHT_BORDER_PROMINENT = Color(0xFFE2E8F0);
  static const Color LIGHT_BORDER_SUBTLE = Color(0xFFF1F5F9);
  
  static const Color LIGHT_HOVER = Color(0xFFF1F5F9);
  static const Color LIGHT_FOCUS = Color(0xFFDBEAFE);
  static const Color LIGHT_ACTIVE = Color(0xFF3B82F6);
  static const Color LIGHT_DISABLED = Color(0xFFE2E8F0);

  // Soft Semantic Backgrounds for Light Mode
  static const Color LIGHT_INFO_SOFT = Color(0x1A0EA5E9);
  static const Color LIGHT_PRIMARY_SOFT = Color(0x1A3B82F6); // 10% opacity
  static const Color LIGHT_SUCCESS_SOFT = Color(0x1A10B981);
  static const Color LIGHT_WARNING_SOFT = Color(0x1AF59E0B);
  static const Color LIGHT_DANGER_SOFT = Color(0x1ADC2626);
  
  // ========== DARK MODE ==========
  static const Color DARK_BACKGROUND = Color(0xFF0F172A);
  static const Color DARK_SIDEBAR = Color(0xFF1E293B);
  static const Color DARK_SURFACE = Color(0xFF1E293B);
  static const Color DARK_CARD = Color(0xFF1E293B);
  static const Color DARK_PANEL = Color(0xFF334155);
  
  static const Color DARK_TEXT_PRIMARY = Color(0xFFF1F5F9);
  static const Color DARK_TEXT_SECONDARY = Color(0xFFCBD5E1);
  static const Color DARK_TEXT_TERTIARY = Color(0xFF94A3B8);
  
  static const Color DARK_BORDER_PROMINENT = Color(0xFF475569);
  static const Color DARK_BORDER_SUBTLE = Color(0xFF334155);
  
  static const Color DARK_HOVER = Color(0xFF334155);
  static const Color DARK_FOCUS = Color(0xFF3B82F6);
  static const Color DARK_ACTIVE = Color(0xFF60A5FA);
  static const Color DARK_DISABLED = Color(0xFF64748B);
  
  // ========== SHARED / SEMANTIC ==========
  static const Color PRIMARY_ACCENT_LIGHT = Color(0xFF3B82F6);
  static const Color PRIMARY_ACCENT_DARK = Color(0xFF60A5FA);
  static const Color SECONDARY_LIGHT = Color(0xFF64748B);
  static const Color SECONDARY_DARK = Color(0xFFCBD5E1);
  
  static const Color SUCCESS = Color(0xFF10B981);
  static const Color SUCCESS_DARK = Color(0xFF34D399);
  
  static const Color WARNING = Color(0xFFF59E0B);
  static const Color WARNING_DARK = Color(0xFFFBBF24);
  
  static const Color DANGER = Color(0xFFDC2626);
  static const Color DANGER_DARK = Color(0xFFF87171);
  
  static const Color INFO = Color(0xFF0EA5E9);
  static const Color INFO_DARK = Color(0xFF38BDF8);

  // ========== STAR ADMIN THEME (SYSTEM DEFAULT) ==========
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

  // Maintain generic names for backward compatibility
  static const primary = PRIMARY_ACCENT_LIGHT;
  static const secondary = SECONDARY_LIGHT;
  static const danger = DANGER;
  static const success = SUCCESS;
  static const warning = WARNING;
  static const info = INFO;
  static const background = LIGHT_BACKGROUND;
  static const surface = LIGHT_SURFACE;
  static const border = LIGHT_BORDER_PROMINENT;
  static const textPrimary = LIGHT_TEXT_PRIMARY;
  static const textMuted = LIGHT_TEXT_SECONDARY;
  static const darkBackground = DARK_BACKGROUND;
  static const darkSurface = DARK_SURFACE;
  static const darkBorder = DARK_BORDER_PROMINENT;
  static const darkText = DARK_TEXT_PRIMARY;
  static const darkTextMuted = DARK_TEXT_SECONDARY;
  static const dangerForeground = Colors.white;
  static const successForeground = Colors.white;
  static const warningForeground = Colors.white;
  static const infoForeground = Colors.white;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.PRIMARY_ACCENT_LIGHT,
    scaffoldBackgroundColor: AppColors.LIGHT_BACKGROUND,
    colorScheme: ColorScheme.light(
      primary: AppColors.PRIMARY_ACCENT_LIGHT,
      secondary: AppColors.SECONDARY_LIGHT,
      surface: AppColors.LIGHT_SURFACE,
      background: AppColors.LIGHT_BACKGROUND,
      error: AppColors.DANGER,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.LIGHT_TEXT_PRIMARY,
      onBackground: AppColors.LIGHT_TEXT_PRIMARY,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.LIGHT_BACKGROUND,
      foregroundColor: AppColors.LIGHT_TEXT_PRIMARY,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.LIGHT_TEXT_PRIMARY),
      displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.LIGHT_TEXT_PRIMARY),
      displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.LIGHT_TEXT_PRIMARY),
      headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.LIGHT_TEXT_PRIMARY),
      titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.LIGHT_TEXT_PRIMARY),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: AppColors.LIGHT_TEXT_PRIMARY),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: AppColors.LIGHT_TEXT_PRIMARY),
      bodySmall: TextStyle(fontFamily: 'Inter', color: AppColors.LIGHT_TEXT_SECONDARY),
    ),
    cardTheme: CardThemeData(
      color: AppColors.LIGHT_CARD,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.LIGHT_BORDER_PROMINENT),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.LIGHT_CARD,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.LIGHT_BORDER_PROMINENT),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.LIGHT_BORDER_PROMINENT),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.PRIMARY_ACCENT_LIGHT, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.PRIMARY_ACCENT_LIGHT,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.LIGHT_BORDER_SUBTLE,
      thickness: 1,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.PRIMARY_ACCENT_DARK,
    scaffoldBackgroundColor: AppColors.DARK_BACKGROUND,
    colorScheme: ColorScheme.dark(
      primary: AppColors.PRIMARY_ACCENT_DARK,
      secondary: AppColors.SECONDARY_DARK,
      surface: AppColors.DARK_SURFACE,
      background: AppColors.DARK_BACKGROUND,
      error: AppColors.DANGER_DARK,
      onPrimary: AppColors.DARK_BACKGROUND,
      onSecondary: AppColors.DARK_BACKGROUND,
      onSurface: AppColors.DARK_TEXT_PRIMARY,
      onBackground: AppColors.DARK_TEXT_PRIMARY,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.DARK_BACKGROUND,
      foregroundColor: AppColors.DARK_TEXT_PRIMARY,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.DARK_TEXT_PRIMARY),
      displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.DARK_TEXT_PRIMARY),
      displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.DARK_TEXT_PRIMARY),
      headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.DARK_TEXT_PRIMARY),
      titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.DARK_TEXT_PRIMARY),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: AppColors.DARK_TEXT_PRIMARY),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: AppColors.DARK_TEXT_PRIMARY),
      bodySmall: TextStyle(fontFamily: 'Inter', color: AppColors.DARK_TEXT_SECONDARY),
    ),
    cardTheme: CardThemeData(
      color: AppColors.DARK_CARD,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.DARK_BORDER_PROMINENT),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.DARK_BACKGROUND,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.DARK_BORDER_PROMINENT),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.DARK_BORDER_PROMINENT),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.PRIMARY_ACCENT_DARK, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.PRIMARY_ACCENT_DARK,
        foregroundColor: AppColors.DARK_BACKGROUND,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.DARK_BORDER_SUBTLE,
      thickness: 1,
    ),
  );

  static ThemeData get starAdminTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.STAR_PRIMARY,
    scaffoldBackgroundColor: AppColors.STAR_BACKGROUND,
    colorScheme: ColorScheme.light(
      primary: AppColors.STAR_PRIMARY,
      secondary: AppColors.STAR_TEXT_SECONDARY,
      surface: AppColors.STAR_BACKGROUND,
      background: AppColors.STAR_BACKGROUND,
      error: AppColors.DANGER,
      onPrimary: Colors.white,
      onSurface: AppColors.STAR_TEXT_PRIMARY,
      onBackground: AppColors.STAR_TEXT_PRIMARY,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.STAR_BACKGROUND,
      foregroundColor: AppColors.STAR_TEXT_PRIMARY,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.STAR_TEXT_PRIMARY),
      displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.STAR_TEXT_PRIMARY),
      displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.STAR_TEXT_PRIMARY),
      headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.STAR_TEXT_PRIMARY),
      titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.STAR_TEXT_PRIMARY),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: AppColors.STAR_TEXT_PRIMARY),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: AppColors.STAR_TEXT_PRIMARY),
      bodySmall: TextStyle(fontFamily: 'Inter', color: AppColors.STAR_TEXT_SECONDARY),
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
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.STAR_PRIMARY,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.STAR_BORDER,
      thickness: 1,
    ),
  );
}
