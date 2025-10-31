import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';

/// Calendar view placeholder for games
class GameCalendarView extends ConsumerWidget {
  final Team team;
  final AsyncValue<List<Game>> gamesAsync;

  const GameCalendarView({
    super.key,
    required this.team,
    required this.gamesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Calendar View',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}


