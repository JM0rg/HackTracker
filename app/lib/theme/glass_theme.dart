import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glassmorphism theme constants and utilities
/// Centralized styling for iOS liquid glass aesthetic
class GlassTheme {
  GlassTheme._(); // Private constructor

  /// Background gradient for auth screens
  static BoxDecoration get backgroundGradient => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0.95),
            AppColors.surface.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      );

  /// Default blur sigma for glass containers
  static const double defaultBlurSigma = 10.0;

  /// Default border radius for glass containers
  static const double defaultBorderRadius = 24.0;

  /// Default button border radius
  static const double defaultButtonRadius = 16.0;

  /// Default input field border radius
  static const double defaultInputRadius = 16.0;

  /// Status indicator dot size
  static const double statusDotSize = 8.0;

  /// Status indicator dot glow blur
  static const double statusDotBlur = 8.0;

  /// Status indicator dot glow spread
  static const double statusDotSpread = 1.5;

  /// Primary icon color with opacity for glass inputs
  static Color get primaryIconColor => AppColors.primary.withValues(alpha: 0.8);

  /// Primary text color with opacity for labels
  static Color get primaryTextColor => AppColors.primary.withValues(alpha: 0.9);

  /// Secondary text color with opacity
  static Color get secondaryTextColor => AppColors.textSecondary.withValues(alpha: 0.9);

  /// Border color with opacity for dividers
  static Color get dividerColor => AppColors.border.withValues(alpha: 0.3);
}

