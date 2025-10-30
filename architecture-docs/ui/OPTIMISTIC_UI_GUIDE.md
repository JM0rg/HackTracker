# Optimistic UI Implementation Guide

**Part of:** [ARCHITECTURE.md](../ARCHITECTURE.md) - Complete system architecture guide

HackTracker's race-condition-safe optimistic UI pattern for instant, responsive user experiences.

---

## Overview

**Problem:** Traditional API flows feel slow (loading spinners, waiting for responses)  
**Solution:** Update UI immediately, sync with backend in background  
**Challenge:** Handle race conditions, failures, and rollbacks safely

**Pattern:** Optimistic Update + Temporary IDs + Safe Rollback + Background Sync

---

## Why Optimistic UI?

### Traditional Flow (Slow ❌)

```
User clicks "Add Player"
  ↓
Show loading spinner
  ↓
Wait for API response (500ms - 2s)
  ↓
Update UI
  ↓
Hide loading spinner
```

**User Experience:** Sluggish, unresponsive, feels broken

### Optimistic Flow (Fast ✅)

```
User clicks "Add Player"
  ↓
Update UI immediately (0ms)
  ↓
Background: Send API request
  ↓
Background: Update with real data
```

**User Experience:** Instant, smooth, feels native

---

## Core Pattern

### 1. Temporary IDs

Generate unique temporary IDs for optimistic items:

```dart
final tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
```

**Why microseconds?**
- Guarantees uniqueness (even for rapid operations)
- Easy to identify as temporary (`temp-` prefix)
- Sortable by creation time

---

### 2. Optimistic Update

Add temporary item to state immediately:

```dart
Future<Team?> createTeam({required String name, String? description}) async {
  // Create temp team
  final temp = Team(
    teamId: 'temp-${DateTime.now().microsecondsSinceEpoch}',
    name: name,
    description: description ?? '',
    role: 'owner',
    memberCount: 1,
    joinedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );

  // Optimistic update (instant UI change)
  final current = state.value ?? <Team>[];
  state = AsyncValue.data([...current, temp]);

  // Background: API call
  try {
    final api = ref.read(apiServiceProvider);
    final newTeam = await api.createTeam(name: name, description: description);
    
    // Success: Replace temp with real data
    final updated = state.value!.map((t) => 
      t.teamId == temp.teamId ? newTeam : t
    ).toList();
    state = AsyncValue.data(updated);
    
    return newTeam;
  } catch (e) {
    // Failure: Remove temp item (rollback)
    final rolled = state.value!.where((t) => t.teamId != temp.teamId).toList();
    state = AsyncValue.data(rolled);
    
    rethrow; // Let UI handle error
  }
}
```

---

### 3. Race-Condition-Safe Rollback

**Problem:** Multiple operations can overlap

**Bad Approach:**
```dart
// ❌ RACE CONDITION! state might change between operations
final current = state.value;
await api.call();
state = AsyncValue.data(current); // Oops! Might overwrite other changes
```

**Good Approach:**
```dart
// ✅ SAFE: Filter from current state at rollback time
catch (e) {
  final current = state.value ?? <Team>[]; // Get latest state
  final rolled = current.where((t) => t.teamId != temp.teamId).toList();
  state = AsyncValue.data(rolled);
  rethrow;
}
```

---

## Implementation Examples

### Create Operation

```dart
Future<Player?> createPlayer({
  required String firstName,
  required String lastName,
  required int playerNumber,
}) async {
  // Temp player
  final temp = Player(
    playerId: 'temp-${DateTime.now().microsecondsSinceEpoch}',
    teamId: _teamId,
    firstName: firstName,
    lastName: lastName,
    playerNumber: playerNumber,
    status: 'active',
    isGhost: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Optimistic update
  final current = state.value ?? <Player>[];
  state = AsyncValue.data([...current, temp]);

  try {
    final api = ref.read(apiServiceProvider);
    final newPlayer = await api.addPlayer(
      teamId: _teamId,
      firstName: firstName,
      lastName: lastName,
      playerNumber: playerNumber,
    );

    // Replace temp with real player
    final updated = state.value!.map((p) => 
      p.playerId == temp.playerId ? newPlayer : p
    ).toList();
    state = AsyncValue.data(updated);
    
    return newPlayer;
  } catch (e) {
    // Rollback: Remove temp player
    final current = state.value ?? <Player>[]; // Fresh state!
    final rolled = current.where((p) => p.playerId != temp.playerId).toList();
    state = AsyncValue.data(rolled);
    rethrow;
  }
}
```

---

### Update Operation

