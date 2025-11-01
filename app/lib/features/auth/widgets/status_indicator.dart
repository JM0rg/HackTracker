import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/custom_text_styles.dart';
import '../../../theme/glass_theme.dart';

/// Status indicator with glowing dot and text (used in auth screens)
class StatusIndicator extends StatelessWidget {
  final String text;
  final double? dotSize;

  const StatusIndicator({
    super.key,
    required this.text,
    this.dotSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: dotSize ?? GlassTheme.statusDotSize,
          height: dotSize ?? GlassTheme.statusDotSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.6),
                blurRadius: GlassTheme.statusDotBlur,
                spreadRadius: GlassTheme.statusDotSpread,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context)
              .extension<CustomTextStyles>()!
              .statusIndicator
              .copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

