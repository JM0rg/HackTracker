import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/glass_theme.dart';

/// Reusable divider with "OR" text for auth forms
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: GlassTheme.dividerColor,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        Expanded(
          child: Divider(
            color: GlassTheme.dividerColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

