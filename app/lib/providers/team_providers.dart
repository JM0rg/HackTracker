import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Provider for the ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    baseUrl: 'https://ugbhshzkh1.execute-api.us-east-1.amazonaws.com',
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
    // This is called on first access and whenever invalidated
    final apiService = ref.watch(apiServiceProvider);
    return await apiService.listTeams();
  }

  /// Refresh the teams list (for pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.listTeams();
    });
  }

  /// Create a new team and refresh the list
  Future<Team> createTeam({
    required String name,
    String? description,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    final newTeam = await apiService.createTeam(
      name: name,
      description: description,
    );
    
    // Refresh the teams list to include the new team
    await refresh();
    
    return newTeam;
  }

  /// Update a team and refresh the list
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? description,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    final updatedTeam = await apiService.updateTeam(
      teamId: teamId,
      name: name,
      description: description,
    );
    
    // Refresh the teams list
    await refresh();
    
    return updatedTeam;
  }

  /// Delete a team and refresh the list
  Future<void> deleteTeam(String teamId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.deleteTeam(teamId);
    
    // Refresh the teams list
    await refresh();
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

