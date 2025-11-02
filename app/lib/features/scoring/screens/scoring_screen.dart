import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../models/player.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/atbat_providers.dart';
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
  final String? editingAtBatId;
  final bool returnToListOnSubmit;
  final bool hideAppBar;
  final bool hideGameStateHeader;

  const ScoringScreen({
    super.key,
    required this.gameId,
    required this.teamId,
    this.editingAtBatId,
    this.returnToListOnSubmit = false,
    this.hideAppBar = false,
    this.hideGameStateHeader = false,
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
  void initState() {
    super.initState();
    // If editing an at-bat, load its data after the first frame
    if (widget.editingAtBatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAtBatForEditing(widget.editingAtBatId!);
      });
    }
  }

  /// Load at-bat data for editing
  void _loadAtBatForEditing(String atBatId) {
    final atBatsAsync = ref.read(atBatsProvider(widget.gameId));
    if (!atBatsAsync.hasValue) return;
    
    final atBat = atBatsAsync.value!.firstWhere(
      (ab) => ab.atBatId == atBatId,
      orElse: () => throw StateError('At-bat not found: $atBatId'),
    );
    
    setState(() {
      _selectedResult = atBat.result;
      _hitLocation = atBat.hitLocation;
      _hitType = atBat.hitType;
      _step = atBat.hitLocation != null ? EntryStep.outcome : EntryStep.initial;
    });
  }

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
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(widget.editingAtBatId != null ? 'Edit At-Bat' : 'Score Game'),
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
              final players = playersAsync.hasValue ? playersAsync.value! : <Player>[];
              
              // If editing, get the player from the at-bat being edited
              Player? editingPlayer;
              int? editingBattingOrder;
              if (widget.editingAtBatId != null) {
                final atBatsAsync = ref.read(atBatsProvider(widget.gameId));
                if (atBatsAsync.hasValue) {
                  final atBat = atBatsAsync.value!.firstWhere(
                    (ab) => ab.atBatId == widget.editingAtBatId,
                    orElse: () => throw StateError('At-bat not found'),
                  );
                  editingPlayer = players.firstWhere(
                    (p) => p.playerId == atBat.playerId,
                    orElse: () => Player(
                      playerId: atBat.playerId,
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
                  editingBattingOrder = atBat.battingOrder;
                }
              }
              
              // Get current batter (for new entries) or editing batter info
              // Convert lineup to Map if it's a List
              final lineupList = game.lineup ?? [];
              final lineupMap = lineupList is Map<String, dynamic>
                  ? lineupList as Map<String, dynamic>
                  : Map<String, dynamic>.fromEntries(
                      (lineupList as List).asMap().entries.map((entry) {
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
              final currentBatter = widget.editingAtBatId != null && editingPlayer != null && editingBattingOrder != null
                  ? {'playerId': editingPlayer.playerId, 'battingOrder': editingBattingOrder!}
                  : _getCurrentBatter(lineupMap, gameState.currentBatterIndex);
              
              final player = editingPlayer ?? players.firstWhere(
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
                  // Current batter and game state display (only if not hidden by parent)
                  if (!widget.hideGameStateHeader)
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
                  
                  // Action Area (fixed height)
                  SizedBox(
                    height: 180,
                    child: ActionArea(
                      step: _step,
                      hitType: _hitType,
                      finalBaseReached: _finalBaseReached,
                      selectedResult: _selectedResult,
                      onResultSelect: (result) => _handleResultSelectAndSubmit(result, currentBatter),
                      onHitTypeTap: _handleHitTypeTap,
                      onFinalBaseTap: _handleFinalBaseTap,
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
  Map<String, dynamic> _getCurrentBatter(Map<String, dynamic> lineup, int batterIndex) {
    final battingOrder = (batterIndex % lineup.length) + 1;
    final playerId = lineup[battingOrder.toString()];
    
    return {
      'playerId': playerId,
      'battingOrder': battingOrder,
    };
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

  /// Handle result selection and immediately submit
  void _handleResultSelectAndSubmit(String result, Map<String, dynamic> batter) {
    // Set result and submit immediately
    setState(() {
      _selectedResult = result;
    });
    // Submit immediately - no need for separate submit button
    _saveAtBat(result, batter);
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
  /// 
  /// If widget.editingAtBatId is set, updates the existing at-bat instead of creating a new one.
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
    
    // Check if we're editing an existing at-bat
    if (widget.editingAtBatId != null) {
      // Update existing at-bat
      await ref.read(gameStateProvider(params).notifier).updateAtBatRecord(
        atBatId: widget.editingAtBatId!,
        result: result,
        hitLocation: hitLocation,
        hitType: hitType,
        rbis: null, // Could be calculated or entered
      );
      
      // If returnToListOnSubmit is true, navigate back to list
      if (widget.returnToListOnSubmit && mounted) {
        Navigator.pop(context, true);
        return;
      }
    } else {
      // Create new at-bat
      await ref.read(gameStateProvider(params).notifier).recordAtBat(
        playerId: playerId,
        result: result,
        battingOrder: battingOrder,
        hitLocation: hitLocation,
        hitType: hitType,
        rbis: null, // Could be calculated or entered
      );
      
      // For new at-bats, stay on scoring screen and advance to next batter
      // State will automatically update via provider's listener
    }
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

