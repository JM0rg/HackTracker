import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/decoration_styles.dart';
import '../../../theme/glass_theme.dart';

/// Reusable glass-styled text field for auth forms
class AuthGlassField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final TextCapitalization textCapitalization;

  const AuthGlassField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: DecorationStyles.glassInputDecoration(
        labelText: labelText,
        prefixIcon: Icon(
          icon,
          color: GlassTheme.primaryIconColor,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      textCapitalization: textCapitalization,
    );
  }
}