```dart
Future<Player?> updatePlayer({
  required String playerId,
  String? firstName,
  int? playerNumber,
  List<String>? positions,
}) async {
  final current = state.value ?? <Player>[];
  final original = current.firstWhere(
    (p) => p.playerId == playerId,
    orElse: () => throw StateError('Player not found'),
  );

  // Optimistic update
  final optimistic = current.map((p) {
    if (p.playerId == playerId) {
      return Player(
        playerId: p.playerId,
        teamId: p.teamId,
        firstName: firstName ?? p.firstName,
        lastName: p.lastName,
        playerNumber: playerNumber ?? p.playerNumber,
        positions: positions ?? p.positions,
        status: p.status,
        isGhost: p.isGhost,
        userId: p.userId,
        linkedAt: p.linkedAt,
        createdAt: p.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    return p;
  }).toList();
  
  state = AsyncValue.data(optimistic);

  try {
    final api = ref.read(apiServiceProvider);
    final updated = await api.updatePlayer(
      teamId: _teamId,
      playerId: playerId,
      firstName: firstName,
      playerNumber: playerNumber,
      positions: positions,
    );

    // Replace optimistic with real data
    final final = state.value!.map((p) => 
      p.playerId == playerId ? updated : p
    ).toList();
    state = AsyncValue.data(final);
    
    return updated;
  } catch (e) {
    // Rollback: Restore original
    final current = state.value ?? <Player>[]; // Fresh state!
    final rolled = current.map((p) => 
      p.playerId == playerId ? original : p
    ).toList();
    state = AsyncValue.data(rolled);
    rethrow;
  }
}
```

**Key Difference:** Update stores original for rollback

---

### Delete Operation

```dart
Future<void> deleteGame(String gameId) async {
  final current = state.value ?? <Game>[];
  final original = current.firstWhere(
    (g) => g.gameId == gameId,
    orElse: () => throw StateError('Game not found'),
  );

  // Optimistic delete (remove from UI)
  final optimistic = current.where((g) => g.gameId != gameId).toList();
  state = AsyncValue.data(optimistic);

  try {
    final api = ref.read(apiServiceProvider);
    await api.deleteGame(gameId: gameId);
    
    // Success: Keep deleted state
    // No action needed, already removed from UI
  } catch (e) {
    // Rollback: Restore original
    final current = state.value ?? <Game>[]; // Fresh state!
    final rolled = [...current, original];
    state = AsyncValue.data(rolled);
    rethrow;
  }
}
```

---

## Error Handling

### Display Error to User

```dart
try {
  await ref.read(rosterProvider(_teamId).notifier).createPlayer(
    firstName: 'John',
    lastName: 'Doe',
    playerNumber: 12,
  );
  
  // Success
  showSuccess(context, 'Player added');
} catch (e) {
  // Error: Optimistic update already rolled back
  showError(context, 'Failed to add player: $e');
}
```

### Error Types

**Validation Errors (400):**
```dart
catch (e) {
  if (e.toString().contains('already exists')) {
    showError(context, 'Player number already in use');
  } else if (e.toString().contains('invalid')) {
    showError(context, 'Invalid player data');
  }
}
```

**Permission Errors (403):**
```dart
catch (e) {
  if (e.toString().contains('permission')) {
    showError(context, 'You don\'t have permission to do that');
  }
}
```

**Network Errors:**
```dart
catch (e) {
  if (e is SocketException || e is TimeoutException) {
    showError(context, 'Network error. Please try again.');
  }
}
```

---

## Stale-While-Revalidate (SWR)

Cache data persistently, show stale data instantly while fetching fresh data in background.

### Implementation

```dart
class TeamsNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() async {
    final api = ref.read(apiServiceProvider);
    
    // Try to get cached data
    final cached = await _getCached();
    
    // If we have cached data, return it immediately
    if (cached != null) {
      state = AsyncValue.data(cached);
      
      // Background: Fetch fresh data
      _fetchFresh().then((fresh) {
        state = AsyncValue.data(fresh);
        _saveCache(fresh);
      });
      
      return cached;
    }
    
    // No cache: Fetch fresh
    final fresh = await api.listTeams();
    _saveCache(fresh);
    return fresh;
  }
  
  Future<List<Team>?> _getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('teams_cache');
    if (json == null) return null;
    
    final list = jsonDecode(json) as List;
    return list.map((e) => Team.fromJson(e)).toList();
  }
  
  Future<void> _saveCache(List<Team> teams) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(teams.map((t) => t.toJson()).toList());
    await prefs.setString('teams_cache', json);
  }
  
  Future<List<Team>> _fetchFresh() async {
    final api = ref.read(apiServiceProvider);
    return await api.listTeams();
  }
}
```

**Benefits:**
- ✅ Instant UI load (0ms from cache)
- ✅ Always fresh (background sync)
- ✅ Works offline (shows stale data)
- ✅ Seamless experience

---

## Best Practices

