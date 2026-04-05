import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTheme {
  static final ThemeData theme = ThemeData(
    scaffoldBackgroundColor: AppColors.pageBg,
    primaryColor: AppColors.primaryGold,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGold,
      secondary: AppColors.primaryGold,
      surface: AppColors.white,
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.cinzel(
        fontSize: 39,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryGold,
        letterSpacing: 2.1,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 31,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 20,
        color: AppColors.textDark,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textDark, size: 24),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.pageBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD3CBC0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.2),
      ),
      hintStyle: GoogleFonts.inter(fontSize: 20, color: Color(0xFFA39A8F)),
    ),
  );
}
