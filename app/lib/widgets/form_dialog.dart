import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable form dialog with consistent styling and sizing
class FormDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? cancelLabel;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final bool isDestructive;
  final bool isLoading;

  const FormDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelLabel,
    required this.confirmLabel,
    this.onConfirm,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive width calculation
    double dialogWidth;
    if (screenWidth < 600) {
      // Mobile: Use most of screen width with small margins
      dialogWidth = screenWidth * 0.9;
    } else if (screenWidth < 1200) {
      // Tablet: Use 60% of screen width
      dialogWidth = screenWidth * 0.6;
    } else {
      // Desktop: Use 40% of screen width, but cap at reasonable maximum
      dialogWidth = (screenWidth * 0.4).clamp(400.0, 600.0);
    }
    
    return Dialog(
      backgroundColor: AppColors.surface,
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDestructive ? AppColors.error : AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Content
              Flexible(child: content),
              const SizedBox(height: 24),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelLabel != null)
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context, false),
                      child: Text(cancelLabel!),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
                      foregroundColor: Colors.black,
                      // Fix button sizing - match TextButton height
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      textStyle: Theme.of(context).textTheme.labelLarge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
