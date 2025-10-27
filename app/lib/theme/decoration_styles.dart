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

  /// Surface container decoration (surface background with border)
  static BoxDecoration surfaceContainer() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }

  /// Error container decoration (red tinted background with red border)
  static BoxDecoration errorContainer() {
    return BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.5)),
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
}
