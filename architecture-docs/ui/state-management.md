# State Management Documentation

**Part of:** [UI_ARCHITECTURE.md](../UI_ARCHITECTURE.md) - Complete frontend implementation guide

This document provides a deep dive into HackTracker's Riverpod 3.0+ state management implementation, including provider architecture, caching strategies, and optimistic UI patterns.

---

## Table of Contents

1. [Provider Architecture](#provider-architecture)
2. [AsyncNotifier Patterns](#asyncnotifier-patterns)
3. [Family Providers](#family-providers)
4. [Optimistic Mutation Implementation](#optimistic-mutation-implementation)
5. [Cache Management](#cache-management)
6. [App Lifecycle Hooks](#app-lifecycle-hooks)
7. [State Management Patterns](#state-management-patterns)

---

## Provider Architecture

### Provider Types Used

HackTracker uses three main provider types:

#### 1. AsyncNotifierProvider (Primary Pattern)

For data fetching and caching:

```dart
// Example: TeamsNotifier
final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<Team>>(() {
  return TeamsNotifier();
});

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // Implementation details below
  }
}
```

**Use Cases:**
- API data fetching
- Persistent caching
- Background refresh
- Error handling

#### 2. StateProvider (Simple State)

For UI state and configuration:

```dart
final selectedTeamProvider = StateProvider<Team?>((ref) => null);
final authStatusProvider = StateProvider<AuthStatus>((ref) => AuthStatus.valid);
final isLoadingProvider = StateProvider<bool>((ref) => false);
```

**Use Cases:**
- UI state (selected items, loading flags)
- Configuration values
- Simple boolean flags
- Navigation state

#### 3. Family Providers

For parameterized providers:

```dart
final playerProvider = AsyncNotifierProvider.family<PlayerNotifier, Player?, String>(
  () => PlayerNotifier(),
);

class PlayerNotifier extends FamilyAsyncNotifier<Player?, String> {
  @override
  Future<Player?> build(String playerId) async {
    // Fetch specific player by ID
  }
}
```

**Use Cases:**
- Entity-specific data (player by ID, team by ID)
- Parameterized queries
- Dynamic data fetching

### Provider Dependencies

```dart
// Provider dependency graph
teamsProvider
├── apiServiceProvider
└── persistence (cache)

playersProvider
├── apiServiceProvider
├── selectedTeamProvider
└── persistence (cache)

currentUserProvider
├── apiServiceProvider
└── persistence (cache)

authStatusProvider
└── AuthService
```

---

## AsyncNotifier Patterns

### Basic AsyncNotifier Structure

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // 1. Try to load cached data first
    final cached = await Persistence.getJson<List<Team>>(
      'teams_cache',
      (obj) => (obj as List).map((e) => Team.fromJson(e as Map<String, dynamic>)).toList(),
    );
    
    // 2. If cache exists, show it immediately and refresh in background
    if (cached != null && cached.isNotEmpty) {
      Future.microtask(() async {
        try {
          final api = ref.read(apiServiceProvider);
          final fresh = await api.listTeams();
          state = AsyncValue.data(fresh);
          await Persistence.setJson('teams_cache', fresh.map((t) => t.toJson()).toList());
        } catch (_) {
          // Keep cached data on error
        }
      });
      return cached;
    }
    
    // 3. No cache - fetch from API
    final apiService = ref.watch(apiServiceProvider);
    final teams = await apiService.listTeams();
    await Persistence.setJson('teams_cache', teams.map((t) => t.toJson()).toList());
    return teams;
  }
}
```

### Stale-While-Revalidate (SWR) Pattern

The SWR pattern provides immediate data display with background refresh:

```dart
@override
Future<List<Team>> build() async {
  // Step 1: Load cached data
  final cached = await _loadCachedData();
  
  if (cached != null) {
    // Step 2: Show cached data immediately
    Future.microtask(() => _refreshInBackground());
    return cached;
  }
  
  // Step 3: No cache - fetch fresh data
  return await _fetchFreshData();
}

Future<void> _refreshInBackground() async {
  try {
    final fresh = await _fetchFreshData();
    state = AsyncValue.data(fresh);
  } catch (_) {
    // Keep cached data on error
  }
}
```

### Error Handling in AsyncNotifier

```dart
@override
Future<List<Team>> build() async {
  try {
    // Data fetching logic
    return await _fetchData();
  } catch (e) {
    // Log error for debugging
    print('Error in TeamsNotifier: $e');
    
    // Return empty list or cached data
    final cached = await _loadCachedData();
    return cached ?? [];
  }
}
```

### Loading State Management

```dart
@override
Future<List<Team>> build() async {
  // AsyncNotifier automatically handles loading states
  // state is AsyncValue<List<Team>>
  
  final cached = await _loadCachedData();
  if (cached != null) {
    // Show cached data immediately
    Future.microtask(() => _refreshInBackground());
    return cached;
  }
  
  // This will show loading state until data is fetched
  return await _fetchFreshData();
}
```

---

## Family Providers

### Family Provider Structure

```dart
final playerProvider = AsyncNotifierProvider.family<PlayerNotifier, Player?, String>(
  () => PlayerNotifier(),
);

class PlayerNotifier extends FamilyAsyncNotifier<Player?, String> {
  @override
  Future<Player?> build(String playerId) async {
    // Fetch specific player by ID
    try {
      final api = ref.read(apiServiceProvider);
      final selectedTeam = ref.read(selectedTeamProvider);
      
      if (selectedTeam == null) return null;
      
      return await api.getPlayer(selectedTeam.teamId, playerId);
    } catch (e) {
      print('Error fetching player $playerId: $e');
      return null;
    }
  }
}
```

### Family Provider Usage

```dart
// In widget
class PlayerDetailsWidget extends ConsumerWidget {
  final String playerId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider(playerId));
    
    return playerAsync.when(
      data: (player) => player != null 
        ? PlayerCard(player: player)
        : Text('Player not found'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Family Provider Caching

```dart
class PlayerNotifier extends FamilyAsyncNotifier<Player?, String> {
  @override
  Future<Player?> build(String playerId) async {
    // Try cache first
    final cached = await Persistence.getJson<Player>(
      'player_$playerId',
      (obj) => Player.fromJson(obj as Map<String, dynamic>),
    );
    
    if (cached != null) {
      Future.microtask(() => _refreshPlayerInBackground(playerId));
      return cached;
    }
    
    // Fetch from API
    return await _fetchPlayerFromAPI(playerId);
  }
  
  Future<void> _refreshPlayerInBackground(String playerId) async {
    try {
      final fresh = await _fetchPlayerFromAPI(playerId);
      state = AsyncValue.data(fresh);
      await Persistence.setJson('player_$playerId', fresh?.toJson());
    } catch (_) {
      // Keep cached data on error
    }
  }
}
```

---

## Optimistic Mutation Implementation

### Race-Condition-Safe Pattern

HackTracker implements optimistic UI updates that are safe from race conditions:

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  Future<void> addTeam(String name, String description) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    // Step 1: Generate temporary ID
    final tempId = _generateTempId();
    
    // Step 2: Create optimistic team
    final tempTeam = Team(
      teamId: tempId,
      name: name,
      description: description,
      ownerId: currentUser.userId,
      status: 'active',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    // Step 3: Update UI immediately
    state.whenData((teams) {
      state = AsyncValue.data([...teams, tempTeam]);
    });
    
    try {
      // Step 4: API call
      final api = ref.read(apiServiceProvider);
      final newTeam = await api.createTeam(name, description);
      
      // Step 5: Replace temp with real data
      state.whenData((teams) {
        final updatedTeams = teams.map((team) {
          return team.teamId == tempId ? newTeam : team;
        }).toList();
        state = AsyncValue.data(updatedTeams);
      });
      
      // Step 6: Update cache
      await _updateCache();
      
    } catch (e) {
      // Step 7: Rollback on error
      await _rollbackAddTeam(tempId);
      rethrow;
    }
  }
  
  String _generateTempId() {
    return 'temp-${DateTime.now().millisecondsSinceEpoch}';
  }
  
  Future<void> _rollbackAddTeam(String tempId) async {
    state.whenData((teams) {
      final updatedTeams = teams.where((team) => team.teamId != tempId).toList();
      state = AsyncValue.data(updatedTeams);
    });
  }
}
```

### Optimistic Update Patterns

#### Add Operations

```dart
Future<void> addItem(ItemData data) async {
  final tempId = _generateTempId();
  final tempItem = Item(id: tempId, ...data);
  
  // Optimistic update
  state.whenData((items) {
    state = AsyncValue.data([...items, tempItem]);
  });
  
  try {
    final newItem = await api.createItem(data);
    
    // Replace temp with real
    state.whenData((items) {
      final updated = items.map((item) => item.id == tempId ? newItem : item).toList();
      state = AsyncValue.data(updated);
    });
  } catch (e) {
    // Rollback
    state.whenData((items) {
      state = AsyncValue.data(items.where((item) => item.id != tempId).toList());
    });
    rethrow;
  }
}
```

#### Update Operations

```dart
Future<void> updateItem(String id, ItemData data) async {
  // Store original for rollback
  Item? originalItem;
  state.whenData((items) {
    originalItem = items.firstWhere((item) => item.id == id);
  });
  
  // Optimistic update
  state.whenData((items) {
    final updated = items.map((item) {
      return item.id == id ? item.copyWith(...data) : item;
    }).toList();
    state = AsyncValue.data(updated);
  });
  
  try {
    final updatedItem = await api.updateItem(id, data);
    
    // Replace with real data
    state.whenData((items) {
      final updated = items.map((item) => item.id == id ? updatedItem : item).toList();
      state = AsyncValue.data(updated);
    });
  } catch (e) {
    // Rollback to original
    if (originalItem != null) {
      state.whenData((items) {
        final updated = items.map((item) => item.id == id ? originalItem! : item).toList();
        state = AsyncValue.data(updated);
      });
    }
    rethrow;
  }
}
```

#### Delete Operations

```dart
Future<void> removeItem(String id) async {
  // Store original for rollback
  List<Item> originalItems = [];
  state.whenData((items) {
    originalItems = List.from(items);
  });
  
  // Optimistic update
  state.whenData((items) {
    state = AsyncValue.data(items.where((item) => item.id != id).toList());
  });
  
  try {
    await api.deleteItem(id);
    // Success - keep optimistic state
  } catch (e) {
    // Rollback
    state = AsyncValue.data(originalItems);
    rethrow;
  }
}
```

### Success/Error Messaging

```dart
Future<void> addTeam(String name, String description) async {
  // ... optimistic update logic ...
  
  try {
    // ... API call ...
    Messenger.showSuccess(context, 'Team created successfully!');
  } catch (e) {
    // ... rollback logic ...
    Messenger.showError(context, 'Failed to create team: ${e.toString()}');
  }
}
```

---

## Cache Management

### Cache Versioning Strategy

```dart
class Persistence {
  static const String _cacheVersion = '1.0.0';
  
  static Future<void> setJson<T>(String key, T data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'version': _cacheVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };
    await prefs.setString(key, jsonEncode(cacheData));
  }
  
  static Future<T?> getJson<T>(String key, T Function(dynamic) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      final cacheData = jsonDecode(jsonString);
      final version = cacheData['version'] as String?;
      
      if (version != _cacheVersion) {
        // Clear outdated cache
        await prefs.remove(key);
        return null;
      }
      
      return fromJson(cacheData['data']);
    } catch (e) {
      // Clear corrupted cache
      await prefs.remove(key);
      return null;
    }
  }
}
```

### Cache Keys and Structure

```dart
// Standardized cache keys
class CacheKeys {
  static const String teams = 'teams_cache';
  static const String players = 'players_cache';
  static const String currentUser = 'current_user_cache';
  static const String authStatus = 'auth_status_cache';
  
  // Dynamic keys
  static String player(String playerId) => 'player_$playerId';
  static String team(String teamId) => 'team_$teamId';
}

// Cache structure
{
  "version": "1.0.0",
  "timestamp": "2025-01-27T10:30:00.000Z",
  "data": [/* actual data */]
}
```

### Cache Invalidation

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  Future<void> _invalidateCache() async {
    await Persistence.clearCache(CacheKeys.teams);
  }
  
  Future<void> _updateCache() async {
    state.whenData((teams) async {
      await Persistence.setJson(CacheKeys.teams, teams.map((t) => t.toJson()).toList());
    });
  }
  
  Future<void> refreshTeams() async {
    await _invalidateCache();
    ref.invalidateSelf();
  }
}
```

### Cache TTL (Time To Live)

```dart
class Persistence {
  static const Duration _cacheTTL = Duration(hours: 24);
  
  static Future<T?> getJson<T>(String key, T Function(dynamic) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      final cacheData = jsonDecode(jsonString);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      
      if (DateTime.now().difference(timestamp) > _cacheTTL) {
        // Cache expired
        await prefs.remove(key);
        return null;
      }
      
      return fromJson(cacheData['data']);
    } catch (e) {
      await prefs.remove(key);
      return null;
    }
  }
}
```

---

## App Lifecycle Hooks

### App Resume Refresh

```dart
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState> {
  AppLifecycleNotifier() : super(AppLifecycleState.resumed);
  
  void onAppResumed() {
    state = AppLifecycleState.resumed;
    _refreshAllData();
  }
  
  void onAppPaused() {
    state = AppLifecycleState.paused;
  }
  
  Future<void> _refreshAllData() async {
    // Refresh all cached data when app resumes
    try {
      // Invalidate and refresh teams
      ref.read(teamsProvider.notifier).refreshTeams();
      
      // Invalidate and refresh current user
      ref.read(currentUserProvider.notifier).refreshUser();
      
      // Refresh any other cached data
    } catch (e) {
      print('Error refreshing data on app resume: $e');
    }
  }
}

final appLifecycleProvider = StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
  (ref) => AppLifecycleNotifier(),
);
```

### Widget Lifecycle Integration

```dart
class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(appLifecycleProvider.notifier).onAppResumed();
        break;
      case AppLifecycleState.paused:
        ref.read(appLifecycleProvider.notifier).onAppPaused();
        break;
      default:
        break;
    }
  }
}
```

### Background Refresh Strategy

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  Timer? _refreshTimer;
  
  @override
  Future<List<Team>> build() async {
    // Start background refresh timer
    _startBackgroundRefresh();
    
    // Load initial data
    return await _loadData();
  }
  
  void _startBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _refreshInBackground();
    });
  }
  
  Future<void> _refreshInBackground() async {
    try {
      final api = ref.read(apiServiceProvider);
      final fresh = await api.listTeams();
      state = AsyncValue.data(fresh);
      await _updateCache();
    } catch (_) {
      // Keep existing data on error
    }
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
```

---

## State Management Patterns

### Provider Composition

```dart
// Compose multiple providers for complex state
final teamWithPlayersProvider = Provider<TeamWithPlayers?>((ref) {
  final selectedTeam = ref.watch(selectedTeamProvider);
  final playersAsync = ref.watch(playersProvider);
  
  if (selectedTeam == null) return null;
  
  return playersAsync.when(
    data: (players) => TeamWithPlayers(team: selectedTeam, players: players),
    loading: () => null,
    error: (_, __) => null,
  );
});
```

### State Synchronization

```dart
// Keep related state in sync
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // Listen to auth changes
    ref.listen(authStatusProvider, (previous, next) {
      if (next == AuthStatus.invalidToken) {
        // Clear teams when user signs out
        state = const AsyncValue.data([]);
        _clearCache();
      }
    });
    
    return await _loadData();
  }
}
```

### State Validation

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  Future<void> addTeam(String name, String description) async {
    // Validate input
    if (name.trim().isEmpty) {
      throw ArgumentError('Team name cannot be empty');
    }
    
    if (name.length < 3 || name.length > 50) {
      throw ArgumentError('Team name must be 3-50 characters');
    }
    
    // Proceed with optimistic update
    // ...
  }
}
```

