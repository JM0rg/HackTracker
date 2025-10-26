# Optimistic UI Pattern Guide

## Overview

HackTracker uses a **race-condition-safe optimistic UI pattern** for all data mutations. This provides instant feedback to users while maintaining data consistency even when multiple operations happen concurrently.

## The Problem: Race Conditions

**Naive approach (BROKEN):**
```dart
// ❌ BAD: Saves previous state snapshot
final previous = state.value;
state = optimisticUpdate();
try {
  await apiCall();
} catch (e) {
  state = previous; // Race condition! May overwrite other changes
}
```

**What goes wrong:**
1. User adds Player A → `previous = []`, `state = [A_temp]`
2. User adds Player B → `previous = [A_temp]`, `state = [A_temp, B_temp]`
3. Player A succeeds → `state = [A_real, B_temp]`
4. Player B fails → `state = previous = [A_temp]` ❌ Lost A_real!

## The Solution: Rollback Functions

**Safe approach (CORRECT):**
```dart
// ✅ GOOD: Rollback operates on current state
state = optimisticUpdate(state);
try {
  await apiCall();
  state = applyResult(state, result);
} catch (e) {
  state = rollback(state); // Safely undoes only this change
}
```

## Implementation

### 1. Extension Method

All optimistic mutations use the `mutate()` extension:

```dart
// app/lib/providers/optimistic_extensions.dart
extension OptimisticMutation<T> on AsyncNotifier<T> {
  Future<R?> mutate<R>({
    required T Function(T current) optimisticUpdate,
    required Future<R> Function() apiCall,
    required T Function(T current, R result) applyResult,
    required T Function(T current) rollback, // ← Key: operates on current
    String? successMessage,
    String Function(dynamic error)? errorMessage,
  }) async { /* ... */ }
}
```

### 2. Usage Pattern

**Add Player Example:**
```dart
Future<Player?> addPlayer({required String firstName, /* ... */}) async {
  final temp = Player(id: 'temp-${timestamp}', name: firstName, /* ... */);
  
  return notifier.mutate<Player>(
    // 1. Add temp player to current state
    optimisticUpdate: (current) => [...current, temp],
    
    // 2. Call API
    apiCall: () => api.createPlayer(name: firstName),
    
    // 3. On success: replace temp with real player in current state
    applyResult: (current, realPlayer) => [
      for (final p in current)
        if (p.id == temp.id) realPlayer else p
    ],
    
    // 4. On failure: remove temp from current state
    rollback: (current) => current.where((p) => p.id != temp.id).toList(),
    
    successMessage: 'Player added!',
    errorMessage: (e) => 'Failed to add player: $e',
  );
}
```

**Update Player Example:**
```dart
Future<Player?> updatePlayer(String id, {String? name}) async {
  final original = state.value!.firstWhere((p) => p.id == id);
  
  return notifier.mutate<Player>(
    // 1. Update player in current state
    optimisticUpdate: (current) => [
      for (final p in current)
        if (p.id == id) p.copyWith(name: name) else p
    ],
    
    // 2. Call API
    apiCall: () => api.updatePlayer(id, name: name),
    
    // 3. On success: replace with real updated player
    applyResult: (current, realPlayer) => [
      for (final p in current)
        if (p.id == id) realPlayer else p
    ],
    
    // 4. On failure: restore original player
    rollback: (current) => [
      for (final p in current)
        if (p.id == id) original else p
    ],
    
    successMessage: 'Player updated!',
  );
}
```

**Remove Player Example:**
```dart
Future<void> removePlayer(String id) async {
  final removed = state.value!.firstWhere((p) => p.id == id);
  
  await notifier.mutate<void>(
    // 1. Remove from current state
    optimisticUpdate: (current) => current.where((p) => p.id != id).toList(),
    
    // 2. Call API
    apiCall: () => api.deletePlayer(id),
    
    // 3. On success: already removed, just persist
    applyResult: (current, _) => current,
    
    // 4. On failure: re-insert the removed player
    rollback: (current) => [...current, removed],
    
    successMessage: 'Player removed!',
  );
}
```

## Key Principles

### 1. Always Capture Original for Rollback
```dart
// For updates/deletes, save the original
final original = state.value!.firstWhere((item) => item.id == id);

// For adds, save the temp item
final temp = Item(id: 'temp-${timestamp}', /* ... */);
```

