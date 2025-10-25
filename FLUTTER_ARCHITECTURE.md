# Flutter Frontend Architecture

**Status:** Implemented - Session-based caching with Riverpod

This document describes the Flutter frontend architecture for HackTracker, focusing on state management, caching strategies, and UI patterns.

---

## Overview

### Core Technology

**Riverpod 2.6+** - Reactive state management with built-in caching

**Why Riverpod?**
- Built-in support for async data and caching
- No context needed (works everywhere, even outside widgets)
- Compile-time safety with strong typing
- Easier testing with provider overrides
- Better performance than setState
- Scales well as the app grows

---

## Caching Strategy

### Pattern: Stale-While-Revalidate

**How it works:**
1. User navigates to a screen
2. If cached data exists, show it immediately (no loading spinner)
3. Fetch fresh data in background
4. Update UI when fresh data arrives (if different)

**Benefits:**
- Instant navigation between tabs
- No repeated loading screens
- Always shows the freshest data available
- Graceful handling of offline/slow connections

### Cache Lifecycle

| Event | Action |
|-------|--------|
| **App Launch** | Empty cache, fetch data on first access |
| **Navigation** | Show cached data immediately, refresh in background |
| **Pull-to-Refresh** | Force fresh fetch, update cache |
| **Create/Update/Delete** | Invalidate cache, fetch fresh data |
| **Logout** | Clear all caches |
| **App Close** | Cache cleared (session-only) |

---

## Provider Structure

### Directory: `app/lib/providers/`

```
providers/
├── team_providers.dart      # Teams list, CRUD operations
├── user_providers.dart       # Current user profile
└── (future providers here)
```

### Provider Types

#### 1. AsyncNotifierProvider (For Mutable Data)

**Use for:** API data that can change (teams list, user profile)

**Example:**
```dart
final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<Team>>(
  () => TeamsNotifier(),
);

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    // Initial fetch - called once, cached automatically
    final apiService = ref.watch(apiServiceProvider);
    return await apiService.listTeams();
  }

  Future<void> refresh() async {
    // Manual refresh (pull-to-refresh)
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.listTeams();
    });
  }

  Future<Team> createTeam({required String name, String? description}) async {
    final apiService = ref.read(apiServiceProvider);
    final newTeam = await apiService.createTeam(name: name, description: description);
    await refresh(); // Invalidate cache and fetch fresh data
    return newTeam;
  }
}
```

#### 2. FutureProvider (For Read-Only Data)

**Use for:** Data that doesn't change often, simple fetches

**Example:**
```dart
final currentUserProvider = FutureProvider<User>((ref) async {
  final authUser = await Amplify.Auth.getCurrentUser();
  final attributes = await Amplify.Auth.fetchUserAttributes();
  return User(userId: authUser.userId, email: email);
});
```

#### 3. StateProvider (For Simple State)

**Use for:** UI state that doesn't require async operations

**Example:**
```dart
final selectedTeamProvider = StateProvider<Team?>((ref) => null);
```

#### 4. Provider (For Singletons)

**Use for:** Service instances, configuration

**Example:**
```dart
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: 'https://api.hacktracker.com');
});
```

---

## Screen Patterns

### Converting StatefulWidget to ConsumerStatefulWidget

**Before:**
```dart
class TeamViewScreen extends StatefulWidget {
  const TeamViewScreen({super.key});

  @override
  State<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends State<TeamViewScreen> {
  List<Team>? _teams;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    final teams = await apiService.listTeams();
    setState(() {
      _teams = teams;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return CircularProgressIndicator();
    return ListView(children: _teams!.map(_buildTeamCard).toList());
  }
}
```

**After:**
```dart
class TeamViewScreen extends ConsumerStatefulWidget {
  const TeamViewScreen({super.key});

  @override
  ConsumerState<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends ConsumerState<TeamViewScreen> {
  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);

    return teamsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorView(error: error, onRetry: () => ref.refresh(teamsProvider)),
      data: (teams) => RefreshIndicator(
        onRefresh: () => ref.refresh(teamsProvider.future),
        child: ListView(children: teams.map(_buildTeamCard).toList()),
      ),
    );
  }
}
```

### Converting StatelessWidget to ConsumerWidget

**Before:**
```dart
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('Profile');
  }
}
```

**After:**
```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorView(error: error),
      data: (user) => Text('Welcome ${user.email}'),
    );
  }
}
```

---

## Common Patterns

### 1. Watching Providers in Build

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Re-builds when teamsProvider changes
  final teamsAsync = ref.watch(teamsProvider);
  
  return teamsAsync.when(/* ... */);
}
```

### 2. Reading Providers in Callbacks

```dart
Future<void> _createTeam(String name) async {
  // One-time read, doesn't listen for changes
  await ref.read(teamsProvider.notifier).createTeam(name: name);
}
```

### 3. Invalidating Cache

```dart
// Manual refresh
ref.refresh(teamsProvider);

// After mutation
await ref.read(teamsProvider.notifier).createTeam(name: 'New Team');
// Cache automatically refreshed inside createTeam()

// On logout
ref.invalidate(teamsProvider);
ref.invalidate(currentUserProvider);
```

### 4. Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () => ref.refresh(teamsProvider.future),
  child: ListView(/* ... */),
)
```

