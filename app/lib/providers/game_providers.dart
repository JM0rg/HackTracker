import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'team_providers.dart';
import '../utils/persistence.dart';
import '../utils/messenger.dart';

/// Provider for games list with automatic caching (per team)
/// 
/// This provider:
/// - Caches the games list for each team
/// - Shows cached data immediately on navigation
/// - Fetches fresh data in background
/// - Supports pull-to-refresh via ref.refresh(gamesProvider(teamId))
final gamesProvider = AsyncNotifierProvider.family<GamesNotifier, List<Game>, String>(
  (teamId) => GamesNotifier(teamId),
);

class GamesNotifier extends AsyncNotifier<List<Game>> {
  GamesNotifier(this._teamId);
  final String _teamId;

  @override
  Future<List<Game>> build() async {
    final cacheKey = 'games_cache_$_teamId';
    final cached = await Persistence.getJson<List<Game>>(
      cacheKey,
      (obj) => (obj as List).map((e) => Game.fromJson(e as Map<String, dynamic>)).toList(),
    );
    
    if (cached != null && cached.isNotEmpty) {
      // Emit cached immediately, then refresh in background
      Future.microtask(() async {
        try {
          final api = ref.read(apiServiceProvider);
          final fresh = await api.listGames(_teamId);
          // Sort games by scheduledStart
          fresh.sort((a, b) {
            if (a.scheduledStart == null && b.scheduledStart == null) return 0;
            if (a.scheduledStart == null) return 1;
            if (b.scheduledStart == null) return -1;
            return a.scheduledStart!.compareTo(b.scheduledStart!);
          });
          state = AsyncValue.data(fresh);
          await Persistence.setJson(cacheKey, fresh.map((g) => g.toJson()).toList());
        } catch (_) {}
      });
      return cached;
    }

    final api = ref.read(apiServiceProvider);
    final games = await api.listGames(_teamId);
    // Sort games by scheduledStart
    games.sort((a, b) {
      if (a.scheduledStart == null && b.scheduledStart == null) return 0;
      if (a.scheduledStart == null) return 1;
      if (b.scheduledStart == null) return -1;
      return a.scheduledStart!.compareTo(b.scheduledStart!);
    });
    await Persistence.setJson(cacheKey, games.map((g) => g.toJson()).toList());
    return games;
  }

  /// Refresh the games list (for pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final cacheKey = 'games_cache_$_teamId';
    