### 2. Rollback Operates on Current State
```dart
// ✅ GOOD: Removes only the temp item from current state
rollback: (current) => current.where((p) => p.id != temp.id).toList()

// ❌ BAD: Reverts to previous snapshot (race condition)
rollback: (_) => previousSnapshot
```

### 3. Use Temp IDs for Adds
```dart
// Temp IDs must be unique and identifiable
final temp = Player(
  playerId: 'temp-${DateTime.now().microsecondsSinceEpoch}',
  // ...
);

// UI can detect syncing state
final isSyncing = player.playerId.startsWith('temp-');
```

### 4. Persist to Cache
```dart
applyResult: (current, result) {
  final updated = /* apply result */;
  Persistence.setJson('cache_key', updated); // ← Persist
  return updated;
}
```

## UI Integration

### Show Loading Indicator for Temp Items
```dart
class PlayerCard extends StatelessWidget {
  final Player player;
  
  @override
  Widget build(BuildContext context) {
    final isSyncing = player.playerId.startsWith('temp-');
    
    return ListTile(
      title: Text(player.name),
      trailing: isSyncing 
        ? CircularProgressIndicator() // ← Show spinner
        : PopupMenuButton(/* ... */),  // ← Show menu when synced
    );
  }
}
```

### Toast Notifications
Success and error toasts are handled automatically by the `mutate()` extension:
- Success: Green toast from top
- Error: Red toast from top + automatic rollback

## Testing Optimistic UI

### Test Concurrent Operations
```dart
test('concurrent adds do not cause race condition', () async {
  final notifier = RosterNotifier();
  
  // Start two adds simultaneously
  final future1 = notifier.addPlayer(firstName: 'Alice');
  final future2 = notifier.addPlayer(firstName: 'Bob');
  
  await Future.wait([future1, future2]);
  
  // Both should be in final state
  expect(notifier.state.value, hasLength(2));
  expect(notifier.state.value!.map((p) => p.firstName), contains('Alice'));
  expect(notifier.state.value!.map((p) => p.firstName), contains('Bob'));
});
```

### Test Rollback
```dart
test('failed add rolls back correctly', () async {
  final notifier = RosterNotifier();
  final api = MockApiService();
  
  // Make API fail
  when(() => api.createPlayer(any())).thenThrow(Exception('Network error'));
  
  await notifier.addPlayer(firstName: 'Alice');
  
  // Temp player should be removed
  expect(notifier.state.value, isEmpty);
});
```

## Cache Versioning

When cache format changes, increment the version to auto-clear old caches:

```dart
// app/lib/utils/persistence.dart
class Persistence {
  static const int cacheVersion = 2; // ← Increment to clear cache
  
  static Future<void> checkCacheVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('cache_version');
    
    if (stored != cacheVersion) {
      await prefs.clear(); // Clear old cache
      await prefs.setInt('cache_version', cacheVersion);
    }
  }
}
```

Call this in `main()` before running the app:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Persistence.checkCacheVersion(); // ← Check version
  runApp(/* ... */);
}
```

## Checklist for New Optimistic Mutations

- [ ] Create temp item with `temp-` prefix (for adds)
- [ ] Capture original item (for updates/deletes)
- [ ] Use `notifier.mutate()` with all 4 functions
- [ ] Rollback operates on `current`, not snapshot
- [ ] Persist to cache in `applyResult` and `rollback`
- [ ] Provide success/error messages
- [ ] Show loading indicator for temp items in UI
- [ ] Test concurrent operations
- [ ] Test rollback on API failure

## Benefits

✅ **Instant feedback** - UI updates immediately  
✅ **Race-condition safe** - Handles concurrent operations correctly  
✅ **Automatic rollback** - Errors handled gracefully  
✅ **Consistent UX** - Same pattern everywhere  
✅ **Easy to test** - Clear, predictable behavior  
✅ **Persistent cache** - Data survives app restarts  

## See Also

- `app/lib/providers/optimistic_extensions.dart` - Extension implementation
- `app/lib/providers/player_providers.dart` - Real-world examples
- `app/lib/utils/persistence.dart` - Cache management
- `ARCHITECTURE.md` - Overall system design

