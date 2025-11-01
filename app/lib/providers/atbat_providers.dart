import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/atbat.dart';
import '../utils/persistence.dart';
import '../utils/messenger.dart';
import 'api_provider.dart';

/// Provider for at-bats list with automatic caching (per game)
/// 
/// This provider:
/// - Caches the at-bats list for each game
/// - Shows cached data immediately on navigation
/// - Fetches fresh data in background
/// - Supports pull-to-refresh via ref.refresh(atBatsProvider(gameId))
final atBatsProvider = AsyncNotifierProvider.family<AtBatsNotifier, List<AtBat>, String>(
  (gameId) => AtBatsNotifier(gameId),
);

class AtBatsNotifier extends AsyncNotifier<List<AtBat>> {
  AtBatsNotifier(this._gameId);
  final String _gameId;

  @override
  Future<List<AtBat>> build() async {
    final cached = await Persistence.getJson<List<AtBat>>(
      CacheKeys.atBats(_gameId),
      (obj) => (obj as List).map((e) => AtBat.fromJson(e as Map<String, dynamic>)).toList(),
    );
    
    if (cached != null && cached.isNotEmpty) {
      // Emit cached immediately, then refresh in background
      Future.microtask(() async {
        try {
          final api = ref.read(apiServiceProvider);
          final fresh = await api.listAtBats(_gameId);
          // Sort at-bats by creation time (chronological)
          fresh.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          state = AsyncValue.data(fresh);
          await Persistence.setJson(CacheKeys.atBats(_gameId), fresh.map((ab) => ab.toJson()).toList());
        } catch (_) {}
      });
      return cached;
    }

    final api = ref.read(apiServiceProvider);
    final atBats = await api.listAtBats(_gameId);
    // Sort at-bats by creation time (chronological)
    atBats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await Persistence.setJson(CacheKeys.atBats(_gameId), atBats.map((ab) => ab.toJson()).toList());
    return atBats;
  }

