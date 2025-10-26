import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'form_dialog.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'CONFIRM',
    this.confirmColor = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: title,
      content: Text(
        message,
        style: GoogleFonts.tektur(color: AppColors.textPrimary),
      ),
      cancelLabel: 'CANCEL',
      confirmLabel: confirmLabel,
      isDestructive: confirmColor == AppColors.error,
      onConfirm: () => Navigator.pop(context, true),
    );
  }
}


