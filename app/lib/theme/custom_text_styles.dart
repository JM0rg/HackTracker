import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom text styles extension for HackTracker-specific styling
@immutable
class CustomTextStyles extends ThemeExtension<CustomTextStyles> {
  const CustomTextStyles({
    required this.toggleButtonLabel,
    required this.statusIndicator,
    required this.appBarTitle,
    required this.sectionHeader,
    required this.errorMessage,
  });

  final TextStyle toggleButtonLabel;
  final TextStyle statusIndicator;
  final TextStyle appBarTitle;
  final TextStyle sectionHeader;
  final TextStyle errorMessage;

  /// Dark theme custom text styles
  static const CustomTextStyles dark = CustomTextStyles(
    toggleButtonLabel: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: 1.5,
    ),
    statusIndicator: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: AppColors.primary,
      letterSpacing: 2,
    ),
    appBarTitle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
      letterSpacing: 2,
    ),
    sectionHeader: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: 1.5,
    ),
    errorMessage: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.red,
      letterSpacing: 0.5,
    ),
  );

  @override
  CustomTextStyles copyWith({
    TextStyle? toggleButtonLabel,
    TextStyle? statusIndicator,
    TextStyle? appBarTitle,
    TextStyle? sectionHeader,
    TextStyle? errorMessage,
  }) {
    return CustomTextStyles(
      toggleButtonLabel: toggleButtonLabel ?? this.toggleButtonLabel,
      statusIndicator: statusIndicator ?? this.statusIndicator,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      sectionHeader: sectionHeader ?? this.sectionHeader,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  CustomTextStyles lerp(ThemeExtension<CustomTextStyles>? other, double t) {
    if (other is! CustomTextStyles) {
      return this;
    }
    return CustomTextStyles(
      toggleButtonLabel: TextStyle.lerp(toggleButtonLabel, other.toggleButtonLabel, t)!,
      statusIndicator: TextStyle.lerp(statusIndicator, other.statusIndicator, t)!,
      appBarTitle: TextStyle.lerp(appBarTitle, other.appBarTitle, t)!,
      sectionHeader: TextStyle.lerp(sectionHeader, other.sectionHeader, t)!,
      errorMessage: TextStyle.lerp(errorMessage, other.errorMessage, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomTextStyles &&
          runtimeType == other.runtimeType &&
          toggleButtonLabel == other.toggleButtonLabel &&
          statusIndicator == other.statusIndicator &&
          appBarTitle == other.appBarTitle &&
          sectionHeader == other.sectionHeader &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      toggleButtonLabel.hashCode ^
      statusIndicator.hashCode ^
      appBarTitle.hashCode ^
      sectionHeader.hashCode ^
      errorMessage.hashCode;
}
