import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'team_providers.dart'; // Import apiServiceProvider from here

/// Provider for user's team context
/// 
/// Fetches the user's team context to determine which views to show:
/// - has_personal_context: User has PERSONAL teams
/// - has_managed_context: User has MANAGED teams
/// 
/// This determines the dynamic UI rendering:
/// - Both: Show tabs (Player View + Team View)
/// - Personal only: Show Player View only
/// - Managed only: Show Team View only
/// - Neither: Show Welcome Screen
final userContextProvider = FutureProvider<UserContext>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserContext();
});

/// Notifier for refreshing user context
/// 
/// Call this after creating teams to update the UI state
class UserContextNotifier extends AsyncNotifier<UserContext> {
  @override
  Future<UserContext> build() async {
    print('🔄 UserContextNotifier: Building...');
    try {
      final apiService = ref.watch(apiServiceProvider);
      final context = await apiService.getUserContext();
      print('✅ UserContextNotifier: Build complete');
      return context;
    } catch (e) {
      print('❌ UserContextNotifier: Build failed - $e');
      rethrow;
    }
  }

  /// Manually refresh the user context
  Future<void> refresh() async {
    print('🔄 UserContextNotifier: Refreshing...');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.watch(apiServiceProvider);
      return await apiService.getUserContext();
    });
  }
}

/// Notifier provider for user context with manual refresh capability
final userContextNotifierProvider = AsyncNotifierProvider<UserContextNotifier, UserContext>(
  () => UserContextNotifier(),
);

/// "Hall Pass" notifier for temporarily bypassing welcome screen
/// 
/// This is set to true when the user clicks "Manage a full team" and needs to
/// create their first team. It allows them to access the team creation flow
/// even though they have no teams yet. Resets to false on app restart.
class CreatingFirstTeamNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setCreating(bool value) {
    state = value;
  }
}

final creatingFirstTeamProvider = NotifierProvider<CreatingFirstTeamNotifier, bool>(
  () => CreatingFirstTeamNotifier(),
);

