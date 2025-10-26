import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'team_providers.dart';
import '../utils/persistence.dart';
import '../utils/messenger.dart';

/// Roster provider (family) that fetches players for a given teamId
final rosterProvider = AsyncNotifierProvider.family<RosterNotifier, List<Player>, String>(
  (teamId) => RosterNotifier(teamId),
);

/// Actions helper for roster mutations (add/update/remove)
class RosterNotifier extends AsyncNotifier<List<Player>> {
  RosterNotifier(this._teamId);
  final String _teamId;

  @override
  Future<List<Player>> build() async {
    final cacheKey = 'roster_cache_$_teamId';
    final cached = await Persistence.getJson<List<Player>>(
      cacheKey,
      (obj) => (obj as List).map((e) => Player.fromJson(e as Map<String, dynamic>)).toList(),
    );
    if (cached != null) {
      Future.microtask(() async {
        try {
          final api = ref.read(apiServiceProvider);
          final fresh = await api.listPlayers(_teamId);
          state = AsyncValue.data(fresh);
          await Persistence.setJson(cacheKey, fresh.map((p) => p.toJson()).toList());
        } catch (_) {}
      });
      return cached;
    }

    final api = ref.read(apiServiceProvider);
    final players = await api.listPlayers(_teamId);
    await Persistence.setJson(cacheKey, players.map((p) => p.toJson()).toList());
    return players;
  }

  RosterActions actions() => RosterActions(ref, _teamId, this);

  /// Expose the current state for RosterActions
  AsyncValue<List<Player>> get currentState => state;

  /// Perform an optimistic mutation with automatic rollback on error
  Future<R?> mutate<R>({
    required List<Player> Function(List<Player> current) optimisticUpdate,
    required Future<R> Function() apiCall,
    required List<Player> Function(List<Player> current, R result) applyResult,
    required List<Player> Function(List<Player> current) rollback,
    String? successMessage,
    String Function(dynamic error)? errorMessage,
  }) async {
    // Guard clause: Only mutate if state is data (not loading/error)
    if (state is! AsyncData<List<Player>>) {
      return null;
    }

    // 1. Apply optimistic update to current state
    state = AsyncValue.data(optimisticUpdate(state.requireValue));

    try {
      // 2. Execute API call
      final result = await apiCall();
      
      // 3. Apply real result to current state (may have changed since step 1)
      state = AsyncValue.data(applyResult(state.requireValue, result));
      
      // 4. Show success message
      if (successMessage != null) {
        showSuccessToast(successMessage);
      }
      
      return result;
    } catch (e) {
      // 5. Rollback from current state (not previous snapshot)
      state = AsyncValue.data(rollback(state.requireValue));
      
      // 6. Show error message
      final errorMsg = errorMessage?.call(e) ?? 'Operation failed';
      showErrorToast(errorMsg);
      
      // Don't rethrow - error is handled via toast
      return null;
    }
  }
}

class RosterActions {
  final Ref ref;
  final String teamId;
  final RosterNotifier notifier;

  RosterActions(this.ref, this.teamId, this.notifier);

  ApiService get _api => ref.read(apiServiceProvider);

