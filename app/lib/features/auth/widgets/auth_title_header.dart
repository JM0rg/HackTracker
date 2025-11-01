import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/glass_theme.dart';
import 'glass_container.dart';

/// Reusable title header for auth screens
/// Displays HACKTRACKER logo and subtitle
class AuthTitleHeader extends StatelessWidget {
  const AuthTitleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          Text(
            'HACKTRACKER',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Slowpitch Stats Tracking',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: GlassTheme.secondaryTextColor,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

