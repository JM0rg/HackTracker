import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/player_providers.dart';
import '../state/game_state_provider.dart';
import '../state/game_state.dart';
import '../../../models/player.dart';
import 'scoring_screen.dart';
import 'atbats_list_screen.dart';

/// Scoring Flow Screen
/// 
/// Main scoring screen with AppBar controls for navigation.
/// Game state (Inning/Outs) shown in AppBar title; "Up to Bat" shown in header.
/// List icon in AppBar pushes AtBatsListScreen for viewing/editing at-bats.
class ScoringFlowScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String teamId;
  final String? initialEditingAtBatId;
  final VoidCallback? onBack;

  const ScoringFlowScreen({
    super.key,
    required this.gameId,
    required this.teamId,
    this.initialEditingAtBatId,
    this.onBack,
  });

  @override
  ConsumerState<ScoringFlowScreen> createState() => _ScoringFlowScreenState();
}

class _ScoringFlowScreenState extends ConsumerState<ScoringFlowScreen> {

  @override
  Widget build(BuildContext context) {
    // Watch game state and roster for the header
    final gameStateAsync = ref.watch(gameStateProvider(GameStateParams(
      gameId: widget.gameId,
      teamId: widget.teamId,
    )));
    final rosterAsync = ref.watch(rosterProvider(widget.teamId));
    final gamesAsync = ref.watch(gamesProvider(widget.teamId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        actions: [
          // List icon - navigate to at-bats list
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AtBatsListScreen(
                    gameId: widget.gameId,
                    teamId: widget.teamId,
                  ),
                ),
              );
            },
            tooltip: 'View At-Bats',
            color: AppColors.textPrimary,
          ),
          // Finish Game button - only show if game is IN_PROGRESS
          gamesAsync.when(
            data: (games) {
              final game = games.firstWhere(
                (g) => g.gameId == widget.gameId,
                orElse: () => throw Exception('Game not found'),
              );
              if (game.status == 'IN_PROGRESS') {
                return TextButton(
                  onPressed: () => _finishGame(context, ref),
                  child: const Text(
                    'Finish Game',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // "Up to Bat" header - always visible
            gameStateAsync.when(
              data: (gameState) {
                return rosterAsync.when(
                  data: (players) {
                    return gamesAsync.when(
                      data: (games) {
                        final game = games.firstWhere(
                          (g) => g.gameId == widget.gameId,
                          orElse: () => throw Exception('Game not found'),
                        );
                        
                        if (game.lineup == null || game.lineup!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        // Get current batter
                        // Convert lineup to Map if it's a List
                        final lineupList = game.lineup!;
                        final lineupMap = lineupList is Map<String, dynamic>
                            ? lineupList as Map<String, dynamic>
                            : Map<String, dynamic>.fromEntries(
                                (lineupList).asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final item = entry.value;
                                  return MapEntry(
                                    (i + 1).toString(),
                                    item is Map<String, dynamic>
                                        ? item['playerId'] as String
                                        : item.toString(),
                                  );
                                }),
                              );
                        final currentBatter = _getCurrentBatter(lineupMap, gameState.currentBatterIndex);
                        final player = players.firstWhere(
                          (p) => p.playerId == currentBatter['playerId'],
                          orElse: () => Player(
                            playerId: currentBatter['playerId'],
                            teamId: widget.teamId,
                            firstName: 'Unknown',
                            lastName: 'Player',
                            playerNumber: null,
                            positions: [],
                            status: 'active',
                            isGhost: true,
                            userId: null,
                            linkedAt: null,
                            createdAt: DateTime.now().toIso8601String(),
                            updatedAt: DateTime.now().toIso8601String(),
                          ),
                        );
                        
                        return _buildUpToBatHeader(player, gameState);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Scoring screen content
            Expanded(
              child: ScoringScreen(
                gameId: widget.gameId,
                teamId: widget.teamId,
                editingAtBatId: widget.initialEditingAtBatId,
                returnToListOnSubmit: false, // Don't auto-navigate
                hideAppBar: true, // Hide AppBar since we're in a wrapper
                hideGameStateHeader: true, // Hide header since we show it here
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get current batter info from lineup
  Map<String, dynamic> _getCurrentBatter(Map<String, dynamic> lineup, int batterIndex) {
    final battingOrder = (batterIndex % lineup.length) + 1;
    final playerId = lineup[battingOrder.toString()];
    
    return {
      'playerId': playerId,
      'battingOrder': battingOrder,
    };
  }

  /// Build game state header with inning/outs and "Up to Bat" info
  Widget _buildUpToBatHeader(Player player, InGameState gameState) {
    // Build player name (first name + last name if available)
    final firstName = player.firstName;
    final lastName = (player.lastName?.isNotEmpty ?? false) ? player.lastName : null;
    final displayName = lastName != null ? '$firstName $lastName' : firstName;
    final number = player.playerNumber != null ? '#${player.playerNumber}' : '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Inning and outs (bigger)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Inning ${gameState.inning}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' • ',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                '${gameState.outs} Out${gameState.outs != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Current batter (horizontal layout)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Up to Bat: ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Flexible(
                child: Text(
                  number.isNotEmpty ? '$displayName $number' : displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Finish game by updating status to FINAL and closing modal
  Future<void> _finishGame(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(gamesProvider(widget.teamId).notifier).updateGame(
        gameId: widget.gameId,
        status: 'FINAL',
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error toast is handled by the provider
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to finish game: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

