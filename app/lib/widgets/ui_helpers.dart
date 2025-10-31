import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/messenger.dart';

void showSuccess(BuildContext context, String message) {
  (messengerKey.currentState ?? ScaffoldMessenger.of(context)).showSnackBar(
    SnackBar(
      content: Text(message, style: Theme.of(context).textTheme.bodySmall),
      backgroundColor: AppColors.primary,
    ),
  );
}

void showError(BuildContext context, String message) {
  (messengerKey.currentState ?? ScaffoldMessenger.of(context)).showSnackBar(
    SnackBar(
      content: Text(message, style: Theme.of(context).textTheme.bodySmall),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Generic status badge with customizable color and text
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Game status badge with predefined colors
class GameStatusBadge extends StatelessWidget {
  final String status;

  const GameStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'SCHEDULED':
        color = AppColors.statusScheduled;
        label = 'SCHEDULED';
        break;
      case 'IN_PROGRESS':
        color = AppColors.statusInProgress;
        label = 'LIVE';
        break;
      case 'FINAL':
        color = AppColors.statusFinal;
        label = 'FINAL';
        break;
      case 'POSTPONED':
        color = AppColors.statusPostponed;
        label = 'POSTPONED';
        break;
      default:
        color = AppColors.textTertiary;
        label = status;
    }

    return StatusBadge(label: label, color: color);
  }
}

/// Section header with uppercase text and primary color
class SectionHeader extends StatelessWidget {
  final String text;
  final double? letterSpacing;

  const SectionHeader({
    super.key,
    required this.text,
    this.letterSpacing = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.primary,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

/// Reusable list item card with icon, title, trailing icon
class ListItemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ListItemCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelSmall,
              )
            : null,
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
        onTap: onTap,
      ),
    );
  }
}

/// Themed loading indicator
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(color: AppColors.primary);
  }
}


