import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../utils/persistence.dart';

/// Provider for the ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    baseUrl: Environment.apiBaseUrl,
  );
});

/// Provider for teams list with automatic caching
/// 
/// This provider:
/// - Caches the teams list in memory (session-only)
/// - Shows cached data immediately on navigation
/// - Fetches fresh data in background
/// - Supports pull-to-refresh via ref.refresh(teamsProvider)
final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<Team>>(
  () => TeamsNotifier(),
);

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // Attempt to load cached teams first
    final cached = await Persistence.getJson<List<Team>>(
      'teams_cache',
      (obj) => (obj as List).map((e) => Team.fromJson(e as Map<String, dynamic>)).toList(),
    );
    if (cached != null && cached.isNotEmpty) {
      // Emit cached immediately, then refresh in background
      Future.microtask(() async {
        try {
          final api = ref.read(apiServiceProvider);
          final fresh = await api.listTeams();
          state = AsyncValue.data(fresh);
          await Persistence.setJson('teams_cache', fresh.map((t) => t.toJson()).toList());
        } catch (_) {}
      });
      return cached;
    }

    final apiService = ref.watch(apiServiceProvider);
    final teams = await apiService.listTeams();
    await Persistence.setJson('teams_cache', teams.map((t) => t.toJson()).toList());
    return teams;
  }

  /// Refresh the teams list (for pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      final teams = await apiService.listTeams();
      await Persistence.setJson('teams_cache', teams.map((t) => t.toJson()).toList());
      return teams;
    });
  }

  /// Create a new team and refresh the list
  Future<Team> createTeam({
    required String name,
    String? description,
  }) async {
    // Optimistic add
    final current = (state.value ?? <Team>[]);
    state = AsyncValue.data([
      ...current,
      Team(
        teamId: 'temp-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        description: description ?? '',
        role: 'team-owner',
        memberCount: 1,
        joinedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ]);

    final apiService = ref.read(apiServiceProvider);
    final newTeam = await apiService.createTeam(
      name: name,
      description: description,
    );
    // Replace temp with real
    final replaced = (state.value ?? <Team>[])..removeWhere((t) => t.teamId.startsWith('temp-'));
    replaced.add(newTeam);
    state = AsyncValue.data(replaced);
    await Persistence.setJson('teams_cache', replaced.map((t) => t.toJson()).toList());
    
    return newTeam;
  }

  /// Update a team and refresh the list
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? description,
  }) async {
    // Optimistic update
    final prev = List<Team>.from(state.value ?? <Team>[]);
    final idx = prev.indexWhere((t) => t.teamId == teamId);
    if (idx != -1) {
      final t = prev[idx];
      prev[idx] = Team(
        teamId: t.teamId,
        name: name ?? t.name,
        description: description ?? t.description,
        role: t.role,
        memberCount: t.memberCount,
        joinedAt: t.joinedAt,
        createdAt: t.createdAt,
      );
      state = AsyncValue.data(prev);
    }

    final apiService = ref.read(apiServiceProvider);
    final updatedTeam = await apiService.updateTeam(
      teamId: teamId,
      name: name,
      description: description,
    );
    // Ensure cache updated
    final curr = List<Team>.from(state.value ?? <Team>[]);
    final i = curr.indexWhere((t) => t.teamId == teamId);
    if (i != -1) curr[i] = updatedTeam;
    state = AsyncValue.data(curr);
    await Persistence.setJson('teams_cache', curr.map((t) => t.toJson()).toList());
    
    return updatedTeam;
  }

  /// Delete a team and refresh the list
  Future<void> deleteTeam(String teamId) async {
    // Optimistic remove
    final prev = List<Team>.from(state.value ?? <Team>[]);
    final next = prev..removeWhere((t) => t.teamId == teamId);
    state = AsyncValue.data(next);
    await Persistence.setJson('teams_cache', next.map((t) => t.toJson()).toList());

    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.deleteTeam(teamId);
    } catch (e) {
      // Rollback
      state = AsyncValue.data(prev);
      await Persistence.setJson('teams_cache', prev.map((t) => t.toJson()).toList());
      rethrow;
    }
  }
}

/// Provider for the currently selected team
/// 
/// This is a simple state provider that holds the selected team
/// from the dropdown/list selection.
final selectedTeamProvider = StateProvider<Team?>((ref) => null);

/// Provider for a specific team by ID with automatic caching
/// 
/// This is a family provider that caches individual team lookups.
/// Each teamId gets its own cached entry.
final teamByIdProvider = FutureProvider.family<Team, String>((ref, teamId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getTeam(teamId);
});

