import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../models/player.dart';
import '../../../models/game.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/player_providers.dart';
import '../state/game_state_provider.dart';
import '../state/game_state.dart';
import '../widgets/field_diagram.dart';
import '../widgets/action_area.dart';

/// Scoring Screen - Fast At-Bat Entry
/// 
/// Core Concept: Single, context-aware "state machine" screen to minimize clicks (1-3 taps per play)
/// 
/// UI Layout:
/// - Field Diagram (Top 70%): Stack with field image, invisible GestureDetector, and dynamic dot
/// - Action Area (Bottom 30%): Container rendering different rows of buttons based on current state
/// 
/// State Management: StatefulWidget managing an EntryStep enum (initial, outcome) and data for JSON payload
/// 
/// User Flows:
/// - Flow 1 (Non-Play, 1-Tap): From initial state, tap [Strikeout], [Walk], or [Hit By Pitch]
/// - Flow 2 (Hit in Play, 2-Tap "Fast Path"): Tap field → tap outcome ([1B], [2B], etc.)
/// - Flow 3 (Advanced Detail, 3+ Taps): Tap field → optional detail buttons → tap outcome
class ScoringScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String teamId;

  const ScoringScreen({
    super.key,
    required this.gameId,
    required this.teamId,
  });

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  // State machine
  EntryStep _step = EntryStep.initial;

  // At-bat data
  Map<String, double>? _hitLocation;
  String? _hitType;
  int? _finalBaseReached;
  String? _selectedResult; // Track selected result before submitting

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gamesProvider(widget.teamId));
    final playersAsync = ref.watch(rosterProvider(widget.teamId));
    final gameStateAsync = ref.watch(gameStateProvider(GameStateParams(
      gameId: widget.gameId,
      teamId: widget.teamId,
    )));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Score Game'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: gameAsync.when(
        data: (games) {
          final game = games.firstWhere(
            (g) => g.gameId == widget.gameId,
            orElse: () => throw Exception('Game not found'),
          );

          if (game.lineup == null || game.lineup!.isEmpty) {
            return _buildNoLineupView();
          }

          // Get game state from provider
          return gameStateAsync.when(
            data: (gameState) {
              final currentBatter = _getCurrentBatter(game.lineup!, gameState.currentBatterIndex);
              
              // Get player name from roster
              final players = playersAsync.hasValue ? playersAsync.value! : <Player>[];
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

              return Column(
                children: [
                  // Current batter and game state display
                  _buildGameStateHeader(player, gameState),
                  
                  // Spray Chart title and instructions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          'Spray Chart',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select hit location. Hold to clear.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Field Diagram
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.1, // Wider than tall to reduce vertical space
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 0),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FieldDiagram(
                              onTap: _handleFieldTap,
                              onLongPress: _clearHitLocation,
                              hitLocation: _hitLocation,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Action Area (fixed height)
                  SizedBox(
                    height: 220,
                    child: ActionArea(
                      step: _step,
                      hitType: _hitType,
                      finalBaseReached: _finalBaseReached,
                      selectedResult: _selectedResult,
                      onResultSelect: _handleResultSelect,
                      onHitTypeTap: _handleHitTypeTap,
                      onFinalBaseTap: _handleFinalBaseTap,
                      onSubmit: () => _saveAtBat(_selectedResult!, currentBatter),
                    ),
                  ),
                ],
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
                    'Failed to load game state',
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load game',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build game state header with current batter and inning/outs
  Widget _buildGameStateHeader(Player player, InGameState gameState) {
    // Build player name (first name + last name if available)
    final firstName = player.firstName;
    final lastName = (player.lastName?.isNotEmpty ?? false) ? player.lastName : null;
    final displayName = lastName != null ? '$firstName $lastName' : firstName;
    final number = player.playerNumber != null ? '#${player.playerNumber}' : '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textTertiary.withOpacity(0.2),
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

  /// Build no lineup view
  Widget _buildNoLineupView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Lineup Set',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please set a lineup before scoring.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Get current batter from lineup
  Map<String, dynamic> _getCurrentBatter(List<dynamic> lineup, int batterIndex) {
    // Sort lineup by batting order
    final sortedLineup = List<Map<String, dynamic>>.from(lineup)
      ..sort((a, b) => (a['battingOrder'] as int).compareTo(b['battingOrder'] as int));

    // Return current batter (cycling through lineup)
    return sortedLineup[batterIndex % sortedLineup.length];
  }

  /// Handle field tap
  void _handleFieldTap(double x, double y) {
    setState(() {
      _hitLocation = {'x': x, 'y': y};
      _step = EntryStep.outcome;
    });
  }

  /// Handle hit type tap
  void _handleHitTypeTap(String type) {
    setState(() {
      _hitType = _hitType == type ? null : type; // Toggle
    });
  }

  /// Handle final base tap
  void _handleFinalBaseTap(int base) {
    setState(() {
      _finalBaseReached = _finalBaseReached == base ? null : base; // Toggle
    });
  }

  /// Handle result selection
  void _handleResultSelect(String result) {
    setState(() {
      _selectedResult = result;
    });
  }

  /// Clear hit location and reset to initial state
  void _clearHitLocation() {
    setState(() {
      _step = EntryStep.initial;
      _hitLocation = null;
      _hitType = null;
      _finalBaseReached = null;
      _selectedResult = null;
    });
  }

  /// Save at-bat with optimistic UI updates
  /// 
  /// Uses the gameStateProvider which handles:
  /// 1. Optimistic updates to at-bat list
  /// 2. Automatic state recalculation from AtBats
  /// 3. Rollback on error
  Future<void> _saveAtBat(String result, Map<String, dynamic> batter) async {
    final playerId = batter['playerId'] as String;
    final battingOrder = batter['battingOrder'] as int;
    
    // Store at-bat data before resetting UI state
    final hitLocation = _hitLocation;
    final hitType = _hitType;
    
    // Reset UI state immediately (optimistic)
    _resetState();
    
    // Submit at-bat via provider (handles optimistic updates and rollback)
    final params = GameStateParams(
      gameId: widget.gameId,
      teamId: widget.teamId,
    );
    
    await ref.read(gameStateProvider(params).notifier).recordAtBat(
      playerId: playerId,
      result: result,
      battingOrder: battingOrder,
      hitLocation: hitLocation,
      hitType: hitType,
      rbis: null, // Could be calculated or entered
    );
    
    // State will automatically update via provider's listener
    // No need to manually advance - provider recalculates from AtBats
  }

  /// Reset state after recording at-bat
  void _resetState() {
    setState(() {
      _step = EntryStep.initial;
      _hitLocation = null;
      _hitType = null;
      _finalBaseReached = null;
      _selectedResult = null;
    });
  }
}

