import 'package:flutter/material.dart';
import '../../../theme/custom_text_styles.dart';
import 'glass_container.dart';

/// Reusable error message display for auth forms
class AuthErrorMessage extends StatelessWidget {
  final String message;

  const AuthErrorMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      blurSigma: 5,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.withValues(alpha: 0.9),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .extension<CustomTextStyles>()!
                  .errorMessage
                  .copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