    try {
      final api = ref.read(apiServiceProvider);
      final games = await api.listGames(_teamId);
      // Sort games by scheduledStart
      games.sort((a, b) {
        if (a.scheduledStart == null && b.scheduledStart == null) return 0;
        if (a.scheduledStart == null) return 1;
        if (b.scheduledStart == null) return -1;
        return a.scheduledStart!.compareTo(b.scheduledStart!);
      });
      state = AsyncValue.data(games);
      await Persistence.setJson(cacheKey, games.map((g) => g.toJson()).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a new game with optimistic update
  Future<Game?> createGame({
    String? status,
    int? teamScore,
    int? opponentScore,
    String? scheduledStart,
    String? opponentName,
    String? location,
    String? seasonId,
    List<dynamic>? lineup,
  }) async {
    // Create temp game for optimistic update
    final temp = Game(
      gameId: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      teamId: _teamId,
      status: status ?? 'SCHEDULED',
      teamScore: teamScore ?? 0,
      opponentScore: opponentScore ?? 0,
      lineup: lineup,
      scheduledStart: scheduledStart != null ? DateTime.parse(scheduledStart) : null,
      opponentName: opponentName,
      location: location,
      seasonId: seasonId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Optimistic update
    final current = state.value ?? <Game>[];
    state = AsyncValue.data([...current, temp]);

    try {
      final api = ref.read(apiServiceProvider);
      final newGame = await api.createGame(
        teamId: _teamId,
        status: status,
        teamScore: teamScore,
        opponentScore: opponentScore,
        scheduledStart: scheduledStart,
        opponentName: opponentName,
        location: location,
        seasonId: seasonId,
        lineup: lineup,
      );

      // Replace temp with real game
      final updated = [
        for (final g in state.value ?? <Game>[])
          if (g.gameId == temp.gameId) newGame else g
      ];
      // Re-sort after adding new game
      updated.sort((a, b) {
        if (a.scheduledStart == null && b.scheduledStart == null) return 0;
        if (a.scheduledStart == null) return 1;
        if (b.scheduledStart == null) return -1;
        return a.scheduledStart!.compareTo(b.scheduledStart!);
      });
      state = AsyncValue.data(updated);
      
      // Persist to cache
      final cacheKey = 'games_cache_$_teamId';
      await Persistence.setJson(cacheKey, updated.map((g) => g.toJson()).toList());

      showSuccessToast('Game created');
      return newGame;
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(current);
      showErrorToast('Failed to create game: $e');
      return null;
    }
  }

  /// Update an existing game with optimistic update
  Future<Game?> updateGame({
    required String gameId,
    String? status,
    int? teamScore,
    int? opponentScore,
    String? scheduledStart,
    String? opponentName,
    String? location,
    String? seasonId,
    List<dynamic>? lineup,
  }) async {
    final current = state.value ?? <Game>[];
    final original = current.firstWhere((g) => g.gameId == gameId, orElse: () => throw StateError('Game not found'));

    // Optimistic update
    final optimistic = [
      for (final g in current)
        if (g.gameId == gameId)
          Game(
            gameId: g.gameId,
            teamId: g.teamId,
            status: status ?? g.status,
            teamScore: teamScore ?? g.teamScore,
            opponentScore: opponentScore ?? g.opponentScore,
            lineup: lineup ?? g.lineup,
            scheduledStart: scheduledStart != null ? DateTime.parse(scheduledStart) : g.scheduledStart,
            opponentName: opponentName ?? g.opponentName,
            location: location ?? g.location,
            seasonId: seasonId ?? g.seasonId,
            createdAt: g.createdAt,
            updatedAt: DateTime.now(),
          )
        else
          g
    ];
    state = AsyncValue.data(optimistic);

    try {
      final api = ref.read(apiServiceProvider);
      final updatedGame = await api.updateGame(
        gameId: gameId,
        status: status,
        teamScore: teamScore,
        opponentScore: opponentScore,
        scheduledStart: scheduledStart,
        opponentName: opponentName,
        location: location,
        seasonId: seasonId,
        lineup: lineup,
      );

      // Replace with real updated game
      final updated = [
        for (final g in state.value ?? <Game>[])
          if (g.gameId == gameId) updatedGame else g
      ];
      // Re-sort after update (in case scheduledStart changed)
      updated.sort((a, b) {
        if (a.scheduledStart == null && b.scheduledStart == null) return 0;
        if (a.scheduledStart == null) return 1;
        if (b.scheduledStart == null) return -1;
        return a.scheduledStart!.compareTo(b.scheduledStart!);
      });
      state = AsyncValue.data(updated);
      
      // Persist to cache
      final cacheKey = 'games_cache_$_teamId';
      await Persistence.setJson(cacheKey, updated.map((g) => g.toJson()).toList());

      showSuccessToast('Game updated');
      return updatedGame;
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data([
        for (final g in current)
          if (g.gameId == gameId) original else g
      ]);
      showErrorToast('Failed to update game: $e');
      return null;
    }
  }

  /// Delete a game with optimistic update
  Future<bool> deleteGame(String gameId) async {
    final current = state.value ?? <Game>[];
    // Validate game exists
    if (!current.any((g) => g.gameId == gameId)) {
      throw StateError('Game not found');
    }

    // Optimistic delete
    state = AsyncValue.data(current.where((g) => g.gameId != gameId).toList());

    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteGame(gameId);
      
      // Persist to cache
      final cacheKey = 'games_cache_$_teamId';
      await Persistence.setJson(cacheKey, (state.value ?? <Game>[]).map((g) => g.toJson()).toList());

      showSuccessToast('Game deleted');
      return true;
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data([...current]);
      showErrorToast('Failed to delete game: $e');
      return false;
    }
  }
}

