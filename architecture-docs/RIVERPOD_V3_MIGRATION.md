# Riverpod v3 Migration Summary

## Overview
Successfully migrated the Flutter app from Riverpod v2.6.1 to v3.0.3. This migration involved several breaking changes that required refactoring the state management architecture.

## Changes Made

### 1. Dependency Update
**File**: `app/pubspec.yaml`
- Updated `flutter_riverpod` from `^2.6.1` to `^3.0.3`

### 2. Family Notifier Pattern Removed
**Breaking Change**: `FamilyAsyncNotifier` no longer exists in Riverpod v3.

**Migration Strategy**: Convert family notifiers to regular `AsyncNotifier` with constructor parameters.

#### Before (v2):
```dart
class RosterNotifier extends FamilyAsyncNotifier<List<Player>, String> {
  @override
  Future<List<Player>> build(String teamId) async {
    // ...
  }
}

final rosterProvider = AsyncNotifierProvider.family<RosterNotifier, List<Player>, String>(
  () => RosterNotifier(),
);
```

#### After (v3):
```dart
class RosterNotifier extends AsyncNotifier<List<Player>> {
  RosterNotifier(this._teamId);
  final String _teamId;

  @override
  Future<List<Player>> build() async {
    // Use _teamId from constructor
  }
}

final rosterProvider = AsyncNotifierProvider.family<RosterNotifier, List<Player>, String>(
  (teamId) => RosterNotifier(teamId),
);
```

**Note:** The family provider requires a lambda that accepts the family argument and returns a notifier instance. Do NOT use `RosterNotifier.new` directly as it won't work with parameterized constructors.

**Files Changed**:
- `app/lib/providers/player_providers.dart` - Converted `RosterNotifier`
- `app/lib/providers/team_providers.dart` - Converted `TeamByIdNotifier`

### 3. State Property Now Protected
**Breaking Change**: The `state` property is now protected and can only be accessed from within the notifier class.

**Impact**: Extension methods that access `state` from outside the notifier no longer work.

**Migration Strategy**: Move optimistic mutation logic from extension methods directly into the notifier class.

#### Before (v2):
```dart
// Extension method accessing state from outside
extension OptimisticMutation<T> on AsyncNotifier<T> {
  Future<R?> mutate<R>({...}) async {
    state = AsyncValue.data(...); // ❌ Not allowed in v3
  }
}
```

#### After (v3):
```dart
// Method inside the notifier class
class RosterNotifier extends AsyncNotifier<List<Player>> {
  Future<R?> mutate<R>({...}) async {
    state = AsyncValue.data(...); // ✅ Allowed within the class
  }
}
```

**Files Changed**:
- `app/lib/providers/player_providers.dart` - Added `mutate()` method to `RosterNotifier`
- `app/lib/providers/optimistic_extensions.dart` - **DELETED** (no longer needed)

### 4. StateProvider Legacy Import
**Breaking Change**: `StateProvider` is now considered "legacy" and moved to a separate import.

**Migration Strategy**: Import from `flutter_riverpod/legacy.dart` for existing `StateProvider` usage.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // For StateProvider
```

**Files Changed**:
- `app/lib/providers/team_providers.dart` - Added legacy import for `selectedTeamProvider`

**Note**: We kept `StateProvider` for now as it's simple and works. Future refactoring could convert it to a `Notifier` for consistency.

### 5. FutureProvider.family Converted to AsyncNotifierProvider.family
**Breaking Change**: While `FutureProvider.family` still exists, the migration guide recommends using `AsyncNotifierProvider.family` for consistency.

**Files Changed**:
- `app/lib/providers/team_providers.dart` - Converted `teamByIdProvider` from `FutureProvider.family` to `AsyncNotifierProvider.family<TeamByIdNotifier, Team, String>`

### 6. Exposed State for Actions Classes
**Pattern**: Since `RosterActions` needs to read the current state but can't access the protected `state` property, we added a public getter.

```dart
class RosterNotifier extends AsyncNotifier<List<Player>> {
  /// Expose the current state for RosterActions
  AsyncValue<List<Player>> get currentState => state;
}
```

**Files Changed**:
- `app/lib/providers/player_providers.dart` - Added `currentState` getter

## Testing

### Compilation Test
```bash
cd app && flutter analyze
# Result: 0 errors related to Riverpod v3 (only pre-existing info warnings)

cd app && flutter build web --release --no-pub
# Result: ✅ Built successfully
```

### Remaining Issues
The following issues are **unrelated to the Riverpod migration** and existed before:
- Info-level deprecation warnings (`withOpacity`, `value` in forms)
- Unused imports and elements
- Test file errors (unrelated to Riverpod)

## Key Takeaways

### What Worked Well
1. **Constructor parameters for family notifiers**: Cleaner API than the old `build(arg)` pattern
2. **Protected state**: Forces better encapsulation and prevents accidental external mutations
3. **Backward compatibility**: Legacy imports allow gradual migration

### What Required Extra Work
1. **Optimistic mutations**: Had to move from extension methods to class methods
2. **Actions pattern**: Required a public getter to expose state to helper classes

## Future Improvements

### Optional: Convert StateProvider to Notifier
Currently using `StateProvider` with legacy import. Could be converted to a `Notifier` for consistency:

```dart
// Current (v3 legacy)
final selectedTeamProvider = StateProvider<Team?>((ref) => null);

// Future (v3 native)
class SelectedTeamNotifier extends Notifier<Team?> {
  @override
  Team? build() => null;
  
  void select(Team? team) => state = team;
}
final selectedTeamProvider = NotifierProvider<SelectedTeamNotifier, Team?>(
  SelectedTeamNotifier.new,
);
```

## References
- [Riverpod 3.0 Migration Guide](https://riverpod.dev/docs/3.0_migration)
- [What's New in Riverpod 3.0](https://riverpod.dev/docs/whats_new)
- [Riverpod Best Practices](https://riverpod.dev/docs/root/do_dont)

## Migration Checklist
- [x] Update `pubspec.yaml` to `flutter_riverpod: ^3.0.3`
- [x] Convert `FamilyAsyncNotifier` to `AsyncNotifier` with constructor
- [x] Move optimistic mutation logic from extensions to notifier methods
- [x] Add legacy import for `StateProvider`
- [x] Convert `FutureProvider.family` to `AsyncNotifierProvider.family`
- [x] Add public getters for state access from helper classes
- [x] Delete obsolete `optimistic_extensions.dart`
- [x] Run `flutter analyze` and fix Riverpod-related errors
- [x] Test compilation with `flutter build web`
- [ ] Optional: Convert `StateProvider` to `Notifier` (future enhancement)