### 5. Handling AsyncValue States

```dart
teamsAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => ErrorView(
    error: error.toString(),
    onRetry: () => ref.refresh(teamsProvider),
  ),
  data: (teams) => TeamList(teams: teams),
)
```

### 6. Conditional Loading (Stale-While-Revalidate)

```dart
// Show cached data while loading fresh data in background
final teamsAsync = ref.watch(teamsProvider);

return teamsAsync.map(
  loading: (_) {
    // Only show spinner if no cached data
    return _.hasValue
        ? TeamList(teams: _.value!)  // Show cached data
        : const CircularProgressIndicator(); // Show spinner
  },
  error: (error) => ErrorView(error: error),
  data: (data) => TeamList(teams: data.value),
);
```

---

## Cache Invalidation Rules

### When to Invalidate

| Operation | Invalidate |
|-----------|-----------|
| **Create Team** | ✅ Yes - Refresh teams list |
| **Update Team** | ✅ Yes - Refresh teams list |
| **Delete Team** | ✅ Yes - Refresh teams list |
| **View Team** | ❌ No - Use cached data |
| **Switch Tabs** | ❌ No - Use cached data |
| **Pull-to-Refresh** | ✅ Yes - User requested fresh data |
| **Logout** | ✅ Yes - Clear all caches |

### Implementation

```dart
// Inside provider notifier
Future<Team> createTeam({required String name, String? description}) async {
  final apiService = ref.read(apiServiceProvider);
  final newTeam = await apiService.createTeam(name: name, description: description);
  
  // Refresh the cache
  await refresh();
  
  return newTeam;
}
```

---

## Error Handling

### Display User-Friendly Errors

```dart
error: (error, stack) {
  String message = 'An error occurred';
  
  if (error is ApiException) {
    if (error.isUnauthorized) message = 'Please sign in again';
    else if (error.isNotFound) message = 'Team not found';
    else message = error.message;
  }
  
  return ErrorView(
    message: message,
    onRetry: () => ref.refresh(teamsProvider),
  );
}
```

---

## Testing with Riverpod

### Override Providers in Tests

```dart
testWidgets('Shows team list', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamsProvider.overrideWith(() => MockTeamsNotifier()),
      ],
      child: const MyApp(),
    ),
  );

  expect(find.text('Team 1'), findsOneWidget);
});
```

---

## Best Practices

### Do's ✅

1. **Use `ref.watch()` in build methods** - Listens for changes
2. **Use `ref.read()` in callbacks** - One-time access
3. **Handle all AsyncValue states** - loading, error, data
4. **Invalidate cache after mutations** - Keep data fresh
5. **Use RefreshIndicator** - Allow manual refresh
6. **Keep providers focused** - One provider per data type
7. **Use `const` constructors** - Better performance

### Don'ts ❌

1. **Don't use `ref.watch()` in callbacks** - Causes unnecessary rebuilds
2. **Don't use `ref.read()` in build** - Won't update on changes
3. **Don't forget error handling** - Always handle errors gracefully
4. **Don't fetch in initState** - Use providers instead
5. **Don't store fetched data in State** - Use providers
6. **Don't manually manage loading states** - AsyncValue handles it

---

## Adding New Cached Endpoints

### Step-by-Step Guide

1. **Add method to ApiService** (`lib/services/api_service.dart`)
```dart
Future<Game> getGame(String gameId) async {
  final response = await _authenticatedRequest(
    method: 'GET',
    path: '/games/$gameId',
  );
  return Game.fromJson(_handleResponse(response));
}
```

2. **Create provider** (`lib/providers/game_providers.dart`)
```dart
final gameProvider = FutureProvider.family<Game, String>((ref, gameId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getGame(gameId);
});
```

3. **Use in screen**
```dart
class GameScreen extends ConsumerWidget {
  final String gameId;
  const GameScreen({required this.gameId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameProvider(gameId));
    return gameAsync.when(/* ... */);
  }
}
```

---

## Performance Considerations

### Cache Memory Usage

- **Session-only caching** - Cleared on app restart
- **In-memory storage** - Fast access, no disk I/O
- **Automatic garbage collection** - Unused providers cleaned up

### Network Optimization

- **Automatic deduplication** - Multiple watches share one request
- **Background refresh** - Non-blocking UI updates
- **Request cancellation** - Stops in-flight requests when leaving screen

---

## Migration Checklist

When adding Riverpod to a new screen:

- [ ] Convert StatefulWidget → ConsumerStatefulWidget (or StatelessWidget → ConsumerWidget)
- [ ] Remove manual state variables (_isLoading, _data, _error)
- [ ] Remove initState() data fetching
- [ ] Replace setState() with provider reads/watches
- [ ] Handle AsyncValue states (loading, error, data)
- [ ] Add RefreshIndicator for pull-to-refresh
- [ ] Invalidate cache on mutations
- [ ] Test all loading/error/success states

---

## See Also

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Overall system architecture
- **[DATA_MODEL.md](./DATA_MODEL.md)** - Backend data model
- **[Riverpod Documentation](https://riverpod.dev)** - Official Riverpod docs
- **[Flutter Best Practices](https://dart.dev/guides/language/effective-dart)** - Dart/Flutter guidelines

