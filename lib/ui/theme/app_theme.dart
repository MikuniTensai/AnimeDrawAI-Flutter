import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Purple Colors
  static const Color purple80 = Color(0xFFD0BCFF);
  static const Color purple60 = Color(0xFF9C7EFF);
  static const Color purple40 = Color(0xFF6650a4);
  static const Color purple20 = Color(0xFF4A3B7A);

  // Background Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF8F7FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Background Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF0D0D1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);

  // Accent Colors
  static const Color accentPurple = Color(0xFF7B68EE);
  static const Color accentPurpleDark = Color(0xFF9C7EFF);
  static const Color accentLavender = Color(0xFFE6E6FA);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textPrimaryDark = Color(0xFFE8E8E8);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningOrange = Color(0xFFFF9800);

  // Theme Color Palette (Harmonious with Purple)
  static const Color themePink = Color(0xFFFF4081);
  static const Color themeIndigo = Color(0xFF536DFE);
  static const Color themeBlue = Color(0xFF448AFF);
  static const Color themeCyan = Color(0xFF00BCD4);
  static const Color themeTeal = Color(0xFF1DE9B6);
  static const Color themeSunset = Color(0xFFFF5722);
}

class AppTheme {
  static ThemeData lightTheme(Color seedColor) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      primary: seedColor,
      surface: AppColors.backgroundLight,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme)
        .copyWith(
          bodyLarge: const TextStyle(color: AppColors.textPrimary),
          bodyMedium: const TextStyle(color: AppColors.textPrimary),
        ),
  );

  static ThemeData darkTheme(Color seedColor) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      primary: seedColor == const Color(0xFF6650a4)
          ? AppColors.purple60
          : seedColor,
      surface: AppColors.backgroundDark,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: const TextStyle(color: AppColors.textPrimaryDark),
      bodyMedium: const TextStyle(color: AppColors.textPrimaryDark),
    ),
  );
}
