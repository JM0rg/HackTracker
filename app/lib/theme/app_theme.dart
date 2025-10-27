import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'custom_text_styles.dart';

/// Centralized theme configuration for HackTracker app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Dark theme (primary theme for the app)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.tekturTextTheme(ThemeData.dark().textTheme).copyWith(
        // Display styles
        displayLarge: GoogleFonts.tektur(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.tektur(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 2,
        ),
        displaySmall: GoogleFonts.tektur(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 2,
        ),
        // Headline styles
        headlineLarge: GoogleFonts.tektur(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.tektur(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        headlineSmall: GoogleFonts.tektur(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        // Title styles
        titleLarge: GoogleFonts.tektur(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        titleMedium: GoogleFonts.tektur(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
        titleSmall: GoogleFonts.tektur(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 1,
        ),
        // Body styles
        bodyLarge: GoogleFonts.tektur(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: GoogleFonts.tektur(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        bodySmall: GoogleFonts.tektur(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        // Label styles
        labelLarge: GoogleFonts.tektur(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        labelMedium: GoogleFonts.tektur(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 1,
        ),
        labelSmall: GoogleFonts.tektur(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: AppColors.textTertiary,
          letterSpacing: 1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.tektur(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.tektur(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      extensions: const [
        CustomTextStyles.dark,
      ],
    );
  }
}

