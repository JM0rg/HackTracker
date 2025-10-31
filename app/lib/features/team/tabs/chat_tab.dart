import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';

/// Chat Tab - Placeholder for future chat feature
class ChatTab extends StatelessWidget {
  final Team team;

  const ChatTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Team Chat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon - coordinate with your team',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


