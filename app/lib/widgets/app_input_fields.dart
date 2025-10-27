import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable text input field with consistent styling
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<String>? autofillHints;
  final int? maxLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        counterText: maxLength != null ? null : '', // Hide counter if not needed
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofillHints: autofillHints,
      maxLines: maxLines,
      maxLength: maxLength,
      onTap: onTap,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

/// Reusable text form field with validation
class AppTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<String>? autofillHints;
  final int? maxLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;

  const AppTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        counterText: maxLength != null ? null : '', // Hide counter if not needed
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofillHints: autofillHints,
      maxLines: maxLines,
      maxLength: maxLength,
      onTap: onTap,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

/// Reusable dropdown form field with consistent styling
class AppDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? Function(T?)? validator;
  final bool enabled;

  const AppDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.labelText,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: labelText,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      dropdownColor: AppColors.surface,
      validator: validator,
    );
  }
}

/// Reusable password field with show/hide toggle
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<String>? autofillHints;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Widget? prefixIcon;

  const AppPasswordField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.autofocus = false,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.autofillHints,
    this.onTap,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      validator: widget.validator,
      obscureText: _obscureText,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      autofillHints: widget.autofillHints,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      prefixIcon: widget.prefixIcon,
      suffixIcon: IconButton(
        icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}

/// Reusable email field with email-specific keyboard and validation
class AppEmailField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<String>? autofillHints;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Widget? prefixIcon;

  const AppEmailField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.onTap,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      validator: validator,
      keyboardType: TextInputType.emailAddress,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofillHints: autofillHints ?? const [AutofillHints.email],
      onTap: onTap,
      onChanged: onChanged,
      enabled: enabled,
      prefixIcon: prefixIcon,
    );
  }
}
