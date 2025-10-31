import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/decoration_styles.dart';

/// Player card for roster display with color-coded number
class RosterPlayerCard extends StatelessWidget {
  final Player player;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const RosterPlayerCard({
    super.key,
    required this.player,
    required this.canManage,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked = player.userId != null;
    final numberColor = isLinked ? AppColors.linkedUserColor : AppColors.guestUserColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: DecorationStyles.surfaceContainerSmall(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Player number with color coding
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: numberColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: numberColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              player.displayNumber,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: numberColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  player.displayRole,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Positions
          if (player.positions != null && player.positions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                player.positions!.join(', '),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 8),
          // Edit/Remove menu (owner only)
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textTertiary),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'remove') {
                  onRemove?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
        ],
      ),
    );
  }
}