  Future<Player?> addPlayer({
    required String firstName,
    String? lastName,
    int? playerNumber,
    String? status,
  }) async {
    // Create temp player for optimistic update
    final temp = Player(
      playerId: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      teamId: teamId,
      firstName: firstName,
      lastName: lastName,
      playerNumber: playerNumber,
      status: status ?? 'active',
      isGhost: true,
      userId: null,
      linkedAt: null,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    return notifier.mutate<Player>(
      optimisticUpdate: (current) => [...current, temp],
      apiCall: () => _api.addPlayer(
        teamId: teamId,
        firstName: firstName,
        lastName: lastName,
        playerNumber: playerNumber,
        status: status,
      ),
      applyResult: (current, realPlayer) {
        // Replace temp with real player
        final updated = [
          for (final p in current)
            if (p.playerId == temp.playerId) realPlayer else p
        ];
        // Persist to cache
        Persistence.setJson('roster_cache_$teamId', updated.map((p) => p.toJson()).toList());
        return updated;
      },
      rollback: (current) {
        // Remove temp player on failure
        final rolledBack = current.where((p) => p.playerId != temp.playerId).toList();
        Persistence.setJson('roster_cache_$teamId', rolledBack.map((p) => p.toJson()).toList());
        return rolledBack;
      },
      successMessage: 'Added ${temp.firstName} to roster',
      errorMessage: (e) => 'Failed to add player: $e',
    );
  }

  Future<Player?> updatePlayer(
    String playerId, {
    String? firstName,
    String? lastName,
    int? playerNumber,
    String? status,
  }) async {
    // Find the original player for rollback
    final original = notifier.currentState.value?.firstWhere(
      (p) => p.playerId == playerId,
      orElse: () => throw StateError('Player not found'),
    );
    
    if (original == null) return null;

    return notifier.mutate<Player>(
      optimisticUpdate: (current) {
        return [
          for (final p in current)
            if (p.playerId == playerId)
              Player(
                playerId: p.playerId,
                teamId: p.teamId,
                firstName: firstName ?? p.firstName,
                lastName: lastName ?? p.lastName,
                playerNumber: playerNumber ?? p.playerNumber,
                status: status ?? p.status,
                isGhost: p.isGhost,
                userId: p.userId,
                linkedAt: p.linkedAt,
                createdAt: p.createdAt,
                updatedAt: DateTime.now().toIso8601String(),
              )
            else
              p
        ];
      },
      apiCall: () => _api.updatePlayer(
        teamId: teamId,
        playerId: playerId,
        firstName: firstName,
        lastName: lastName,
        playerNumber: playerNumber,
        status: status,
      ),
      applyResult: (current, realPlayer) {
        // Replace with real updated player
        final updated = [
          for (final p in current)
            if (p.playerId == playerId) realPlayer else p
        ];
        Persistence.setJson('roster_cache_$teamId', updated.map((p) => p.toJson()).toList());
        return updated;
      },
      rollback: (current) {
        // Restore original player
        final rolledBack = [
          for (final p in current)
            if (p.playerId == playerId) original else p
        ];
        Persistence.setJson('roster_cache_$teamId', rolledBack.map((p) => p.toJson()).toList());
        return rolledBack;
      },
      successMessage: 'Updated ${original.fullName}',
      errorMessage: (e) => 'Failed to update player: $e',
    );
  }

  Future<void> removePlayer(String playerId) async {
    // Find the player being removed for rollback
    final removed = notifier.currentState.value?.firstWhere(
      (p) => p.playerId == playerId,
      orElse: () => throw StateError('Player not found'),
    );
    
    if (removed == null) return;

    await notifier.mutate<void>(
      optimisticUpdate: (current) {
        return current.where((p) => p.playerId != playerId).toList();
      },
      apiCall: () => _api.removePlayer(teamId, playerId),
      applyResult: (current, _) {
        // Player already removed in optimistic update
        Persistence.setJson('roster_cache_$teamId', current.map((p) => p.toJson()).toList());
        return current;
      },
      rollback: (current) {
        // Re-insert the removed player
        final rolledBack = [...current, removed];
        Persistence.setJson('roster_cache_$teamId', rolledBack.map((p) => p.toJson()).toList());
        return rolledBack;
      },
      successMessage: 'Removed ${removed.fullName}',
      errorMessage: (e) => 'Failed to remove player: $e',
    );
  }
}

/// Provider for roster actions bound to a specific teamId
final rosterActionsProvider = Provider.family<RosterActions, String>((ref, teamId) {
  final notifier = ref.read(rosterProvider(teamId).notifier);
  return RosterActions(ref, teamId, notifier);
});


