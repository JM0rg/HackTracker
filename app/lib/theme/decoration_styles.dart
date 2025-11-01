import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Common BoxDecoration patterns used throughout the app
class DecorationStyles {
  DecorationStyles._(); // Private constructor

  /// Primary border decoration (2px primary color border, 12px radius)
  static BoxDecoration primaryBorder() {
    return BoxDecoration(
      border: Border.all(color: AppColors.primary, width: 2),
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Surface container decoration (surface background with border, 12px radius)
  static BoxDecoration surfaceContainer() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }

  /// Surface container decoration with smaller radius (8px)
  static BoxDecoration surfaceContainerSmall() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    );
  }

  /// Error container decoration (red tinted background with red border)
  static BoxDecoration errorContainer() {
    return BoxDecoration(
      color: Colors.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
    );
  }

  /// Status container decoration (surface background with bottom border only)
  static BoxDecoration statusContainer() {
    return const BoxDecoration(
      color: AppColors.surface,
      border: Border(
        bottom: BorderSide(color: AppColors.border, width: 1),
      ),
    );
  }

  /// Card decoration (standard card with surface color and border)
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }

  /// Info box decoration (surface background with border, smaller radius)
  static BoxDecoration infoBox() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }

  /// Password requirements box decoration
  static BoxDecoration passwordRequirements() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }

  /// Glassmorphism container decoration (iOS liquid glass effect)
  /// Use with BackdropFilter for full frosted glass effect
  static BoxDecoration glassContainer({
    double borderRadius = 24.0,
    Color? borderColor,
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.primary.withValues(alpha: 0.3),
        width: borderWidth,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surface.withValues(alpha: 0.7),
          AppColors.surface.withValues(alpha: 0.5),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }

  /// Glassmorphism button decoration (for elevated buttons)
  static BoxDecoration glassButton({bool isEnabled = true}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isEnabled
            ? [
                AppColors.primary.withValues(alpha: 0.9),
                AppColors.secondary.withValues(alpha: 0.9),
              ]
            : [
                AppColors.border.withValues(alpha: 0.3),
                AppColors.border.withValues(alpha: 0.3),
              ],
      ),
      boxShadow: isEnabled
          ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ]
          : [],
    );
  }

  /// Glassmorphism input field decoration
  static InputDecoration glassInputDecoration({
    required String labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.8),
        letterSpacing: 1.2,
      ),
      floatingLabelStyle: TextStyle(
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
