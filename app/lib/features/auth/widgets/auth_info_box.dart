import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/glass_theme.dart';
import 'glass_container.dart';

/// Reusable info box for displaying informational messages in auth forms
class AuthInfoBox extends StatelessWidget {
  final String message;
  final IconData icon;

  const AuthInfoBox({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      blurSigma: 5,
      child: Row(
        children: [
          Icon(
            icon,
            color: GlassTheme.primaryIconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

