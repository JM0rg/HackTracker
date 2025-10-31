import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/player_providers.dart';

/// Lineup section that displays the lineup and action buttons
class LineupSection extends ConsumerWidget {
  final Game game;
  final Team team;
  final bool hasLineup;
  final bool showButtons;
  final VoidCallback onShowLineupDialog;
  final VoidCallback onStartGame;
  final VoidCallback onNavigateToScoring;

  const LineupSection({
    super.key,
    required this.game,
    required this.team,
    required this.hasLineup,
    required this.showButtons,
    required this.onShowLineupDialog,
    required this.onStartGame,
    required this.onNavigateToScoring,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(team.teamId));

    return rosterAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading roster: $e'),
      ),
      data: (players) {
        if (!hasLineup) {
          return _buildNoLineupView(context);
        }
        return _buildLineupList(context, players);
      },
    );
  }

  Widget _buildNoLineupView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LINEUP',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No lineup set',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          if (showButtons) ...[
            const SizedBox(height: 16),
            _buildActionButtons(context, hasLineup: false),
          ],
        ],
      ),
    );
  }

  Widget _buildLineupList(BuildContext context, List<Player> players) {
    // Build lineup map
    final lineupMap = <String, int>{};
    if (game.lineup != null) {
      for (final item in game.lineup!) {
        if (item is Map<String, dynamic>) {
          final playerId = item['playerId'] as String?;
          final battingOrder = item['battingOrder'] as int?;
          if (playerId != null && battingOrder != null) {
            lineupMap[playerId] = battingOrder;
          }
        }
      }
    }

    final sortedLineup = lineupMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LINEUP',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedLineup.map((entry) {
            final player = players.firstWhere(
              (p) => p.playerId == entry.key,
              orElse: () => throw StateError('Player ${entry.key} not found in roster'),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.value.toString(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.fullName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '#${player.displayNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (showButtons) ...[
            const SizedBox(height: 16),
            _buildActionButtons(context, hasLineup: true),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, {required bool hasLineup}) {
    return Row(
      children: [
        // SET LINEUP / EDIT LINEUP button
        Expanded(
          child: OutlinedButton(
            onPressed: onShowLineupDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(hasLineup ? 'EDIT LINEUP' : 'SET LINEUP'),
          ),
        ),
        const SizedBox(width: 12),
        // START GAME / VIEW GAME button
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              if (!hasLineup) {
                // No lineup set - show dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Lineup Required'),
                    content: const Text('You must set a lineup first'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else if (game.status == 'IN_PROGRESS') {
                // Game already in progress - just navigate
                onNavigateToScoring();
              } else if (hasLineup) {
                // Scheduled game with lineup - start it
                onStartGame();
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: (!hasLineup)
                  ? AppColors.textTertiary
                  : AppColors.primary,
              side: BorderSide(
                color: (!hasLineup)
                    ? AppColors.textTertiary
                    : AppColors.primary,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              game.status == 'IN_PROGRESS' ? 'VIEW GAME' : 'START GAME',
            ),
          ),
        ),
      ],
    );
  }
}


