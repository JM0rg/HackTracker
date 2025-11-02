import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/atbat.dart';
import '../../../models/game.dart';
import '../../../providers/atbat_providers.dart';
import '../../../providers/game_providers.dart';
import 'game_state.dart';
import 'in_game_calculator.dart';

/// Parameters for game state provider
class GameStateParams {
  final String gameId;
  final String teamId;
  
  const GameStateParams({
    required this.gameId,
    required this.teamId,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameStateParams &&
        other.gameId == gameId &&
        other.teamId == teamId;
  }
  
  @override
  int get hashCode => Object.hash(gameId, teamId);
}

/// Provider for game state (inning, outs, current batter)
/// 
/// This provider derives the game state from the list of AtBats,
/// making it the single source of truth. It automatically recalculates
/// when the AtBats list changes.
/// 
/// The provider stays alive for 5 minutes after the last listener
/// to provide instant state when returning to the screen.
final gameStateProvider = AsyncNotifierProvider.family<GameStateNotifier, InGameState, GameStateParams>(
  (params) => GameStateNotifier(params),
);

class GameStateNotifier extends AsyncNotifier<InGameState> {
  GameStateNotifier(this._params);
  final GameStateParams _params;
  
  Timer? _keepAliveTimer;
  
  @override
  Future<InGameState> build() async {
    // Keep provider alive for 5 minutes after last listener
    final link = ref.keepAlive();
    ref.onCancel(() {
      _keepAliveTimer?.cancel();
      _keepAliveTimer = Timer(const Duration(minutes: 5), () {
        link.close();
      });
    });
    ref.onResume(() {
      _keepAliveTimer?.cancel();
      _keepAliveTimer = null;
    });
    
    // Clean up timer when provider is disposed
    ref.onDispose(() {
      _keepAliveTimer?.cancel();
    });
    
    // Watch for changes to at-bats list (will auto-recompute on changes)
    ref.listen<AsyncValue<List<AtBat>>>(
      atBatsProvider(_params.gameId),
      (previous, next) {
        // Recompute state when at-bats change
        if (next.hasValue && state.hasValue) {
          _recomputeState();
        }
      },
    );
    
    // Fetch initial state
    return await _computeCurrentState();
  }
  
  /// Compute current game state from AtBats and lineup
  Future<InGameState> _computeCurrentState() async {
    // Wait for at-bats and games to be available
    final atBatsAsync = ref.read(atBatsProvider(_params.gameId));
    final gamesAsync = ref.read(gamesProvider(_params.teamId));
    
    // Get at-bats list
    final atBats = await atBatsAsync.when(
      data: (data) => Future.value(data),
      loading: () => Future.value(<AtBat>[]),
      error: (_, __) => Future.value(<AtBat>[]),
    );
    
    // Get games list
    final games = await gamesAsync.when(
      data: (data) => Future.value(data),
      loading: () => Future.error(Exception('Games still loading')),
      error: (e, _) => Future.error(Exception('Failed to load games: $e')),
    );
    
    // Find the game
    final game = games.firstWhere(
      (g) => g.gameId == _params.gameId,
      orElse: () => throw Exception('Game not found'),
    );
    
    // Get lineup
    if (game.lineup == null || game.lineup!.isEmpty) {
      throw Exception('Game lineup not set');
    }
    
    // Compute and return state
    return InGameCalculator.compute(
      atBats: atBats,
      lineup: game.lineup!,
    );
  }
  
  /// Recompute state and update provider
  void _recomputeState() {
    if (state.isLoading) return; // Don't recompute while initializing
    
    _computeCurrentState().then(
      (newState) {
        state = AsyncValue.data(newState);
      },
      onError: (error, stackTrace) {
        // Keep previous state if recomputation fails
        // (this shouldn't happen, but be defensive)
      },
    );
  }
  
  /// Record a new at-bat with optimistic updates
  /// 
  /// This method delegates to the atBatsProvider which handles
  /// optimistic updates and rollback. The state will automatically
  /// recompute when the at-bat list changes.
  Future<AtBat?> recordAtBat({
    required String playerId,
    required String result,
    required int battingOrder,
    Map<String, double>? hitLocation,
    String? hitType,
    int? rbis,
  }) async {
    // Get current state to use for inning/outs
    final currentState = state.value ?? await _computeCurrentState();
    
    // Delegate to atBatsProvider (which handles optimistic updates)
    final atBat = await ref.read(atBatsProvider(_params.gameId).notifier).createAtBat(
      playerId: playerId,
      result: result,
      inning: currentState.inning,
      outs: currentState.outs,
      battingOrder: battingOrder,
      hitLocation: hitLocation,
      hitType: hitType,
      rbis: rbis,
    );
    
    // State will automatically recompute via the listener
    return atBat;
  }
  
  /// Get the last recorded at-bat for editing
  AtBat? getLastAtBat() {
    final atBatsAsync = ref.read(atBatsProvider(_params.gameId));
    if (!atBatsAsync.hasValue) return null;
    
    final atBats = atBatsAsync.value!;
    if (atBats.isEmpty) return null;
    
    // Sort by createdAt and get the most recent
    final sorted = List<AtBat>.from(atBats)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sorted.first;
  }

  /// Update an existing at-bat
  Future<AtBat?> updateAtBatRecord({
    required String atBatId,
    String? result,
    Map<String, double>? hitLocation,
    String? hitType,
    int? rbis,
  }) async {
    // Delegate to atBatsProvider (which handles optimistic updates and rollback)
    final atBat = await ref.read(atBatsProvider(_params.gameId).notifier).updateAtBat(
      atBatId: atBatId,
      result: result,
      hitLocation: hitLocation,
      hitType: hitType,
      rbis: rbis,
    );
    
    // State will automatically recompute via the listener
    return atBat;
  }
}

