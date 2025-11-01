import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'glass_container.dart';
import 'glass_button.dart';

/// Reusable success dialog for auth operations
class AuthSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOkPressed;

  const AuthSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      borderRadius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            text: 'OK',
            onPressed: onOkPressed ?? () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Show the success dialog
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOkPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => AuthSuccessDialog(
        title: title,
        message: message,
        onOkPressed: onOkPressed,
      ),
    );
  }
}

