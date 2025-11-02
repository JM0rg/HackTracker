import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../models/atbat.dart';
import '../../../models/player.dart';
import '../../../providers/atbat_providers.dart';
import '../../../providers/player_providers.dart';
import '../state/game_state_provider.dart';
import 'scoring_flow_screen.dart';

/// Helper function to format inning as ordinal (1st, 2nd, 3rd, etc.)
String _getOrdinalInning(int inning) {
  final suffix = inning % 100;
  if (suffix >= 11 && suffix <= 13) {
    return '${inning}th Inning';
  }
  switch (inning % 10) {
    case 1:
      return '${inning}st Inning';
    case 2:
      return '${inning}nd Inning';
    case 3:
      return '${inning}rd Inning';
    default:
      return '${inning}th Inning';
  }
}

/// At-Bats List Screen
/// 
/// Displays all recorded at-bats for a game, grouped by inning in collapsible sections.
/// Each at-bat can be edited by tapping the Edit button.
class AtBatsListScreen extends ConsumerWidget {
  final String gameId;
  final String teamId;
  final bool hideAppBar;

  const AtBatsListScreen({
    super.key,
    required this.gameId,
    required this.teamId,
    this.hideAppBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atBatsAsync = ref.watch(atBatsProvider(gameId));
    final playersAsync = ref.watch(rosterProvider(teamId));
    final gameStateAsync = ref.watch(gameStateProvider(GameStateParams(
      gameId: gameId,
      teamId: teamId,
    )));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('At-Bats'),
              backgroundColor: AppColors.background,
              elevation: 0,
            ),
      body: atBatsAsync.when(
        data: (atBats) {
          if (atBats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_baseball,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No at-bats recorded yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start scoring to record at-bats',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group at-bats by inning
          final groupedByInning = <int, List<AtBat>>{};
          for (final atBat in atBats) {
            groupedByInning.putIfAbsent(atBat.inning, () => []).add(atBat);
          }

          // Sort innings
          final innings = groupedByInning.keys.toList()..sort();

          // Get current inning for default expansion
          final currentInning = gameStateAsync.maybeWhen(
            data: (state) => state.inning,
            orElse: () => innings.isNotEmpty ? innings.last : 1,
          );

          final players = playersAsync.hasValue ? playersAsync.value! : <Player>[];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: innings.length,
            itemBuilder: (context, index) {
              final inning = innings[index];
              final inningAtBats = groupedByInning[inning]!;
              
              // Sort at-bats within inning by creation time
              inningAtBats.sort((a, b) => a.createdAt.compareTo(b.createdAt));

              final isExpanded = inning == currentInning;

              return _InningSection(
                inning: inning,
                atBats: inningAtBats,
                players: players,
                isInitiallyExpanded: isExpanded,
                onEditAtBat: (atBat) async {
                  // Navigate to scoring flow screen in edit mode
                  // The wrapper will show ScoringScreen first, then user can swipe to list
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScoringFlowScreen(
                        gameId: gameId,
                        teamId: teamId,
                        initialEditingAtBatId: atBat.atBatId,
                      ),
                    ),
                  );
                  // Refresh the list when returning from edit (provider auto-updates, but ensure UI refresh)
                  if (context.mounted) {
                    ref.invalidate(atBatsProvider(gameId));
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load at-bats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inning section with collapsible at-bats list
class _InningSection extends StatefulWidget {
  final int inning;
  final List<AtBat> atBats;
  final List<Player> players;
  final bool isInitiallyExpanded;
  final void Function(AtBat) onEditAtBat;

  const _InningSection({
    required this.inning,
    required this.atBats,
    required this.players,
    required this.isInitiallyExpanded,
    required this.onEditAtBat,
  });

  @override
  State<_InningSection> createState() => _InningSectionState();
}

class _InningSectionState extends State<_InningSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: widget.isInitiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Row(
          children: [
            Text(
              _getOrdinalInning(widget.inning),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.atBats.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          ...widget.atBats.map((atBat) => _AtBatListItem(
            atBat: atBat,
            players: widget.players,
            onEdit: () => widget.onEditAtBat(atBat),
          )),
        ],
      ),
    );
  }
}

/// Individual at-bat list item
class _AtBatListItem extends StatelessWidget {
  final AtBat atBat;
  final List<Player> players;
  final VoidCallback onEdit;

  const _AtBatListItem({
    required this.atBat,
    required this.players,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Find player
    final player = players.firstWhere(
      (p) => p.playerId == atBat.playerId,
      orElse: () => Player(
        playerId: atBat.playerId,
        teamId: atBat.teamId,
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

    // Build player name (first name only, no number)
    final firstName = player.firstName;
    
    // Build lineup order (battingOrder from at-bat)
    final battingOrder = atBat.battingOrder ?? 0;
    
    // Build result string
    // For hits: "Hit, {result}, {RBIs}" (e.g., "Hit, 3B, 1RBI")
    // For non-hits: just the result code (e.g., "K", "Out")
    String resultText;
    if (atBat.isHit) {
      final parts = <String>['Hit', atBat.result];
      if (atBat.rbis != null && atBat.rbis! > 0) {
        parts.add('${atBat.rbis}RBI');
      }
      resultText = parts.join(', ');
    } else {
      resultText = atBat.result;
    }
    
    // Build the single-line display: "{battingOrder}. {firstName} - {result}"
    final displayText = '$battingOrder. $firstName - $resultText';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.accent, size: 20),
            onPressed: onEdit,
            tooltip: 'Edit at-bat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

