import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/custom_text_styles.dart';

/// Custom toggle button for switching between options
class ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ToggleButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).extension<CustomTextStyles>()!.toggleButtonLabel.copyWith(
              color: isSelected ? Colors.black : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
