import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/messenger.dart';

void showSuccess(BuildContext context, String message) {
  (messengerKey.currentState ?? ScaffoldMessenger.of(context)).showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.tektur(fontSize: 12)),
      backgroundColor: AppColors.primary,
    ),
  );
}

void showError(BuildContext context, String message) {
  (messengerKey.currentState ?? ScaffoldMessenger.of(context)).showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.tektur(fontSize: 12)),
      backgroundColor: AppColors.error,
    ),
  );
}

Future<void> showLoadingDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.tektur(
          fontSize: 10,
          color: active ? Colors.black : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PlayerNumberAvatar extends StatelessWidget {
  final String text;
  const PlayerNumberAvatar({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.tektur(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


