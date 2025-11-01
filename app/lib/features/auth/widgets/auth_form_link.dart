import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/glass_theme.dart';

/// Reusable form link button for switching between auth forms
class AuthFormLink extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AuthFormLink({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: GlassTheme.primaryTextColor,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

