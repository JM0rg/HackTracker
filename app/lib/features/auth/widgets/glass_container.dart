import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/decoration_styles.dart';
import '../../../theme/glass_theme.dart';

/// Glassmorphism container widget with backdrop blur
/// Creates iOS liquid glass effect with frosted glass appearance
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = GlassTheme.defaultBorderRadius,
    this.blurSigma = GlassTheme.defaultBlurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: DecorationStyles.glassContainer(borderRadius: borderRadius),
          child: child,
        ),
      ),
    );
  }
}

