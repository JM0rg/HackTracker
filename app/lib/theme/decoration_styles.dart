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

  /// Liquid glass decoration - iOS-inspired frosted glass effect
  /// Uses semi-transparent background with blur
  static BoxDecoration liquidGlass() {
    return BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Liquid glass decoration with accent - Enhanced version with stronger glow
  static BoxDecoration liquidGlassAccent() {
    return BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.4),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.15),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 40,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
