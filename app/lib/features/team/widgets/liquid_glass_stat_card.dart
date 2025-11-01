import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/decoration_styles.dart';
import '../../../theme/custom_text_styles.dart';

/// Liquid glass stat card - iOS-inspired glass morphism design
class LiquidGlassStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  const LiquidGlassStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: DecorationStyles.liquidGlass(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: accent,
                        size: 20,
                      ),
                    ),
                  ] else
                    const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liquid glass stat row - Horizontal stat display with multiple values
class LiquidGlassStatRow extends StatelessWidget {
  final String label;
  final List<StatItem> items;

  const LiquidGlassStatRow({
    super.key,
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: DecorationStyles.liquidGlass(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .extension<CustomTextStyles>()
                    ?.sectionHeader
                    .copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items
                    .map((item) => Expanded(
                          child: _StatItemWidget(
                            label: item.label,
                            value: item.value,
                            accentColor: item.accentColor,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual stat item widget
class _StatItemWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;

  const _StatItemWidget({
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;

    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Stat item data model
class StatItem {
  final String label;
  final String value;
  final Color? accentColor;

  const StatItem({
    required this.label,
    required this.value,
    this.accentColor,
  });
}

