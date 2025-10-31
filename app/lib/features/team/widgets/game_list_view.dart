import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/date_grouping.dart';
import 'game_card.dart';

/// Game list view with date-based grouping
class GameListView extends ConsumerWidget {
  final Team team;
  final AsyncValue<List<Game>> gamesAsync;

  const GameListView({
    super.key,
    required this.team,
    required this.gamesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return gamesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (games) {
        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_baseball, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  'No games scheduled',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to schedule your first game',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        final groupedGames = groupGamesByDateRange(games);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            for (var entry in groupedGames.entries) ...[
              if (entry != groupedGames.entries.first) const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...entry.value.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GameCard(game: game, team: team),
              )),
            ],
          ],
        );
      },
    );
  }
}