### State Persistence

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // Load from cache first
    final cached = await _loadFromCache();
    if (cached != null) {
      Future.microtask(() => _refreshInBackground());
      return cached;
    }
    
    // Fetch fresh data
    final fresh = await _fetchFromAPI();
    await _saveToCache(fresh);
    return fresh;
  }
  
  Future<void> _saveToCache(List<Team> teams) async {
    await Persistence.setJson(CacheKeys.teams, teams.map((t) => t.toJson()).toList());
  }
  
  Future<List<Team>?> _loadFromCache() async {
    return await Persistence.getJson<List<Team>>(
      CacheKeys.teams,
      (obj) => (obj as List).map((e) => Team.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
```

---

## Testing State Management

### Provider Testing

```dart
void main() {
  group('TeamsNotifier', () {
    test('should load teams from API', () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(MockApiService()),
        ],
      );
      
      final notifier = container.read(teamsProvider.notifier);
      final teams = await container.read(teamsProvider.future);
      
      expect(teams, isA<List<Team>>());
      expect(teams.length, greaterThan(0));
    });
    
    test('should handle optimistic updates', () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(MockApiService()),
        ],
      );
      
      final notifier = container.read(teamsProvider.notifier);
      
      // Add team optimistically
      await notifier.addTeam('Test Team', 'Test Description');
      
      final teams = container.read(teamsProvider);
      expect(teams.value?.length, 1);
      expect(teams.value?.first.name, 'Test Team');
    });
  });
}
```

### Integration Testing

```dart
testWidgets('Teams should persist across app restarts', (tester) async {
  // Create teams
  await tester.tap(find.byType(FloatingActionButton));
  await tester.enterText(find.byType(AppTextField).first, 'Test Team');
  await tester.tap(find.text('Create'));
  await tester.pumpAndSettle();
  
  // Restart app
  await tester.binding.reassembleApplication();
  await tester.pumpAndSettle();
  
  // Verify teams persist
  expect(find.text('Test Team'), findsOneWidget);
});
```

---

## Performance Considerations

### Provider Optimization

```dart
// Use select to minimize rebuilds
class TeamListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when team count changes, not when individual teams change
    final teamCount = ref.watch(teamsProvider.select((teams) => teams.value?.length ?? 0));
    
    return Text('Teams: $teamCount');
  }
}
```

### Memory Management

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  void dispose() {
    // Cancel timers
    _refreshTimer?.cancel();
    
    // Clear large data structures
    state = const AsyncValue.data([]);
    
    super.dispose();
  }
}
```

### Lazy Loading

```dart
// Only load data when needed
final expensiveDataProvider = FutureProvider<ExpensiveData>((ref) async {
  // Only fetch when first accessed
  return await _fetchExpensiveData();
});
```

---

## Summary

HackTracker's state management architecture provides:

- **Modern Riverpod 3.0+ Patterns** - AsyncNotifier, StateProvider, Family providers
- **Persistent Caching** - Shared Preferences with versioning and TTL
- **Optimistic UI** - Race-condition-safe updates with rollback
- **Background Refresh** - Stale-while-revalidate pattern
- **App Lifecycle Integration** - Resume refresh and pause handling
- **Error Handling** - Comprehensive error states and recovery
- **Performance Optimization** - Selective rebuilds and memory management
- **Testing Support** - Provider testing and integration testing

The state management system provides a **robust foundation** for complex UI interactions while maintaining **performance** and **user experience** standards.