  /// Refresh the at-bats list (for pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    
    try {
      final api = ref.read(apiServiceProvider);
      final atBats = await api.listAtBats(_gameId);
      // Sort at-bats by creation time (chronological)
      atBats.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = AsyncValue.data(atBats);
      await Persistence.setJson(CacheKeys.atBats(_gameId), atBats.map((ab) => ab.toJson()).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a new at-bat with optimistic update
  Future<AtBat?> createAtBat({
    required String playerId,
    required String result,
    required int inning,
    required int outs,
    required int battingOrder,
    Map<String, double>? hitLocation,
    String? hitType,
    int? rbis,
  }) async {
    // Get current at-bats list
    final current = state.hasValue ? state.value! : <AtBat>[];

    // Create temp at-bat for optimistic update
    final temp = AtBat(
      atBatId: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      gameId: _gameId,
      teamId: 'unknown', // Will be set by backend
      playerId: playerId,
      result: result,
      inning: inning,
      outs: outs,
      hitLocation: hitLocation,
      hitType: hitType,
      rbis: rbis,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Optimistically add the at-bat
    final updated = <AtBat>[...current, temp];
    state = AsyncValue.data(updated);

    try {
      final api = ref.read(apiServiceProvider);
      final created = await api.createAtBat(
        gameId: _gameId,
        playerId: playerId,
        result: result,
        inning: inning,
        outs: outs,
        battingOrder: battingOrder,
        hitLocation: hitLocation,
        hitType: hitType,
        rbis: rbis,
      );

      // Replace temp with real at-bat
      final finalList = <AtBat>[...updated.where((ab) => ab.atBatId != temp.atBatId), created];
      finalList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      state = AsyncValue.data(finalList);
      await Persistence.setJson(CacheKeys.atBats(_gameId), finalList.map((ab) => ab.toJson()).toList());

      showSuccessToast('At-bat recorded successfully');
      return created;
    } catch (e) {
      // Rollback optimistic update
      state = AsyncValue.data(current);
      showErrorToast('Failed to record at-bat: $e');
      return null;
    }
  }

  /// Update an existing at-bat with optimistic update
  Future<AtBat?> updateAtBat({
    required String atBatId,
    String? result,
    Map<String, double>? hitLocation,
    String? hitType,
    int? rbis,
    int? inning,
    int? outs,
  }) async {
    final current = state.hasValue ? state.value! : <AtBat>[];
    final index = current.indexWhere((ab) => ab.atBatId == atBatId);
    
    if (index == -1) {
      showErrorToast('At-bat not found');
      return null;
    }

    final existing = current[index];

    // Create optimistically updated at-bat
    final updated = AtBat(
      atBatId: existing.atBatId,
      gameId: existing.gameId,
      teamId: existing.teamId,
      playerId: existing.playerId,
      result: result ?? existing.result,
      inning: inning ?? existing.inning,
      outs: outs ?? existing.outs,
      hitLocation: hitLocation ?? existing.hitLocation,
      hitType: hitType ?? existing.hitType,
      rbis: rbis ?? existing.rbis,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    // Optimistically update the list
    final updatedList = <AtBat>[...current];
    updatedList[index] = updated;
    state = AsyncValue.data(updatedList);

    try {
      final api = ref.read(apiServiceProvider);
      final serverUpdated = await api.updateAtBat(
        gameId: _gameId,
        atBatId: atBatId,
        result: result,
        hitLocation: hitLocation,
        hitType: hitType,
        rbis: rbis,
        inning: inning,
        outs: outs,
      );

      // Replace optimistic with server response
      final finalList = <AtBat>[...current];
      finalList[index] = serverUpdated;
      
      state = AsyncValue.data(finalList);
      await Persistence.setJson(CacheKeys.atBats(_gameId), finalList.map((ab) => ab.toJson()).toList());

      showSuccessToast('At-bat updated successfully');
      return serverUpdated;
    } catch (e) {
      // Rollback optimistic update
      state = AsyncValue.data(current);
      showErrorToast('Failed to update at-bat: $e');
      return null;
    }
  }

  /// Delete an at-bat with optimistic update
  Future<bool> deleteAtBat(String atBatId) async {
    final current = state.hasValue ? state.value! : <AtBat>[];
    final index = current.indexWhere((ab) => ab.atBatId == atBatId);
    
    if (index == -1) {
      showErrorToast('At-bat not found');
      return false;
    }

    // Optimistically remove at-bat
    final updated = current.where((ab) => ab.atBatId != atBatId).toList();
    state = AsyncValue.data(updated);

    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteAtBat(_gameId, atBatId);
      
      await Persistence.setJson(CacheKeys.atBats(_gameId), updated.map((ab) => ab.toJson()).toList());
      
      showSuccessToast('At-bat deleted successfully');
      return true;
    } catch (e) {
      // Rollback optimistic update
      state = AsyncValue.data(current);
      showErrorToast('Failed to delete at-bat: $e');
      return false;
    }
  }
}

/// Provider for at-bat actions without holding state
/// 
/// This is a separate provider for actions that don't need to maintain state
/// but need to interact with the API (e.g., for scoring flows)
final atBatActionsProvider = Provider.family<AtBatActions, String>((ref, gameId) {
  return AtBatActions(ref, gameId);
});

class AtBatActions {
  final Ref _ref;
  final String _gameId;

  AtBatActions(this._ref, this._gameId);

  /// Quick method to record an at-bat and refresh the list
  Future<AtBat?> recordAtBat({
    required String playerId,
    required String result,
    required int inning,
    required int outs,
    required int battingOrder,
    Map<String, double>? hitLocation,
    String? hitType,
    int? rbis,
  }) async {
    final notifier = _ref.read(atBatsProvider(_gameId).notifier);
    return notifier.createAtBat(
      playerId: playerId,
      result: result,
      inning: inning,
      outs: outs,
      battingOrder: battingOrder,
      hitLocation: hitLocation,
      hitType: hitType,
      rbis: rbis,
    );
  }

  /// Refresh at-bats list
  Future<void> refresh() async {
    await _ref.read(atBatsProvider(_gameId).notifier).refresh();
  }
}