### 1. Always Use Temp IDs

```dart
// ✅ GOOD
final tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';

// ❌ BAD: Could collide
final tempId = 'temp-${Random().nextInt(1000)}';
```

---

### 2. Always Rollback from Fresh State

```dart
// ✅ GOOD: Get latest state at rollback time
catch (e) {
  final current = state.value ?? [];
  final rolled = current.where((item) => item.id != tempId).toList();
  state = AsyncValue.data(rolled);
}

// ❌ BAD: Using stale state from beginning
catch (e) {
  state = AsyncValue.data(originalState); // Race condition!
}
```

---

### 3. Store Original for Updates

```dart
// ✅ GOOD: Store original for safe rollback
final original = current.firstWhere((item) => item.id == id);
// ... optimistic update ...
catch (e) {
  // Restore original
  final rolled = current.map((item) => 
    item.id == id ? original : item
  ).toList();
}

// ❌ BAD: No way to restore if API fails
// ... optimistic update ...
catch (e) {
  // What do we restore to?
}
```

---

### 4. Rethrow Errors

```dart
// ✅ GOOD: Let UI handle error display
catch (e) {
  rollback();
  rethrow; // UI shows error
}

// ❌ BAD: Silent failure
catch (e) {
  rollback();
  // User has no idea it failed!
}
```

---

### 5. Keep UI Consistent

```dart
// ✅ GOOD: Sort after operations
final updated = [...current, newItem]..sort((a, b) => a.name.compareTo(b.name));
state = AsyncValue.data(updated);

// ❌ BAD: New item appears at random position
state = AsyncValue.data([...current, newItem]);
```

---

## Flutter Widget Integration

### Using Optimistic Providers

```dart
class TeamViewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(teamId));
    
    return rosterAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, st) => ErrorView(error: e),
      data: (players) {
        return ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            
            // Temp players appear grayed out (optional)
            final isTempPlayer = player.playerId.startsWith('temp-');
            
            return PlayerCard(
              player: player,
              opacity: isTempPlayer ? 0.6 : 1.0, // Visual feedback
            );
          },
        );
      },
    );
  }
}
```

---

### Triggering Optimistic Operations

```dart
ElevatedButton(
  onPressed: () async {
    try {
      await ref.read(rosterProvider(teamId).notifier).createPlayer(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        playerNumber: int.parse(_numberController.text),
      );
      
      Navigator.pop(context); // Close dialog
      showSuccess(context, 'Player added');
    } catch (e) {
      // Optimistic update already rolled back
      showError(context, 'Failed to add player: $e');
    }
  },
  child: const Text('Add Player'),
)
```

---

## Testing Optimistic Updates

### Test Optimistic Path

```dart
test('creates player optimistically', () async {
  final container = ProviderContainer();
  final notifier = container.read(rosterProvider(teamId).notifier);
  
  // Act: Trigger create (don't await)
  final future = notifier.createPlayer(
    firstName: 'John',
    lastName: 'Doe',
    playerNumber: 12,
  );
  
  // Assert: Optimistic player added immediately
  final state = container.read(rosterProvider(teamId));
  expect(state.value?.length, 1);
  expect(state.value?[0].firstName, 'John');
  expect(state.value?[0].playerId.startsWith('temp-'), true);
  
  // Await completion
  await future;
  
  // Assert: Real player replaced temp
  final finalState = container.read(rosterProvider(teamId));
  expect(finalState.value?[0].playerId.startsWith('temp-'), false);
});
```

### Test Rollback

```dart
test('rolls back on error', () async {
  final container = ProviderContainer();
  final notifier = container.read(rosterProvider(teamId).notifier);
  
  // Mock API to fail
  when(mockApi.createPlayer(...)).thenThrow(Exception('API error'));
  
  // Act & Assert
  expect(
    () => notifier.createPlayer(...),
    throwsException,
  );
  
  // Assert: Player was rolled back
  final state = container.read(rosterProvider(teamId));
  expect(state.value?.length, 0);
});
```

---

## Performance Considerations

### Memory

**Concern:** Storing original state for rollback

**Solution:** Only store what changes, not entire state
```dart
final original = current.firstWhere((item) => item.id == id); // Single item
```

### Network

**Concern:** Multiple rapid operations

**Solution:** Debounce updates or use queue
```dart
Timer? _debounceTimer;

void debouncedUpdate() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    // Perform update
  });
}
```

---

## See Also

- **[state-management.md](./state-management.md)** - Riverpod 3.0+ patterns
- **[../DATA_MODEL.md](../DATA_MODEL.md)** - Current implementation
- **[Riverpod Documentation](https://riverpod.dev/)** - State management library

---

**Philosophy:** Users should never wait for the network. The UI should feel instant, even on slow connections.

